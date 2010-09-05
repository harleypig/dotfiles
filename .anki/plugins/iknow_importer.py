from PyQt4.QtCore import SIGNAL, QUrl
from PyQt4.QtGui import QAction, QMessageBox, QDesktopServices
from PyQt4 import QtCore, QtGui
from ankiqt import mw
from ankiqt.ui.utils import getOnlyText
from anki.utils import canonifyTags
from anki.models import Model, FieldModel, CardModel
from anki.facts import Field
import os, re, time, urllib, traceback, os.path
from smartfm.iknow import *
from smartfm.ja_reading import getAdjustedReadingOfText

DOWNLOAD_IMAGES = False

class AudioDownloadError(Exception):
    pass

class AddMediaException(Exception):
    pass

class SmartFMModelCustomizeDialog(QtGui.QDialog):
    def __init__(self, cardSettings, showVocab, showSentence):
        QtGui.QDialog.__init__(self, mw)
        self.cardSettings = cardSettings
        self.showSentence = showSentence
        self.showVocab = showVocab
        self.setObjectName("smartfmCardCustomizeDialog")
        self.setWindowTitle("Smart.fm - Customize Card Types")
        self.setMinimumSize(450, 400)
        self.resize(450, 400)
        
        self.mainLayout = QtGui.QVBoxLayout(self)
        #self.mainLayout.setSpacing(6)
        #self.mainLayout.setMargin(9)
        self.mainLayout.setObjectName("mainLayout")
        
        self.labelTop = QtGui.QLabel("<b>Notes:</b><br />* Hover over a card type for more information about it.<br />* You can always edit cards later using the 'card templates' feature of Anki.<br /><br />")
        self.labelTop.setWordWrap(True)
        self.labelTop.setMaximumHeight(80)
        self.labelTop.setSizePolicy(QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Fixed)
        self.mainLayout.addWidget(self.labelTop)
        
        if self.showVocab:
            self.labelVocab = QtGui.QLabel("<b>Vocabulary Model - Card Types</b>")
            #self.labelVocab.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignBottom)
            self.labelVocab.setWordWrap(True)
            self.mainLayout.addWidget(self.labelVocab)
        
            self.checkProduction = QtGui.QCheckBox("Recall (production) card")
            self.checkProduction.setChecked(self.cardSettings.vocabProduction)
            self.checkProduction.setToolTip("Given a hint in your language, remember the correct word in your study language.")
            self.mainLayout.addWidget(self.checkProduction)
        
            self.checkListening = QtGui.QCheckBox("Listening card (enables audio download)")
            self.checkListening.setChecked(self.cardSettings.vocabListening)
            self.checkListening.setToolTip("Listen to the audio and remember its meaning.")
            self.mainLayout.addWidget(self.checkListening)
        
            self.checkReading = QtGui.QCheckBox("Reading card")
            self.checkReading.setChecked(self.cardSettings.vocabReading)
            self.checkReading.setToolTip("Read the text and remember its meaning.")
            self.mainLayout.addWidget(self.checkReading)
        
        if self.showSentence:
            self.labelSentences = QtGui.QLabel("<b>Sentences Model - Card Types</b>")
            #self.labelSentences.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignBottom)
            self.labelSentences.setWordWrap(True)
            self.mainLayout.addWidget(self.labelSentences)
        
            self.checkProductionSentences = QtGui.QCheckBox("Recall (production) card")
            self.checkProductionSentences.setChecked(self.cardSettings.sentenceProduction)
            self.checkProductionSentences.setToolTip("Given a hint in your language, remember the correct sentence in your study language.")
            self.mainLayout.addWidget(self.checkProductionSentences)
        
            self.checkListeningSentences = QtGui.QCheckBox("Listening card (enables audio download)")
            self.checkListeningSentences.setChecked(self.cardSettings.sentenceListening)
            self.checkListeningSentences.setToolTip("Listen to the audio and remember its meaning.")
            self.mainLayout.addWidget(self.checkListeningSentences)
        
            self.checkReadingSentences = QtGui.QCheckBox("Reading card")
            self.checkReadingSentences.setChecked(self.cardSettings.sentenceReading)
            self.checkReadingSentences.setToolTip("Read the text and remember its meaning.")
            self.mainLayout.addWidget(self.checkReadingSentences)
        
        self.mainLayout.addItem(QtGui.QSpacerItem(5, 30, QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Expanding))
        
        self.btnSubmit = QtGui.QPushButton(self)
        self.btnSubmit.setText("Start Import")
        self.mainLayout.addWidget(self.btnSubmit)
        
        self.btnCancel = QtGui.QPushButton(self)
        self.btnCancel.setText("Cancel")
        self.mainLayout.addWidget(self.btnCancel)
        
        self.connect(self.btnSubmit, QtCore.SIGNAL("clicked()"), self.submitClicked)
        self.connect(self.btnCancel, QtCore.SIGNAL("clicked()"), self.reject)
        
    def submitClicked(self):
        self.btnSubmit.setEnabled(False)
        if self.showVocab:
            self.cardSettings.vocabProduction = self.checkProduction.isChecked()
            self.cardSettings.vocabListening = self.checkListening.isChecked()
            self.cardSettings.vocabReading = self.checkReading.isChecked()
        if self.showSentence:
            self.cardSettings.sentenceProduction = self.checkProductionSentences.isChecked()
            self.cardSettings.sentenceListening = self.checkListeningSentences.isChecked()
            self.cardSettings.sentenceReading = self.checkReadingSentences.isChecked()
        self.accept()


