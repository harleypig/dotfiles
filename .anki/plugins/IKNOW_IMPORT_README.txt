iKnow! plugin for Anki
author: Joe Savona (joe savona at gmail dot com)

NOTE: This is not an official product of iKnow! It does, however, use iKnow!'s publicly documented API.

Please see http://wiki.github.com/ridisculous/anki-iknow-importer for the most up to date FAQ. The version at the time of this release is:


Anki smart.fm! Importer

This is the homepage for the (unofficial) smart.fm! import plugin for Anki. With this plugin, you can quickly import items you’ve studied on smart.fm! into your Anki deck. You can also import entire lists into Anki. The plugin allows you to configure Anki’s card templates as you like before importng, so that you can have cards that match the way you want to study.
Features

    * Import vocabulary and sentences, or sentences only
          o Import only the items you’ve actually studied (“My Items”)
          o Or import an entire smart.fm! list
    * Downloads audio samples for each item locally so you can still study offline.
    * Images are referenced so you can see them when you have online access (per smart.fm!’s terms of use)
    * Customize your card templates before importing to get only the cards you want. You can set up only one card per vocab/sentence, or many. When you first start importing into a deck, you can choose from the following card types (select/deselect as desired):
          o Reading (question is the expression (in Kanji where applicable))
          o Listening (question is audio only)
          o Production (question is the meaning of the item, you have to produce the expression)
    * Imports phonetic reading information for languages such as Chinese (pinyin) or Japanese (hiragana/katakana). Currently you cannot select romaji readings for Japanese lists. If you’re studying Japanese, you really, really should learn Hiragana straight away. For those studying Chinese, note that two written forms are included for the 'expression' (I believe these are simple and traditional). 

Download and Installation

   1. Download the latest version from the downloads page. Choose the highest version number.
   2. Save the .zip file to your Anki plugins directory.
          * On Mac OS X, this is /Users/username/Library/Application Support/Anki/plugins/.
          * To find the plugins directory, open Anki, and choose the menu item Settings->Plugins->Open Plugins Folder
   3. Extract the contents of the zip file. You should have “smart.fm.py” and “smart.fm_importer.py” in the plugins folder now (eg …/Anki/plugins/smart.fm.py)
   4. Restart or open Anki
   5. From the Tools menu, choose 'Smart.fm Importer'

Usage

   1. Select ‘Smart.fm Importer’ from the Tools menu.
   2. Choose what list to enter, and what items from that list:
     * Enter the list URL at the top
     * Choose vocab only, sentences only, or both vocab and sentences
     * Optionally enter a maximum number of items to import (if left blank all list items are imported)
     * If you don't want any listening practice, you can deselect 'download audio clips'
     * If you want to reinforce the keyword of each sentence, the 'include keyword meanings in sentence meanings' will add 'keyword -- meaning' to the end of a sentence's meaning.
     * If you want the keyword of a sentence to be bolded, choose 'bold sentence keywords'. This applies to bilingual lists. Monolingual lists (studying Japanese in Japanese) will automatically have keywords bolded. Deselecting this option ensures that keywords are *not* bolded
  3. Click 'Start Import'
  4. If this is your first import into a deck, you will see a new screen. Choose what card types to use for studying sentences, and for vocab. You can have different card types for vocab than you do for sentences. For example, vocab listening can be difficult with languages that have many homophones (eg Japanese) but you probably want listening practice for sentences.
  5. Finally, just wait as the data is downloaded from smart.fm. It'll take a little while, but then you'll be all set to study!

   
F.A.Q.

Q) I found a bug. What do I do?

A) Email the author (address above) and try to describe it in as much detail. Specifically, what version of Anki, what list were you importing (or if its your user data, just tell me your native language and the language you were trying to study). Also, what operating system are you on?

Q) Where does the reading come from?

A) For Japanese lists, it comes from smart.fm!’s own hiragana/katakana phonetic reading. For all other languages, it comes from the latin/romanized reading. Eg pinyin for chinese. Currently there is no option to get romaji readings for Japanese. Learn Hiragana!

Q) I don’t need audio. Can I skip downloading it?
A) Yes. Just unclick the checkbox on the import screen.

Q) I ran an import but no items were imported. What’s up with that?

A) If there were lots of duplicates, then you probably have just imported that list before. 

Q) This plugin is great and makes my life easier. How can I show my appreciation?

A) Email the author and say thanks!
License

This plugin is free. You may edit this plugin and distribute your own derivative, provided that you prominently note the original source of your work and link back to this page.
