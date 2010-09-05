# -*- coding: utf-8 -*-
import traceback
foundJapaneseSupportPlugin = False
mecabInstance = None
try:
    from japanese.reading import MecabController
    foundJapaneseSupportPlugin = True
    mecabInstance = MecabController()
except:
    pass

FIRST_HIRAGANA = ord(u"ぁ")
LAST_HIRAGANA = ord(u"ゖ")
FIRST_KATAKANA = ord(u"ァ")
LAST_CONVERTIBLE_KATAKANA = ord(u"ヶ")
KANA_OFFSET = FIRST_KATAKANA - FIRST_HIRAGANA

def asHiraganaOrEmpty(char):
    charOrd = ord(char)
    if charOrd >= FIRST_HIRAGANA and charOrd <= LAST_HIRAGANA:
        return char
    elif charOrd >= FIRST_KATAKANA and charOrd <= LAST_CONVERTIBLE_KATAKANA:
        return unichr(charOrd - KANA_OFFSET)
    else:
        return u""

def kanaOnly(string):
    kanaStr = u""
    for c in unicode(string):
        kanaStr += asHiraganaOrEmpty(c)
    return kanaStr
    
if not foundJapaneseSupportPlugin:
    def getAdjustedReadingOfText(originalText, originalReading):
        """given the original text, use JA support mecab plugin to find the reading. if the mecab reading matches the original reading, return the mecab formatted version (ie with kanjitext[kanareading] form). if the mecab reading does not match the original reading, return None."""
        return (originalReading, "original-mecab-unavailable")
else:
    def getAdjustedReadingOfText(originalText, originalReading, logMsg):
        """given the original text, use JA support mecab plugin to find the reading. if the mecab reading matches the original reading, return the mecab formatted version (ie with kanjitext[kanareading] form). if the mecab reading does not match the original reading, return None."""
        try:
            mecabReading = mecabInstance.reading(originalText)
            if len(originalReading) == 0:
                return (mecabReading, "no-original-using-mecab")
            elif kanaOnly(originalReading) != kanaOnly(mecabReading):
                return (mecabReading, "original-notequal-mecab")
            else:
                return (mecabReading, "mecab-ok")
        except:
            logMsg(traceback.format_exc().encode('utf-8'))
            return (originalReading, "mecab-error-using-original")