class IknowImportDialog(QtGui.QDialog):
    def __init__(self, importSettings):
        QtGui.QDialog.__init__(self, mw)
        self.importSettings = importSettings
        self.setObjectName("Smart.fm Import")
        self.setWindowTitle("Smart.fm Import")
        self.setMinimumSize(450, 600)
        self.resize(450, 600)
    
        self.mainLayout = QtGui.QVBoxLayout(self)
        self.mainLayout.setSpacing(6)
        self.mainLayout.setMargin(9)
        self.mainLayout.setObjectName("mainLayout")
    
        self.settingsBox = QtGui.QGroupBox("Import Settings", self)
        self.settingsLayout = QtGui.QVBoxLayout(self.settingsBox)
        self.mainLayout.addWidget(self.settingsBox)
        
        self.labelSource = QtGui.QLabel("URL of the smart.fm list you wish to import. Example: http://smart.fm/goals/35430-chinese-media-lesson-1")
        self.labelSource.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignTop)
        self.labelSource.setWordWrap(True)
        self.settingsLayout.addWidget(self.labelSource)
        self.txt_source = QtGui.QLineEdit(self)
        self.txt_source.setMaxLength(500)
        self.settingsLayout.addWidget(self.txt_source)
    
        self.rbtn_group_typesToImport = QtGui.QGroupBox("Item types to import:", self)
        self.rbtnLayout = QtGui.QVBoxLayout(self.rbtn_group_typesToImport)
        self.rbtn_typesToImportVocab = QtGui.QRadioButton("&Vocabulary/Items", self.rbtn_group_typesToImport)
        self.rbtn_typesToImportVocab.setChecked(self.importSettings.importVocab and (not self.importSettings.importSentences))
        
        self.rbtnLayout.addWidget(self.rbtn_typesToImportVocab)
        self.rbtn_typesToImportSent = QtGui.QRadioButton("&Sentences", self.rbtn_group_typesToImport)
        self.rbtn_typesToImportSent.setChecked((not self.importSettings.importVocab) and  self.importSettings.importSentences)
        self.rbtnLayout.addWidget(self.rbtn_typesToImportSent)
        
        self.rbtn_typesToImportAll = QtGui.QRadioButton("&Both", self.rbtn_group_typesToImport)
        self.rbtnLayout.addWidget(self.rbtn_typesToImportAll)
        self.rbtn_typesToImportAll.setChecked(self.importSettings.importVocab and  self.importSettings.importSentences)
        self.settingsLayout.addWidget(self.rbtn_group_typesToImport)
        
        self.check_AudioDownload = QtGui.QCheckBox("Download audio clips if available", self)
        self.check_AudioDownload.setChecked(self.importSettings.downloadAudio)
        self.settingsLayout.addWidget(self.check_AudioDownload)
        
        self.check_includeItemMeaning = QtGui.QCheckBox("Include keyword meanings in sentence meanings")
        self.check_includeItemMeaning.setChecked(self.importSettings.includeItemMeaning)
        self.check_includeItemMeaning.setToolTip("Adds the keyword of the sentence<br /> and its meaning to the end of the sentence meaning.")
        self.settingsLayout.addWidget(self.check_includeItemMeaning)
        
        #self.check_boldKeywordMonolingual = QtGui.QCheckBox("Bold sentence keywords for monolingual lists")
        #self.check_boldKeywordMonolingual.setChecked(self.importSettings.boldMonolingualKeywords)
        #self.settingsLayout.addWidget(self.check_boldKeywordMonolingual)
        
        self.check_boldKeywordBilingual = QtGui.QCheckBox("Bold sentence keywords for bilingual lists")
        self.check_boldKeywordBilingual.setToolTip("Good for languages using the roman alphabet<br /> not suggested for languages using Chinese Characters or other scripts.")
        self.check_boldKeywordBilingual.setChecked(self.importSettings.boldBilingualKeywords)
        self.settingsLayout.addWidget(self.check_boldKeywordBilingual)
        
        self.check_reverseStudyDirection = QtGui.QCheckBox("Reverse study direction of list")
        self.check_reverseStudyDirection.setChecked(False)
        self.check_reverseStudyDirection.setToolTip("Makes a 'Japanese speaker learning English' list and turns it into a 'English speaker learning Japanese' list.")
        self.settingsLayout.addWidget(self.check_reverseStudyDirection)
        
        self.labelAmount = QtGui.QLabel("Maximum number of items to import (leave blank to download all items):")
        self.labelAmount.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignTop)
        self.labelAmount.setWordWrap(True)
        self.settingsLayout.addWidget(self.labelAmount)
        self.txt_amountToImport = QtGui.QLineEdit(self)
        self.txt_amountToImport.setMaxLength(5)
        self.settingsLayout.addWidget(self.txt_amountToImport)
        
        self.labelTags = QtGui.QLabel("Tags: ")
        self.labelTags.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignTop)
        self.labelTags.setWordWrap(True)
        self.settingsLayout.addWidget(self.labelTags)
        self.txt_tagsOnImport = QtGui.QLineEdit(self)
        self.txt_tagsOnImport.setMaxLength(50)
        if self.importSettings.tagsOnImport:
            self.txt_tagsOnImport.setText(self.importSettings.tagsOnImport)
        self.settingsLayout.addWidget(self.txt_tagsOnImport)
        
        self.labelReschedule = QtGui.QLabel("Schedule First Reviews for after # to # Days (please use the format #-# eg '7-14')")
        self.labelReschedule.setAlignment( QtCore.Qt.AlignLeading | QtCore.Qt.AlignLeft | QtCore.Qt.AlignTop)
        self.labelReschedule.setWordWrap(True)
        self.settingsLayout.addWidget(self.labelReschedule)
        self.txt_rescheduleAmount = QtGui.QLineEdit(self)
        self.txt_rescheduleAmount.setMaxLength(50)
        self.settingsLayout.addWidget(self.txt_rescheduleAmount)
        
        self.settingsLayout.addItem(QtGui.QSpacerItem(5, 30, QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Expanding))
        
        self.btnStartImport = QtGui.QPushButton(self)
        self.btnStartImport.setText(_("Start Import"))
        self.btnStartImport.setDefault(True)
        self.mainLayout.addWidget(self.btnStartImport)
        
        self.importStatusLabel = QtGui.QLabel("")
        self.settingsLayout.addWidget(self.importStatusLabel)
    
        self.cancelButton = QtGui.QPushButton(self)
        self.cancelButton.setText(_("Cancel"))
        self.mainLayout.addWidget(self.cancelButton)
        
        self.connect(self.btnStartImport, QtCore.SIGNAL("clicked()"), self.startImportClicked)
        self.connect(self.cancelButton, QtCore.SIGNAL("clicked()"), self.cancelClicked)
    
    def showErrors(self, errors):
        QMessageBox.warning(mw, "Warning", "There were various errors:<br />%s" % "<br />".join(errors))
        pass
    
    def clearErrors(self):
        pass 
    
    def startImportClicked(self):
        self.btnStartImport.setEnabled(False)
        self.clearErrors()
        errors = list()
        if self.rbtn_typesToImportAll.isChecked():
            self.importSettings.importSentences = True
            self.importSettings.importVocab = True
        elif self.rbtn_typesToImportSent.isChecked():
            self.importSettings.importSentences = True
            self.importSettings.importVocab = False
        elif self.rbtn_typesToImportVocab.isChecked():
            self.importSettings.importVocab = True
            self.importSettings.importSentences = False
        else:
            errors.append("Please choose a type of item to import")
        
        sourceText = self.txt_source.text()
        if sourceText:
            sourceText = unicode(sourceText)
            listId = re.search("goals/(\d+)", sourceText)
            if listId:
                self.importSettings.listId = listId.group(1)
            else:
                errors.append("URL of the smart.fm list is invalid, please see the example")
        else:
            errors.append("URL of the smart.fm list is required")
            
        maxItemsText = self.txt_amountToImport.text()
        if maxItemsText:
            maxItemsText = unicode(maxItemsText)
            if re.match("^\d+$", maxItemsText) and int(maxItemsText) >= 0:
                self.importSettings.maxItems = int(maxItemsText)
            else:
                errors.append("Maximum items to import must be all numeric, and greater than or equal to 0.")
        else:
            self.importSettings.maxItems = 0
        
        tagsOnImport = self.txt_tagsOnImport.text()
        if tagsOnImport:
            tagsOnImport = unicode(tagsOnImport).strip()
            if len(tagsOnImport) > 0:
                self.importSettings.tagsOnImport = tagsOnImport
            else:
                self.importSettings.tagsOnImport = None
        else:
            self.importSettings.tagsOnImport = None
        
        rescheduleText = self.txt_rescheduleAmount.text()
        if rescheduleText:
            rescheduleText = unicode(rescheduleText).strip()
            minMax = re.match("^(\d+)\s*-\s*(\d+)$", rescheduleText)
            if minMax:
                rescheduleMin = float(minMax.group(1))
                rescheduleMax = float(minMax.group(2))
                if rescheduleMin < rescheduleMax:
                    self.importSettings.rescheduleMin = rescheduleMin
                    self.importSettings.rescheduleMax = rescheduleMax
                else:
                    errors.append("The reschedule amount minimum days is greater or equal to the reschdule amount maximum days")
            else:
                errors.append("Please follow the format '#-#' (min days - max days) for the reschedule amount eg '3-4'")
        self.importSettings.downloadAudio = self.check_AudioDownload.isChecked()
        self.importSettings.includeItemMeaning = self.check_includeItemMeaning.isChecked()
        self.importSettings.boldBilingualKeywords = self.check_boldKeywordBilingual.isChecked()
        #self.importSettings.boldMonolingualKeywords = self.check_boldKeywordMonolingual.isChecked()
        self.importSettings.reverseStudyDirection = self.check_reverseStudyDirection.isChecked()
        
        if len(errors) > 0:
            for i, error in enumerate(errors):
                errors[i] = "* %s" % error
            self.showErrors(errors)
            self.btnStartImport.setEnabled(True)
        else:
            self.accept()
    
    def cancelClicked(self):
        self.reject()


