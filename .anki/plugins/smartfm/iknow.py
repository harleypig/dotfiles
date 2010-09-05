from xml.dom import pulldom, Node
import os, urllib, urllib2, re, operator, traceback, time

#CACHE_API_RESULTS_PATH = None #remove comment from beginning of this line, and add comment to next line, in order to cache results
#TODO
MAX_HTTP_RETRIES = 3
CACHE_API_RESULTS_PATH = None #os.path.join("/tmp", "smartfm_api_cache") #Set to 'None' (no quotes) to disable caching. do *not* enable unless you are debugging this script

#API CACHING - useful for script debugging or if you know your lists won't be changing (if there is ANY chance your list might change, disable this)
if CACHE_API_RESULTS_PATH:
    if not os.path.exists(CACHE_API_RESULTS_PATH):
        try:
            os.mkdir(CACHE_API_RESULTS_PATH)
        except:
            CACHE_API_RESULTS_PATH = None
if CACHE_API_RESULTS_PATH:    
    import sha
    def getUrlOrCache(url, logger):
        if url[-1] == "?":
            url = url[0:-1]
        hasher = sha.new(url)
        hashedFilename = os.path.join(CACHE_API_RESULTS_PATH, hasher.hexdigest())
        #DEBUG: print "caching %s at %s" % (url, hashedFilename)
        if not os.path.exists(hashedFilename):
            urllib.urlretrieve(url, hashedFilename)
        return open(hashedFilename)
else:
    def getUrlOrCache(url, logger):
        if url[-1] == "?":
            url = url[0:-1]
        tries = 0
        while True:
            try:
                return urllib2.urlopen(url)
            except:
                tries += 1
                logger("try %s to fetch %s"  % (tries, url))
                if tries >= MAX_HTTP_RETRIES:
                    raise


class SmartFMDownloadError(Exception):
    pass

class SmartFMNoListDataFound(Exception):
    pass

def q(node, tag):
    return node.getElementsByTagName(tag)

def qallwa(node, tag, attribute, value):
    nodes = q(node, tag)
    matchingNodes = list()
    if nodes.length > 0:
        for node in nodes:
            if node.hasAttribute(attribute) and node.getAttribute(attribute).lower() == value.lower():
                matchingNodes.append(node)
    return matchingNodes


def q1(node, tag):
    nodes = q(node,tag)
    if nodes and len(nodes) > 0:
        return nodes[0]
    else:
        return None

def qwa(node, tag, attribute, value):
    nodes = q(node, tag)
    for n in nodes:
        if n and n.hasAttribute(attribute):
            attrValue = n.getAttribute(attribute)
            if attrValue and attrValue == value:
                return n
    return None

def c1(node, tag):
    if node and node.childNodes:
        for c in node.childNodes:
            if c.tagName == tag:
                return c

def c1wa(node, tag, attribute, value):
    if node and node.childNodes:
        for c in node.childNodes:
            if c.tagName == tag and c.hasAttribute(attribute):
                if c.getAttribute(attribute) == value:
                    return c

def c1d(node, tag):
    n = c1(node, tag)
    if not n:
        return u""
    text = u""
    for c in n.childNodes:
        text += c.data
    return text

def qnodetext(node):
    text = u""
    for c in node.childNodes:
        text += c.data
    return text

def q1d(node, tag):
    n = q1(node, tag)
    if not n:
        return u""
    text = u""
    for c in n.childNodes:
        text += c.data
    return text
    
class SmartFMList(object):
    def __init__(self):
        self.iknow_id = None
        self.list_uri = None
        self.name = None
        self.language = None
        self.translation_language = None
        self.type = u"list"
        self.index = None
    
    def isBilingual(self):
        if self.language and self.translation_language and self.language != self.translation_language:
            return True
        else:
            return False
    
    def uniqIdStr(self):
        return self.type + u":" + self.iknow_id
    
    def loadFromDOM(self, node):
        self.iknow_id = node.getAttribute(u'id')
        self.language = q1d(node, u'language')
        self.translation_language = q1d(node, u'translation_language')
        self.list_uri = node.getAttribute(u'href')
        self.name = q1d(node, u'title')
    
    def __repr__(self):
        return "id: %s\n\tlist uri: %s\n\tname: %s\n\tlang: %s\n\ttrans lang: %s\n\t" % (self.iknow_id, self.list_uri, self.name, self.language, self.translation_language)
    

