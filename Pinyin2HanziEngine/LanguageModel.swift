//
//  LanguageModel.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import Darwin
import SQLite

class LanguageModel {
    let unknown = "<unknown>"
    let infiniteEstimation: Double = 1e-100
    
    var lexicon: LexiconTree
    //var unigram: [String: Double] = [:]
    //var bigram: [String: [String: Double]] = [:]
    
    var db: Connection! // connection to unigram/bigram databse
    let grams = Table("grams")
    let hash = Expression<Int>("hash")
    let probability = Expression<Double>("probability")
    
    init(lexicon: LexiconTree, databaseConnection connection: Connection) {
        self.lexicon = lexicon
        self.db = connection
    }
    
    /* get P(w_i) */
    func getUnigram(phrase: String) -> Double {
        let query = grams.select(probability).where(hash == phrase.hashValue).limit(1)
        do {
            for row in try db.prepare(query) {
                return row[probability]
            }
        } catch {
            // do nothing
        }
        
        return infiniteEstimation
    }
    
    /* get P(w_i|w_j) */
    func getBigram(phrase1: String, phrase2: String) -> Double {
        var delta: Double = 0.0
//        if let dict = bigram[phrase1] {
//            if let prob = dict[phrase2] {
//                return prob // P(phrase1|phrase2)
//            } else if let unknownProb = dict[unknown] {
//                delta = unknownProb // P(phrase1|unknown)
//            }
//        } else if let unknownDict = bigram[unknown] {
//            if let unknownPhrase2 = unknownDict[phrase2] {
//                delta = unknownPhrase2 // p(unknown|phrase2)
//            }
//        }
        return getUnigram(phrase: phrase1) * getUnigram(phrase: phrase2) * (Darwin.M_E + delta)
    }
}