class SmartFMCardTypeSettings:
    def __init__(self):
        self.vocabProduction = False
        self.vocabListening = False
        self.vocabReading = True
        self.sentenceProduction = False
        self.sentenceListening = False
        self.sentenceReading = True


class SmartFMImportSettings:
    def __init__(self):
        self.listId = None
        self.maxItems = 0
        self.importVocab = True
        self.importSentences = True
        self.downloadAudio = True
        self.includeItemMeaning = True
        self.boldBilingualKeywords = False
        self.boldMonolingualKeywords = True
        self.reverseStudyDirection = False
        self.tagsOnImport = None
        self.rescheduleMin = None
        self.rescheduleMax = None
        self.loadFromConfig()
    
    def loadFromConfig(self):
        if "iknow.importVocab" in mw.config:
            if mw.config["iknow.importVocab"] == "True":
                self.importVocab = True
            elif mw.config["iknow.importVocab"] == "False":
                self.importVocab = False
        if "iknow.importSentences" in mw.config:
            if mw.config["iknow.importSentences"] == "True":
                self.importSentences = True
            elif mw.config["iknow.importSentences"] == "False":
                self.importSentences = False
        if "iknow.downloadAudio" in mw.config:
            if mw.config["iknow.downloadAudio"] == "True":
                self.downloadAudio = True
            elif mw.config["iknow.downloadAudio"] == "False":
                self.downloadAudio = False
        if "iknow.includeItemMeaning" in mw.config:
            if mw.config["iknow.includeItemMeaning"] == "True":
                self.includeItemMeaning = True
            elif mw.config["iknow.includeItemMeaning"] == "False":
                self.includeItemMeaning = False
        if "iknow.boldBilingualKeywords" in mw.config:
            if mw.config["iknow.boldBilingualKeywords"] == "True":
                self.boldBilingualKeywords = True
            elif mw.config["iknow.boldBilingualKeywords"] == "False":
                self.boldBilingualKeywords = False
        if "iknow.tagsOnImport" in mw.config:
            self.tagsOnImport = unicode(mw.config["iknow.tagsOnImport"])
    
    def saveToConfig(self):
        if self.importVocab:
            mw.config["iknow.importVocab"] = "True"
        else:
            mw.config["iknow.importVocab"] = "False"
        if self.importSentences:
            mw.config["iknow.importSentences"] = "True"
        else:
            mw.config["iknow.importSentences"] = "False"
        if self.downloadAudio:
            mw.config["iknow.downloadAudio"] = "True"
        else:
            mw.config["iknow.downloadAudio"] = "False"
        if self.includeItemMeaning:
            mw.config["iknow.includeItemMeaning"] = "True"
        else:
            mw.config["iknow.includeItemMeaning"] = "False"
        if self.boldBilingualKeywords:
            mw.config["iknow.boldBilingualKeywords"] = "True"
        else:
            mw.config["iknow.boldBilingualKeywords"] = "False"
        if self.tagsOnImport:
            mw.config["iknow.tagsOnImport"] = self.tagsOnImport
        elif "iknow.tagsOnImport" in mw.config:
            del mw.config["iknow.tagsOnImport"]


