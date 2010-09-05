# -*- coding: utf-8 -*-
#
# Learn Mode (a plugin for Anki)
# Coded by Thomas Bereknyei <tomberek@gmail.com>
# Version 0.3 (2009-08-26)
#
# Based on the Add Icons to Toolbar and Anki code by Damien Elmes <anki@ichi2.net>
#
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
#
#0.1 Basic plugin. Added tag support
#
#0.2 Learn mode can be accessed through card browser and selection of cards.
#
#0.3 Fixed bug: crash when entering learn mode from open card.
from PyQt4 import QtCore, QtGui
from PyQt4.QtGui import *
from PyQt4.QtCore import *
import os, sys
import tempfile
import ankiqt
import ankiqt.ui
ui = ankiqt.ui
from anki.utils import *
from ankiqt import mw
from anki.hooks import *
from anki.hooks import _hooks

def init():
    #This adds the Learn action just before the Cram action in the main window
    mw.mainWin.actionLearn = QtGui.QAction(mw)
    icon99 = QtGui.QIcon()
    icon99.addPixmap(QtGui.QPixmap(":/icons/list-add.png"), QtGui.QIcon.Normal, QtGui.QIcon.Off)  
    mw.mainWin.actionLearn.setIcon(icon99)
    mw.mainWin.actionLearn.setObjectName("actionLearn")
    mw.mainWin.actionLearn.setText(_("L&earn..."))
    mw.mainWin.actionLearn.setStatusTip(_("Review a set of 7 new cards"))
    mw.mainWin.menuTools.insertAction(mw.mainWin.actionCram,mw.mainWin.actionLearn)
    s = SIGNAL("triggered()")
    mw.connect(mw.mainWin.actionLearn, s, onLearn)

#This hook allows init to run when the plugin loads
mw.addHook("init", init)

#mw.registerPlugin("Learn Mode", 13)  #not sure what this is for

# Adds 'Learn' to the card browser
def browserLearnSetup(cardWin):
    cardWin.dialog.actionLearn = QtGui.QAction(mw)
    icon98 = QtGui.QIcon()
    icon98.addPixmap(QtGui.QPixmap(":/icons/list-add.png"), QtGui.QIcon.Normal, QtGui.QIcon.Off)
    cardWin.dialog.actionLearn.setIcon(icon98)
    cardWin.dialog.actionLearn.setObjectName("actionLearn")
    cardWin.dialog.actionLearn.setText(_("&Learn..."))
    cardWin.dialog.actionLearn.setStatusTip(_("Review a set of cards by selection or tag (7 newest cards is default)"))
    cardWin.dialog.menuActions.insertAction(cardWin.dialog.actionCram,cardWin.dialog.actionLearn)
    s = SIGNAL("triggered()")
    cardWin.connect(cardWin.dialog.actionLearn, s, Learn)
    mw.cardWin=cardWin #to help the Learn method work
mw.addHook("editor.setupMenus",browserLearnSetup)

# The method run when Learn is chosen in the card browser.
def Learn():
    if ui.utils.askUser(
        _("Learn selected cards in new deck?"),
        help=""):
        mw.cardWin.close()
        onLearn(mw.cardWin.selectedCards())  #this is where I use cardWin line 46
mw.cardWin=[] #This is a hack to allow me to access the dialog window. If anyone knows a better way, let me know.

# Creates a temp deck. Limits by tag and id, defaults is to seven new cards.
def _copyToLearnDeck(name="cram.anki", tags="", ids=[]):
    ndir = tempfile.mkdtemp(prefix="anki")
    path = os.path.join(ndir, name)
    from anki.exporting import AnkiExporter
    e = AnkiExporter(mw.deck)
    e.includeMedia = False
    if tags:
        e.limitTags = parseTags(tags)
    if ids:
        e.limitCardIds = ids
    else:
        cardIDtup=mw.deck.s.all("select id from %s limit 7" % mw.deck.newCardTable())
        for q in cardIDtup:
            e.limitCardIds += q.values()
    path = unicode(path, sys.getfilesystemencoding())
    e.exportInto(path)
    return (e, path)

#helper function
def isLearning():
        return mw.deck is not None and mw.deck.name() == "cram"

#Prevents learning of a learn deck.
def onLearn(cardIds=[]):
    if isLearning():
        ui.utils.showInfo(
            _("Already learning. Please close this deck first."))
        return
    if not mw.save(required=True):
        return
    if not cardIds:
        (s, ret) = ui.utils.getTag(mw,
                                   mw.deck, _("Press enter to get 7 new cards or enter tags to learn:"),
                                   help="LearnMode", tags="all")
        if not ret:
            return
        s = unicode(s)
        # open learn deck
        (e, path) = _copyToLearnDeck(tags=s)
    else:
        (e, path) = _copyToLearnDeck(ids=cardIds)
    if not e.exportedCards:
        ui.utils.showInfo(_("No cards matched the provided tags."))
        return
    if mw.config['randomizeOnCram']:
        n = 3
    else:
        n = 2
    p = ui.utils.ProgressWin(mw, n, 0, _("Learn"))
    p.update(_("Loading deck..."))
    oldMedia = mw.deck.mediaDir()
    mw.deck.close()
    mw.deck = None
    mw.loadDeck(path, media=oldMedia)
    mw.config['recentDeckPaths'].pop(0)
    mw.deck.newCardsPerDay = 9999 #9999
    mw.deck.delay0 = 1 #300
    mw.deck.delay1 = 1 #600
    mw.deck.hardIntervalMin = 0.000057870370 # 5sec
    mw.deck.hardIntervalMax = 0.000115740741 # 10sec
    mw.deck.midIntervalMin = 0.000115740741 # 10sec
    mw.deck.midIntervalMax = 0.000173611111 # 15sec
    mw.deck.easyIntervalMin = 0.000173611111 # 15sec
    mw.deck.easyIntervalMax = 0.000231481481 # 20sec
    mw.deck.newCardOrder = 0 #0
    mw.deck.syncName = None
    mw.deck.collapseTime = 1
    p.update()
    mw.deck.updateDynamicIndices()
    if mw.config['randomizeOnCram']:
        p.update(_("Randomizing..."))
        mw.deck.randomizeNewCards()
    mw.reset()
    mw.deck.s.statement("update models set initialSpacing=0")
    p.finish()
