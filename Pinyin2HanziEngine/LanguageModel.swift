//
//  LanguageModel.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import Darwin
import GRDB

class LanguageModel {
    let unknown = "<unknown>"
    let infiniteEstimation: Double = 1e-100

    var lexicon: LexiconTree
    //var unigram: [String: Double] = [:]
    //var bigram: [String: [String: Double]] = [:]

    var db: DatabaseQueue // connection to unigram/bigram databse

    init(lexicon: LexiconTree, databaseConnection connection: DatabaseQueue) {
        self.lexicon = lexicon
        self.db = connection
    }

    /* get P(w_i) */
    func getUnigram(phrase: String) -> Double {
        var probability: Double = self.infiniteEstimation

        db.read { db in
            if let prob = try? Double.fetchOne(db, sql: "SELECT probability from unigram where hash = ?", arguments: [phrase.stableHash]) {
                probability = prob
            }
        }

        return probability
    }

    /* get P(w_i|w_j) */
    func getBigram(phrase1: String, phrase2: String) -> Double {
        var delta: Double = 0.0
        var probability: Double = 0.0
        
        let phrase = phrase1 + " " + phrase2 // for P(phrase1|phrase2)
        let phrase1_unknown = phrase1 + " " + self.unknown // for P(phrase1|unknown)
        let unknown_phrase2 = self.unknown + " " + phrase2 // for P(unknown|phrase2)
        
        db.read{ db in
            if let prob = try? Double.fetchOne(db, sql: "SELECT probability from unigram where hash = ?", arguments: [phrase.stableHash]) {
                probability = prob
            } else if let prob = try? Double.fetchOne(db, sql: "SELECT probability from unigram where hash = ?", arguments: [phrase1_unknown.stableHash]) {
                delta = prob
            } else if let prob = try? Double.fetchOne(db, sql: "SELECT probability from unigram where hash = ?", arguments: [unknown_phrase2.stableHash]) {
                delta = prob
            }
        }
        
        return probability != 0.0 ? probability : getUnigram(phrase: phrase1) * getUnigram(phrase: phrase2) * (Darwin.M_E + delta)
    }
}