class SmartFMModelManager:
    VOCAB_MODEL_NAME = u"iKnow! Vocabulary"
    SENTENCE_MODEL_NAME = u"iKnow! Sentences"
    
    def __init__(self, importSettings):
        self.importSettings = importSettings
        self.loadModels()
    
    def loadModels(self):
        self.vocabModel = self.findModel(SmartFMModelManager.VOCAB_MODEL_NAME)
        self.sentenceModel = self.findModel(SmartFMModelManager.SENTENCE_MODEL_NAME)
        
    def findModel(self, modelName):
        for m in mw.deck.models:
            if m.name.lower() == modelName.lower():
                return m
        return None
    
    def tagModelsAsJapanese(self):
        deckModified = False
        if self._tagModelAsJapanese(self.vocabModel):
            deckModified = True
        if self._tagModelAsJapanese(self.sentenceModel):
            deckModified = True
        if deckModified:
            mw.deck.setModified()
            mw.deck.save()
    
    def _tagModelAsJapanese(self, model):
        if model.tags.find(u"Japanese") < 0:
            model.tags = model.tags + u" Japanese"
            model.setModified()
            return True
        return False
    
    def isNeedsVocabModel(self):
        if self.importSettings.importVocab and not self.vocabModel:
            return True
        else:
            return False
    
    def isNeedsSentenceModel(self):
        if self.importSettings.importSentences and not self.sentenceModel:
            return True
        else:
            return False
    
    def createModelsFromSettings(self, cardSettings):
        if not self.vocabModel:
            self.createModel(SmartFMModelManager.VOCAB_MODEL_NAME, cardSettings.vocabProduction, cardSettings.vocabListening, cardSettings.vocabReading)
        if not self.sentenceModel:
            self.createModel(SmartFMModelManager.SENTENCE_MODEL_NAME, cardSettings.sentenceProduction, cardSettings.sentenceListening, cardSettings.sentenceReading)
        self.loadModels()
    
    def createModel(self, modelName, production, listening, reading):
        model = Model(modelName)
        model.addFieldModel(FieldModel(u'Expression', True, False))
        model.addFieldModel(FieldModel(u'Meaning', True, False))
        model.addFieldModel(FieldModel(u'Reading', False, False))
        model.addFieldModel(FieldModel(u'Audio', False, False))
        model.addFieldModel(FieldModel(u'Image_URI', False, False))
        model.addFieldModel(FieldModel(u'iKnowID', True, True))
        model.addFieldModel(FieldModel(u'iKnowType', False, False))
        if listening:
            model.addCardModel(CardModel(
                u'Listening',
                u'Listen.%(Audio)s',
                u'%(Expression)s<br>%(Reading)s<br>%(Meaning)s'))
        if production:
            model.addCardModel(CardModel(
                u'Production',
                u'%(Meaning)s<br>%(Image_URI)s',
                u'%(Expression)s<br>%(Reading)s<br>%(Audio)s'))
        if reading:
            model.addCardModel(CardModel(
                u'Reading',
                u'%(Expression)s',
                u'%(Reading)s<br>%(Meaning)s<br>%(Audio)s'))
        mw.deck.addModel(model)
        