class SmartFMItem(object):
    def __init__(self):
        self.iknow_id = None
        self.language = None
        self.index = None
        self.meaning = None
        self.secondary_meanings = list()
        self.expression = None
        self.reading = None
        self.audio_uri = None
        self.image_uri = None
        self.item_uri = None
        
    def uniqIdStr(self):
        return self.type + u":" + self.iknow_id
    
    def __repr__(self):
        return "id: %s\n\tlang: %s\n\tmeaning: %s\n\texpr: %s\n\tread: %s\n\taudio: %s\n\t img: %s\n\ttype: %s\n" % (self.iknow_id, self.language, self.meaning, self.expression, self.reading, self.audio_uri, self.image_uri, self.type)

class SmartFMVocab(SmartFMItem):
    def __init__(self):
        SmartFMItem.__init__(self)
        self.type = u"item"
    
    def loadFromDOM(self, node):
        self.iknow_id = node.getAttribute(u'id')
        self.language = node.getAttribute(u'language')
        self.item_uri = node.getAttribute(u'href')
        charNode = None
        if q1(node, u'character'):
            self.expression = q1d(node, u'character')
            if q1(node, u'text'):
                self.reading = q1d(node, u'text')
        else:
            cueNodeText = qwa(node, u'cue', u'type', u'text')
            if cueNodeText:
                self.expression = q1d(cueNodeText, u'text')
            else:
                cueNodeImg = qwa(node, u'cue', u'type', u'image')
                if cueNodeImg:
                    imgdata = q1d(cueNodeImg, u'image')
                    self.expression = u'<img src="%s">' % imgdata
        hansNode = qwa(node, u'transliteration', u'type', u'Hans')
        if hansNode:
            if not self.expression:
                self.expression = u"hans: " + qnodetext(hansNode)
            elif qnodetext(hansNode) != self.expression:
                self.expression = u"trad: " + self.expression + u"<br />hans: " + qnodetext(hansNode)
        if not self.reading:
            readingNode = c1wa(node, u'transliteration', u'type', u'Hrkt')
            readingNodeAlt = c1wa(node, u'transliteration', u'type', u'Hira')
            if readingNode:
                self.reading = qnodetext(readingNode)
            elif readingNodeAlt:
                self.reading = qnodetext(readingNodeAlt)
            else:
                readingNode = c1wa(node, u'transliteration', u'type', u'Latn')
                if readingNode:
                    self.reading = qnodetext(readingNode)
        meaningNode = qwa(node, u'response', u'type', u'meaning')
        if meaningNode:
            self.meaning = q1d(meaningNode, u'text')
        cueNode = c1(node, u'cue')
        if cueNode and c1(cueNode, u'sound'):
            self.audio_uri = c1d(cueNode, u'sound')
        #not technically sure, but seems that image doesn't have to be part of queue, since the image would be generic regardless of an item's meaning. sound is a problem because we don't want audio from the wrong language
        if q1(node, u'image'):
            self.image_uri = q1d(node, u'image')
        
    def sentencesFromDOM(self, node, translationLanguage):
        sentencesNode = q1(node, u'sentences')
        sentenceslist = list()
        if not sentencesNode:
            return sentenceslist
        for sentenceNode in sentencesNode.childNodes:
            if sentenceNode.nodeType == Node.ELEMENT_NODE and sentenceNode.tagName.lower() == "sentence":
                nextsentence = SmartFMSentence()
                nextsentence.loadFromDOM(sentenceNode, translationLanguage)
                nextsentence.linkToVocab(self)
                sentenceslist.append(nextsentence)
        return sentenceslist
        
class SmartFMSentence(SmartFMItem):
    def __init__(self):
        SmartFMItem.__init__(self)
        self.type = u"sentence"
        self.core_words = list()
    
    def linkToVocab(self, vocab):
        self.secondary_meanings.append(vocab)
        self.core_words.append(vocab.expression)
    
    def loadFromDOM(self, node, translationLanguage):
        self.iknow_id = node.getAttribute(u'id')
        self.language = node.getAttribute(u'language')
        self.item_uri = node.getAttribute(u'href')
        self.expression = q1d(node, u'text')
        hansNode = qwa(node, u'transliteration', u'type', u'Hans')
        if hansNode:
            if not self.expression:
                self.expression = u"hans: " + qnodetext(hansNode)
            elif qnodetext(hansNode) != self.expression:
                self.expression = u"trad: " + self.expression + u"<br />hans: " + qnodetext(hansNode)
        readingNode = qwa(node, u'transliteration', u'type', u'Hrkt')
        readingNodeAlt = qwa(node, u'transliteration', u'type', u'Hira')
        if readingNode:
            self.reading = qnodetext(readingNode)
        elif readingNodeAlt:
            self.reading = qnodetext(readingNodeAlt)
        else:
            readingNode = qwa(node, u'transliteration', u'type', u'Latn')
            if readingNode:
                self.reading = qnodetext(readingNode)
        meaningSentenceNode = qwa(node, u'sentence', u'language', translationLanguage)
        if meaningSentenceNode:
            self.meaning = q1d(meaningSentenceNode, u'text')
        if c1(node, u'sound'):
            self.audio_uri = c1d(node, u'sound')
        if q1(node, u'image'):
            self.image_uri = q1d(node, u'image')

