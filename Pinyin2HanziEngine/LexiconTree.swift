//
//  Lexion.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/15/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

/*
 This is a data structure like R-Trie, where edge is valid syllable and node store possible phrase
 */
//class LexiconTree {
//    class Node: CustomStringConvertible {
//        var children: [String: Node] = [:]
//        var phrase: [String] = [] // the chinese phrase/vocab
//
//        var description: String {
//            return "\(children)\n\(phrase)"
//        }
//    }
//
//    var root: Node = Node()
//    var pinyinSyllable: Set<String> // a hash set contains valid syllable
//    var lexicon: Set<String> = Set()
//    var maxLength: Int = 0 // maximum length of phrase
//
//    var count: Int {
//        return lexicon.count
//    }
//
//    /* initialize valid pinyin syllable */
//    init(pinyinSyllable: Set<String>) {
//        self.pinyinSyllable = pinyinSyllable
//    }
//
//    func insertPhrase(phrase: String, pinyins: [String]) {
//        insertPhrase(currentNode: self.root, phrase: phrase, pinyins: pinyins, index: 0)
//    }
//
//    private func insertPhrase(currentNode: Node, phrase: String, pinyins: [String], index: Int) {
//        if !pinyinSyllable.contains(pinyins[index]) { // check if pinyin is valid
//            return
//        }
//
//        let child: Node
//        if let node = currentNode.children[pinyins[index]] { // check if we have a child with pinyin[index] already
//            child = node
//        } else {
//            currentNode.children[pinyins[index]] = Node()
//            child = currentNode.children[pinyins[index]]!
//        }
//
//        if index == pinyins.count - 1 { // reach the end of tree
//            child.phrase.append(phrase)
//            lexicon.insert(phrase)
//            maxLength = max(maxLength, phrase.count)
//        } else {
//            insertPhrase(currentNode: child, phrase: phrase, pinyins: pinyins, index: index+1)
//        }
//    }
//
//    func searchPhrase(pinyins: [String]) -> [String]? {
//        return self.searchPhrase(currentNode: root, pinyins: pinyins, index: 0)
//    }
//
//    private func searchPhrase(currentNode: Node, pinyins: [String], index: Int) -> [String]? {
//        if let child = currentNode.children[pinyins[index]] {
//            if index == pinyins.count - 1 {
//                return child.phrase
//            } else {
//                return searchPhrase(currentNode: child, pinyins: pinyins, index: index+1)
//            }
//        }
//
//        return nil
//    }
//}

class LexiconTree {
    let shenmu = ["b": "a", "p": "b", "m": "c", "f": "d", "d": "e",
                  "t": "f", "n": "g", "l": "h", "g": "i", "k": "j",
                  "h": "k", "j": "l", "q": "m", "x": "n", "zh": "o",
                  "ch": "p", "sh": "q", "r": "r", "z": "s", "c": "t",
                  "s": "u", "y": "v", "w": "w"]
    let yunmu = ["a": "A", "o": "B", "e": "C", "i": "D", "u": "E",
                 "v": "F", "ai": "G", "ei": "H", "ui": "I", "ao": "J",
                 "ou": "K", "iu": "L", "ie": "M", "ue": "N", "er": "O",
                 "an": "P", "en": "Q", "in": "R", "un": "S",
                 "ang": "T", "eng": "U", "ing": "V", "ong": "W",
                 "ia": "0", "iao": "1", "ian": "2", "iang": "3", "iong": "4",
                 "ua": "5", "uo": "6", "uai": "7", "uan": "8", "uang": "9"]
    
    var db: DatabaseQueue
    
    init(database: DatabaseQueue) {
        self.db = database
    }
    
    func searchPhrase(pinyins: [String]) -> [String]? {
        var phrases: [String]?
        db.read { db in
            phrases = try? String.fetchAll(db, sql: "select vocab from lexicon where code glob \"\(encodePinyin(pinyins: pinyins))\"")
        }
        return phrases
    }
    
    private func encodePinyin(pinyins: [String]) -> String {
        var codes: String = ""
        for pinyin in pinyins {
            var index = 0 // keep track of where we are
            /* isolate shenmu from pinyin string */
            if let code = self.shenmu[pinyin[0..<2]] {
                codes += code
                index = 2
            } else if let code = self.shenmu[pinyin[0..<1]] {
                codes += code
                index = 1
            }
            // since we get ride of shenmu, rest of them must be yunmu
            codes += self.yunmu[pinyin[index...]]!
        }
        return codes
    }
}