class ProgressTracker:
    def __init__(self, log=None):
        self.dialog = QtGui.QProgressDialog(mw)
        self.dialog.setCancelButton(None)
        self.dialog.setMaximum(0)
        self.dialog.setMinimumDuration(0)
        self.dialog.setLabelText("Starting import..")
        self.currentPercent = 0
        if log:
            self.logFile = open(log, 'a')
            self.logFile.write("START [")
        else:
            self.logFile = None
            
    def close(self):
        if self.logFile:
            self.logFile.write("] END")
            self.logFile.flush()
            self.logFile.close()
            
    def logMsg(self, msg):
        if self.logFile:
            self.logFile.write(str(msg) + "\n")
            self.logFile.flush()
            
    def downloadCallback(self, url, pageNumber, itemCount, itemType):
        self.currentPercent += 1
        self.logMsg("url:%s\npage#:%s\nitems:%s\n\n" % (url, pageNumber, itemCount))
        self.dialog.setLabelText("Downloading data from smart.fm - got %s %s so far - please wait..." % (itemCount, itemType))
        self.dialog.setValue(self.currentPercent)
        mw.app.processEvents()
        
    def preImportResetProgress(self, count):
        self.currentPercent = 0
        self.dialog.setMaximum(count)
        self.dialog.setMinimumDuration(0)
        self.dialog.setValue(0)
        self.dialog.setLabelText("Starting to import %s items" % count)
        self.logMsg("starting to import %s items\n\n" % count)
        mw.app.processEvents()
        
    def importCallback(self, processedCount, currentItem):
        self.dialog.setValue(processedCount)
        self.dialog.setLabelText("Importing %s" % currentItem)
        mw.app.processEvents()



def formatIknowItemPreImportReverseStudyDirection(item, iknowList, importSettings):
    # first ensure there is both an expression and a meaning: the original meaning will become the new expression so it must also exist.
    if not item.meaning or len(item.meaning.strip()) == 0:
        return False
    newExpression = item.meaning
    item.meaning = item.expression
    item.expression = newExpression
    item.audio_uri = None #TODO: see if there's a fast way to check for audio on the translation
    if iknowList.translation_language:
        item.language = iknowList.translation_language
    return True