class SmartFMItemSorter:
    def __init__(self):
        pass

    def __call__(self, x, y):
        if x.index == y.index:
            if x.type == "item" and y.type == "sentence":
                return -1
            elif x.type == "sentence" and y.type == "item":
                return 1
            else:
                return 0
        else:
            return cmp(x.index, y.index)

class SmartFMAPIResultSet(object):
    def __init__(self, startIndex=0):
        self.lists = {}
        self.items = {}
        self.current_index = startIndex
        
    def updateIndexToMatch(self, itemToUpdateKey, itemWithTargetIndexKey):
        if itemWithTargetIndexKey in self.items and itemToUpdateKey in self.items:
            self.items[itemToUpdateKey].index = self.items[itemWithTargetIndexKey].index
    
    def addList(self, newlist):
        if newlist.uniqIdStr() in self.lists:
            return False
        self.current_index += 1
        newlist.index = self.current_index
        self.lists[newlist.uniqIdStr()] = newlist
        return True
        
    def addItem(self, newitem):
        if newitem.uniqIdStr() in self.items:
            return False
        self.current_index += 1
        newitem.index = self.current_index
        self.items[newitem.uniqIdStr()] = newitem
        return True
    
    def sortItems(self, yesVocab, yesSentences):
        for key in self.items.keys():
            if self.items[key].type == "item" and not yesVocab:
                del self.items[key]
            elif self.items[key].type == "sentence" and not yesSentences:
                del self.items[key]
        values = self.items.values()
        values.sort(SmartFMItemSorter())
        return values

