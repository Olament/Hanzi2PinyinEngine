//
//  Lexion.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/15/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

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