def formatIknowItemPreImport(item, iknowList, importSettings, isBilingualItem, progress):
    if importSettings.reverseStudyDirection:
        if not formatIknowItemPreImportReverseStudyDirection(item, iknowList, importSettings):
            progress.logMsg("formatIknowItemPreImport(): item %s could not be imported as a reversed study direction item: %s" % (item.uniqIdStr(), repr(item)))
            return False
            
    if not item.reading or len(item.reading.strip()) == 0:
        item.reading = u""
        
    try:
        if item.language.lower() == "ja":
            (adjustedReading, readingSource) = getAdjustedReadingOfText(item.expression, item.reading, progress.logMsg)
            progress.logMsg("getAdjustedReading('%s'): %s" % (item.expression.encode('utf-8'), readingSource.encode('utf-8')))
            if readingSource == "original-mecab-unavailable":
                pass #if mecab is unavailable, leave the reading alone
            elif readingSource == "mecab-ok":
                item.reading = adjustedReading
            else:
                if len(item.reading) > 0:
                    item.reading += u"<br />"
                item.reading += adjustedReading + u" -- !EditReading!"
    
    except:
        pass
    
    # for sentences in a monolingual list, use the item meaning 
    if not item.meaning and len(item.secondary_meanings) > 0:
        item.meaning = u""
        for secondary in item.secondary_meanings:
            item.meaning = item.meaning + u"<br />" + secondary.expression + u" -- " + secondary.meaning
    elif importSettings.includeItemMeaning and len(item.secondary_meanings) > 0:
        #note this only applies when the sentence already has its own meaning and we are possibly adding to it
        for secondary in item.secondary_meanings:
            item.meaning = item.meaning + u"<br />" + secondary.expression + u" -- " + secondary.meaning
    
    ###if it has its own meaning (bilingual list) and we do NOT want bolding on bilingual lists, then remove the default bolding from smart.fm
    ###TODO: in the case of bilingual lists with sentences conaining no meaning, this next check will fail.
    if isBilingualItem and not importSettings.boldBilingualKeywords:
        if item.meaning:
            item.meaning = item.meaning.replace('<b>','').replace('</b>','')
        item.reading = item.reading.replace('<b>','').replace('</b>','')
        item.expression = item.expression.replace('<b>','').replace('</b>','')
    ###if monolingual list, and we DO want bolding on monolingual lists, then bold the primary word if it isn't already bolded        
    #if not hasOwnMeaning and importSettings.boldMonolingualKeywords and item.type == "sentence" and len(item.core_words) > 0:
    #    for key in mainKeys:
    #        if item[key].find('<b>') >= 0:
    #            continue
    #        item[key] = item[key].replace(item['core_word'], u"<b>" + item['core_word'] + u"</b>")
    if not item.meaning or len(item.meaning.strip()) == 0:
        item.meaning = u"!EditMeaning! -- no meaning available on smart.fm!"
    return True