class SmartFMAPI(object):
    SmartFM_STD_URL = "http://smart.fm"
    SmartFM_API_URL = "http://api.smart.fm"
    
    def __init__(self, logFile=None):
        self.debug = True
        self.callback = None
        self.lastUrlFetched = u""
        self.log = None
        self.urlTimeTotal = None
        self.processTimeTotal = None
        if self.debug:
            if logFile:
                self.log = open(logFile, 'a')
                self.log.write("\n\n----------------------START----------------------\n")
            self.urlTimeTotal = 0
            self.processTimeTotal = 0
    
    def setCallback(self, callback):
        self.callback = callback
    
    def _logMsg(self, msg):
        if self.debug and self.log:
            self.log.write(str(msg) + "\n")
            self.log.flush()
    
    def _close(self):
        if self.debug and self.log:
            self._logMsg("total url time: %s\ntotal process time: %s\nratio: %s" % (self.urlTimeTotal, self.processTimeTotal, self.urlTimeTotal / self.processTimeTotal))
            self.log.flush()
            self.log.close()
    
    def _logUrlTimeAndProcessTime(self, urlTime, processTime):
        if self.debug:
            self.urlTimeTotal += urlTime
            self.processTimeTotal += processTime
        
    def _parsePage(self, xml, pageResults, translationLanguage, includeSentences):
        events = pulldom.parse(xml)
        changedItemCount = 0
        for (event, node) in events:
            if event == pulldom.START_ELEMENT:
                if node.tagName.lower() == 'list':
                    events.expandNode(node)
                    smartfmlist = SmartFMList()
                    smartfmlist.loadFromDOM(node)
                    #self._logMsg(smartfmlist)
                    if pageResults.addList(smartfmlist):
                        changedItemCount += 1
                elif node.tagName.lower() == 'item':
                    events.expandNode(node)
                    smartfmitem = SmartFMVocab()
                    smartfmitem.loadFromDOM(node)
                    #self._logMsg(smartfmitem)
                    if pageResults.addItem(smartfmitem):
                        changedItemCount += 1
                    if includeSentences:
                        for sentence in smartfmitem.sentencesFromDOM(node, translationLanguage):
                            #self._logMsg(sentence)
                            if pageResults.addItem(sentence):
                                changedItemCount += 1
                            elif sentence.uniqIdStr() in pageResults.items:
                                pageResults.items[sentence.uniqIdStr()].linkToVocab(smartfmitem)
                                pageResults.updateIndexToMatch(sentence.uniqIdStr(), smartfmitem.uniqIdStr())
                elif includeSentences and node.tagName.lower() == 'sentence':
                    events.expandNode(node)
                    smartfmsentence = SmartFMSentence()
                    smartfmsentence.loadFromDOM(node, translationLanguage)
                    if pageResults.addItem(smartfmsentence):
                        changedItemCount += 1
        return changedItemCount
    
    def _allPagesUntilEmpty(self, baseUrl, baseParams={}, translationLanguage=None, moreThanOnePage=True, includeSentences=False, startResultSet=None, gettingType=u"smart.fm data"):
        page = 0
        perPage = 25
        areMoreItems = True
        currentUrl = None
        currentParams = None
        newItemsOnPageCount = None
        totalResults = SmartFMAPIResultSet()
        if startResultSet:
            totalResults = startResultSet
        while areMoreItems:
            page += 1
            self._logMsg("page fetch loop, page %s with %s lists and %s items" % (page, len(totalResults.lists), len(totalResults.items)))
            currentParams = {}
            currentParams.update(baseParams)
            currentParams["per_page"] = perPage
            currentParams["page"] = page
            currentUrl = baseUrl + u"?"
            for i, key in enumerate(currentParams.keys()):
                if i != 0: currentUrl += u"&"
                currentUrl += "%s=%s" % (key, currentParams[key])
            if self.callback:
                self.callback(currentUrl, page, len(totalResults.items) + len(totalResults.lists), gettingType)
            self.lastUrlFetched = currentUrl
            urlpreTime = time.time()
            xml = getUrlOrCache(currentUrl, self._logMsg)
            urlpostTime = time.time()
            self._logMsg("timing: got url in %s" % (urlpostTime - urlpreTime))
            procpreTime = time.time()
            newItemsOnPageCount = self._parsePage(xml, totalResults, translationLanguage, includeSentences)
            procpostTime = time.time()
            self._logMsg("timing: parsed xml in %s" % (procpostTime - procpreTime))
            self._logUrlTimeAndProcessTime((urlpostTime - urlpreTime), (procpostTime - procpreTime))
            if newItemsOnPageCount > 0:
                self._logMsg("at least one new list/item retrieved: %s" % newItemsOnPageCount)
            else:
                self._logMsg("no new lists/items retrieved, breaking loop")
                areMoreItems = False
            if not moreThanOnePage:
                areMoreItems = False
        self._logMsg("all pages fetched, got %s lists and %s items" % (len(totalResults.lists), len(totalResults.items)))
        return totalResults
    
    def list(self, listId):
        url = None
        try:
            self._logMsg("list(%s)" % listId)
            url = SmartFMAPI.SmartFM_API_URL + "/lists/%s.xml" % listId
            results = self._allPagesUntilEmpty(url, moreThanOnePage=True, gettingType="list data")
            if len(results.lists.values()) > 0:
                return results.lists.values()[0]
            else:
                raise SmartFMNoListDataFound, "No data could be retrieved for smart.fm list %s" % listId
        except:
            raise SmartFMDownloadError(traceback.format_exc())
    
    def search(self, query, targetLanguage, includeItems=True, includeSentences=True, translationLanguage=None, requireSound=False, requireImage=False):
        finalResults = {}
        if includeItems:
            itemsURL = SmartFMAPI.SmartFM_API_URL + "/items/matching/%s.xml" % query
            params = {"language" : targetLanguage, "require_sound" : requireSound, "require_image" : requireImage}
            if translationLanguage:
                params["translation_language"] = translationLanguage
            itemResults = self._allPagesUntilEmpty(itemsURL, moreThanOnePage=True, gettingType="items", includeSentences=False, baseParams=params)
            finalResults['items'] = itemResults
        if includeSentences:
            sentencesURL = SmartFMAPI.SmartFM_API_URL + "/sentences/matching/%s.xml" % query
            params = {"language" : targetLanguage, "require_image" : requireImage, "require_sound" : requireSound}
            if translationLanguage:
                params["translation_language"] = translationLanguage
                params["require_translation"] = "true"
            sentenceResults = self._allPagesUntilEmpty(sentencesURL, moreThanOnePage=True, gettingType="sentences", includeSentences=True, baseParams=params)
            finalResults['sentences'] = sentenceResults
        return finalResults
        
    
    def sentence(self, iknowId, lang=u"en"):
        return self.genericItem("sentence", iknowId, lang)
    
    def item(self, iknowId):
        return self.genericItem("item", iknowId, u"en")
    
    def genericItem(self, itemtype, iknowId, lang):
        url = None
        try:
            includeSentences = False
            if itemtype == "sentence":
                includeSentences = True
            self._logMsg("%s(%s)" % (itemtype, iknowId))
            url = SmartFMAPI.SmartFM_API_URL + "/%ss/%s.xml" % (itemtype, iknowId)
            results = self._allPagesUntilEmpty(url, moreThanOnePage=False, gettingType="sentence", includeSentences=includeSentences, translationLanguage=lang)
            if len(results.items.values()) > 0:
                return results.items.values()[0]
            else:
                raise SmartFMNoListDataFound, "No data could be retrieved for smart.fm item/sentence %s" % iknowId
        except:
            raise SmartFMDownloadError(traceback.format_exc())
            
    
    def listItems(self, listId, includeVocab, includeSentences):
        smartfmlist = self.list(listId)
        if includeVocab and includeSentences:
            return self.listItemsAll(smartfmlist)
        elif includeVocab:
            return self.listVocab(smartfmlist)
        elif includeSentences:
            return self.listSentences(smartfmlist)
        else:
            raise SmartFMDownloadError, "listItems() called but no item type (vocab, sentence, both) specified"
        
    def listVocab(self, smartfmlist):
        try:
            self._logMsg("listVocab(%s)" % smartfmlist.iknow_id)
            itemsUrlBase = SmartFMAPI.SmartFM_API_URL + "/lists/%s/items.xml" % smartfmlist.iknow_id
            itemsParamsBase = {"include_sentences" : "false"}
            results = self._allPagesUntilEmpty(itemsUrlBase, baseParams=itemsParamsBase, includeSentences=False, gettingType="items/vocab")
            return results.sortItems(True, False)
        except:
            raise SmartFMDownloadError(traceback.format_exc())
    
    def listSentences(self, smartfmlist):
        try:
            if smartfmlist.language == smartfmlist.translation_language:
                return self.listItemsAllGeneric(smartfmlist).sortItems(False, True)
            else:
                return self.listSentencesBilingual(smartfmlist)
        except:
            raise SmartFMDownloadError(traceback.format_exc())
    
    def listSentencesBilingual(self, smartfmlist):
        self._logMsg("listSentences(%s)" % smartfmlist.iknow_id)
        baseUrl = SmartFMAPI.SmartFM_API_URL + "/lists/%s/sentences.xml" % smartfmlist.iknow_id
        results = self._allPagesUntilEmpty(baseUrl, translationLanguage=smartfmlist.translation_language, moreThanOnePage=True, includeSentences=True, gettingType="sentences")
        return results.sortItems(False, True)
            
    def listItemsAll(self, smartfmlist):
        try:
            return self.listItemsAllGeneric(smartfmlist).sortItems(True, True)
        except:
            raise SmartFMDownloadError(traceback.format_exc())
    
    def listItemsAllGeneric(self, smartfmlist):
        self._logMsg("listItemsAll(%s)" % smartfmlist.iknow_id)
        itemsUrlBase = SmartFMAPI.SmartFM_API_URL + "/lists/%s/items.xml" % smartfmlist.iknow_id
        itemsBaseParams = {"include_sentences" : "true"} #we want the data for the sentences so that we can tie vocab words to the sentences
        allResults = self._allPagesUntilEmpty(itemsUrlBase, baseParams=itemsBaseParams, includeSentences=True, translationLanguage=smartfmlist.translation_language, gettingType="items/vocab and sentences")
        
        #NOTE: DEPRECATED: as of mid June 2009, seems that smart.fm has fixed their list/items API. If the include_sentences param is passed as true, only sentences in the list itself is returned. skipping the below step seems to save a massive amount of time
        #NOTE: UNdeprecated: smart.fm reverted to previous behavior and now includes sentences not in the list, so we have to filter them out
        sentUrl = SmartFMAPI.SmartFM_API_URL + "/lists/%s/sentences.xml" % smartfmlist.iknow_id
        sentenceResults = self._allPagesUntilEmpty(sentUrl, translationLanguage=smartfmlist.translation_language, moreThanOnePage=True, includeSentences=True, gettingType="list-specific sentences")
        #pretime = time.time()
        for key in allResults.items.keys():
            if allResults.items[key].type == "sentence":
                if key not in sentenceResults.items:
                    del allResults.items[key]
                else:
                    #sentences only list will not be associated with any vocabulary, so ensure that any linked vocab is preserved
                    # this swap to use the sentences from the sentence only list instead of the sentences from the items&sentences list is due to a bug on smart.fm's part with incomplete data on the sentences in the items&sentences api calls
                    sentenceResults.items[key].secondary_meanings = allResults.items[key].secondary_meanings
                    allResults.items[key] = sentenceResults.items[key]
                    
        #posttime = time.time()
        #self._logMsg("timing: listItemsGeneric: remove sentences: %s" % (posttime - pretime))
        return allResults