//
//  LanguageModel.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

class LanguageModel {
    let unknown = "<unknown>"
    let infiniteEstimation: Double = 1e-100
    let E: Double = 2.71828

    var lexicon: LexiconTree
    var db: DatabaseQueue // connection to unigram/bigram databse
    
    //var cache: [UInt64: Double] = [:] // TODO: add LRU cache
    var cache: LRUCache = LRUCache<UInt64, Double>(cacheLimit: 2000)

    init(lexicon: LexiconTree, databaseConnection connection: DatabaseQueue) {
        self.lexicon = lexicon
        self.db = connection
    }

    /* get P(w_i) */
    func getUnigram(phrase: String) -> Double {
        var probability: Double = self.infiniteEstimation
        let hash = phrase.stableHash
        
        if let prob = cache[hash] {
            return prob
        } else {
            db.read { db in
                if let prob = try? Double.fetchOne(db, sql: "SELECT probability from unigram where hash = ?", arguments: [hash]) {
                    probability = prob
                }
            }
        }

        cache[hash] = probability
        return probability
    }

    /* get P(w_i|w_j) */
    func getBigram(phrase1: String, phrase2: String) -> Double {
        var delta: Double = 0.0
        var probability: Double = 0.0
        var layerHit = 0 // mark which query layer it hits
        
        let phraseHash = (phrase1 + " " + phrase2).stableHash
        let phraseUnknownHash = (phrase1 + " " + self.unknown).stableHash
        let unknownPhraseHash = (self.unknown + " " + phrase2).stableHash
                        
        if let prob = cache[phraseHash] {
            return prob
        } else if let prob = cache[phraseUnknownHash] {
            return prob
        } else if let prob = cache[unknownPhraseHash] {
            return prob
        } else {
            db.read{ db in
                if let prob = try? Double.fetchOne(db, sql: "SELECT probability from bigram where hash = ?", arguments: [phraseHash]) {
                    probability = prob
                } else if let prob = try? Double.fetchOne(db, sql: "SELECT probability from bigram where hash = ?", arguments: [phraseUnknownHash]) {
                    delta = prob
                    layerHit = 1
                } else if let prob = try? Double.fetchOne(db, sql: "SELECT probability from bigram where hash = ?", arguments: [unknownPhraseHash]) {
                    delta = prob
                    layerHit = 2
                }
            }
        }
        
        let result = probability != 0 ? probability : getUnigram(phrase: phrase1) * getUnigram(phrase: phrase2) * (self.E + delta)
        
        switch layerHit {
        case 1:
            cache[phraseUnknownHash] = result
        case 2:
            cache[unknownPhraseHash] = result
        default:
            cache[phraseHash] = result
        }
        
        return result
    }
}