def importIknowItem(item, sentenceModel, vocabModel, importSettings, progress):
    idQuery = mw.deck.s.query(Field).filter_by(value=item.uniqIdStr())
    field = idQuery.first()
    if field:
        return False#is duplicate of an existing iknow ID, so return immediately
    
    try:
        expQuery = mw.deck.s.query(Field).filter_by(value=item.expression)
        field = expQuery.first()
        if field:
            return False #duplicate expression, the definition may be different but we don't want dup cards
    except:
        pass #might fail due to null expression which we catch other ways
    
    if item.type == "item":
        model = vocabModel
    elif item.type == "sentence":
        model = sentenceModel
    
    fact = mw.deck.newFact(model)
    if importSettings.tagsOnImport and len(importSettings.tagsOnImport.strip()) > 0:
        fact.tags = canonifyTags(importSettings.tagsOnImport)
    fact['iKnowID'] = item.uniqIdStr()
    fact['Expression'] = item.expression
    fact['Meaning'] = item.meaning
    fact['iKnowType'] = item.type
    fact['Reading'] = item.reading
    if item.image_uri:
        if DOWNLOAD_IMAGES: 
            #downloading images from smart.fm may be prohibited by smart.fm in certain cases. please only enable DOWNLOAD_IMAGES if you are sure that the list you are downloading has public domain (non-copyrighted or free for use) images.
            (filePath, headers) = urllib.urlretrieve(item.image_uri)
            path = mw.deck.addMedia(filePath)
            fact['Image_URI'] = u'<img src="%s" alt="[No Image]">' % item.image_uri
        else:
            fact['Image_URI'] = u'<img src="%s" alt="[No Image]">' % item.image_uri
    else:
        fact['Image_URI'] = u""
    if importSettings.downloadAudio and item.audio_uri:
        tries = 0
        gotAudioForItem = False
        gotItemWithNoData = False
        filePath = None
        headers = None
        path = None
        
        # make several attempts to download audio from smart.fm
        while not gotAudioForItem and tries < 3:
            tries += 1
            try:
                (filePath, headers) = urllib.urlretrieve(item.audio_uri)
                if os.path.exists(filePath) and os.path.getsize(filePath) > 0:
                    gotAudioForItem = True
                elif not os.path.exists(filePath):
                    progress.logMsg("WARN INFO: downloading URL %s with urlretrieve but the returned path %s does not exist." % (item.audio_uri.encode('utf-8'), filePath.encode('utf-8')))
                else:
                    progress.logMsg("WARN INFO: downloading URL %s with urlretrieve but the returned path %s has no data." % (item.audio_uri.encode('utf-8'), filePath.encode('utf-8')))
                    gotItemWithNoData = True
            except IOError:
                progress.logMsg("ERROR INFO: downloading URL %s but got IOError: %s" % (item.audio_uri.encode('utf-8'), traceback.format_exc().encode('utf-8')))
        if not gotAudioForItem and not gotItemWithNoData:
            #sometimes smart.fm reports that an item has an audio file, gives its URL, and even serves a response from that URL - except the URL has 0 bytes of data. so it downloads as a blank file. in this infrequent case, don't raise an error but just skip the audio.
            raise AudioDownloadError, "Failed to get audio for an item after 3 tries, cancelling import. Error with URI %s" % item.audio_uri
        if gotItemWithNoData:
            progress.logMsg("WARN INFO: skipping audio for %s, file had 0 bytes on smart.fm." % item.uniqIdStr())
        
        if gotAudioForItem:
            # now try to add the media file to the deck
            try:
                path = mw.deck.addMedia(filePath)
                progress.logMsg("Successfully added media from URI %s which was downloaded to %s to the media dir at %s" % (item.audio_uri.encode('utf-8'), filePath.encode('utf-8'), mw.deck.mediaDir().encode('utf-8')))
            except:
                raise AddMediaException, ("Failed to add media from URI %s \nwhich was downloaded to %s \nto the media dir at %s" % (item.audio_uri.encode('utf-8'), filePath.encode('utf-8'), mw.deck.mediaDir().encode('utf-8'))) + traceback.format_exc().encode('utf-8')
        
        fact['Audio'] = u"[sound:%s]" % path
    elif item.audio_uri:
        fact['Audio'] = u"[sound:%s]" % item.audio_uri
    else:
        fact['Audio'] = u""
    newfact = mw.deck.addFact(fact)
    cardIds = [card.id for card in newfact.cards]
    if importSettings.rescheduleMin and importSettings.rescheduleMax:
        mw.deck.rescheduleCards(cardIds, importSettings.rescheduleMin, importSettings.rescheduleMax)
    mw.deck.save()
    return True



def runImport(modelManager, importSettings):
    progress = ProgressTracker(os.path.join(mw.pluginsFolder(), "iknow-smartfm-log.txt"))
    try:
        importSettings.saveToConfig()
        iknow = SmartFMAPI()
        iknowList = iknow.list(importSettings.listId)
        try:
            if iknowList.language and iknowList.language == "ja":
                modelManager.tagModelsAsJapanese()
        except:
            progress.logMsg("Error trying to tag models as Japanese")
            progress.logMsg(traceback.format_exc())
            pass
        iknow.setCallback(progress.downloadCallback)
        items = iknow.listItems(importSettings.listId, (importSettings.importVocab or importSettings.includeItemMeaning), importSettings.importSentences)
        progress.preImportResetProgress(len(items))
        totalImported = 0
        totalDup = 0
        totalFormattingErrors = 0
        totalImportedByType = {"item" : 0, "sentence" : 0}
        for i, item in enumerate(items):
            if importSettings.maxItems > 0 and totalImported >= importSettings.maxItems:
                break
            if not importSettings.importSentences and item.type == "sentence":
                continue
            if not importSettings.importVocab and item.type == "item":
                continue
            if formatIknowItemPreImport(item, iknowList, importSettings, iknowList.isBilingual(), progress):
                progress.importCallback(i, item.expression)
                if importIknowItem(item, modelManager.sentenceModel, modelManager.vocabModel, importSettings, progress):
                    totalImported += 1
                    totalImportedByType[item.type] = totalImportedByType[item.type] + 1
                else:
                    totalDup += 1
            else:
                totalFormattingErrors += 1
        progress.dialog.cancel()
        progress.close()
        mw.deck.save()
        resultStr = "Import complete. Imported %s items, %s sentences, and skipped %s duplicates." % (totalImportedByType["item"], totalImportedByType["sentence"], totalDup)
        if totalFormattingErrors > 0:
            resultStr += " %s items were skipped because there was no translation available on smart.fm." % totalFormattingErrors
        QMessageBox.information(mw, "Summary", resultStr)
        mw.reset(mw.mainWin)
    except AudioDownloadError:
        progress.logMsg(traceback.format_exc())
        progress.dialog.cancel()
        progress.close()
        QMessageBox.warning(mw, "Warning", "Data for one item could not be retrieved even after several retries. This may be caused by a slower internet connection or smart.fm's (occasionally slow) servers. Please try your import again.")
        mw.reset(mw.mainWin)
    except AddMediaException:
        progress.logMsg(traceback.format_exc())
        progress.dialog.cancel()
        progress.close()
        QMessageBox.warning(mw, "Warning", "Anki was unable to add an audio file to your deck. This may be caused by a problem with Anki, the smart.fm! plugin, or both. Please inform the plugin developer.")
        mw.reset(mw.mainWin)
    except SmartFMDownloadError:
        progress.logMsg(traceback.format_exc())
        progress.dialog.cancel()
        progress.close()
        QMessageBox.warning(mw,"Warning","There was a problem retrieving data from Smart.fm. When you hit 'OK', a browser window will open to check that you can reach smart.fm.<br /><br />If this browser window shows an error, then please wait for smart.fm to be fixed, and try importing cards again. If there is no error in the browser window and you see some content relevant to your study list, please notify the plugin developer at http://github.com/ridisculous/anki-iknow-importer/issues")
        try:
            QDesktopServices.openUrl(QUrl(iknow.lastUrlFetched))
        except:
            pass
        mw.reset(mw.mainWin)
    except:
        progress.logMsg(traceback.format_exc())
        progress.dialog.cancel()
        progress.close()
        QMessageBox.warning(mw, "Warning", "There was an unknown error importing items. Please contact the plugin developer at http://github.com/ridisculous/anki-iknow-importer/issues<br /><br />Please be sure to include the file 'iknow-smartfm-log.txt' from your plugins directory with a description of what you tried to do before this error.")
        mw.reset(mw.mainWin)



def runDialog():
    importSettings = SmartFMImportSettings()
    if not mw.deck:
        QMessageBox.information(mw, "Information", "Please open a deck before using this plugin. Thanks!")
        return
    dialog = IknowImportDialog(importSettings)
    if dialog.exec_():
        #DEBUG: QMessageBox.information(mw, "Information", "Got some import settings '%s' type '%s'" % (importSettings.listId, str(type(importSettings.listId))))
        if not importSettings.importSentences and not importSettings.importVocab:
            return
        cardSettings = SmartFMCardTypeSettings()
        modelManager = SmartFMModelManager(importSettings)
        if modelManager.isNeedsVocabModel() or modelManager.isNeedsSentenceModel():
            cardEditDialog = SmartFMModelCustomizeDialog(cardSettings, modelManager.isNeedsVocabModel(), modelManager.isNeedsSentenceModel())
            if cardEditDialog.exec_():
                modelManager.createModelsFromSettings(cardSettings)
                #DEBUG: QMessageBox.information(mw, "Information", "Created required models, importing...")
                #automatically enable audio download if the user selects listening cards
                if cardSettings.vocabListening or cardSettings.sentenceListening:
                    importSettings.downloadAudio = True
                runImport(modelManager, importSettings)
            else:
                pass
                #DEBUG: QMessageBox.information(mw, "Information", "Cancelled on card types dialog")
        else:
            #DEBUG: QMessageBox.information(mw, "Information", "All required models already exist, importing...")
            runImport(modelManager, importSettings)
    else:
        pass
        #DEBUG: QMessageBox.warning(mw, "Warning", "Cancelled on import settings dialog")


def showHelp():
    try:
        QDesktopServices.openUrl(QUrl("http://wiki.github.com/ridisculous/anki-iknow-importer"))
    except:
        QMessageBox.information(mw, "Information", "Please see the smart.fm importer wiki at http://wiki.github.com/ridisculous/anki-iknow-importer.")

dialogStart = QAction(mw)
dialogStart.setText("Smart.fm Importer")
mw.connect(dialogStart, SIGNAL("triggered()"), runDialog)
mw.mainWin.menuTools.addAction(dialogStart)

mw.actionSmartFMHelp = QtGui.QAction(mw)
mw.actionSmartFMHelp.setObjectName("smartfmHelp")
mw.actionSmartFMHelp.setText(_("Open Smart.FM Importer Help Wiki"))
mw.connect(mw.actionSmartFMHelp, SIGNAL("triggered()"), showHelp)
menu = None
try:
    menu = mw.mainWin.menuPlugins
except:
    menu = mw.mainWin.menuTools
menu.addSeparator()
menu.addAction(mw.actionSmartFMHelp)