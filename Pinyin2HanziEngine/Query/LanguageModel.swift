//
//  LanguageModel.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/29/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

class Weight {
    var phraseHash: UInt64 = 0
    var probability: Double?
    
    init(hash: UInt64) { // for phrase not in cache
        self.phraseHash = hash
    }
}

enum QueryStatus {
    case needPhrase
    case needPhraseUnknown
    case needUnknownPhrase
}

class BiWeight: Weight {
    var phraseUnknown: UInt64
    var unknownPhrase: UInt64
    var phrase1: UInt64
    var phrase2: UInt64
    
    var phrase1Weight: Weight?
    var phrase2Weight: Weight?
    
    var status: QueryStatus = .needPhrase
    var isDone: Bool = false
    var delta: Double?
    
    var hashToQuery: UInt64 {
        var hash: UInt64 = 0
        
        switch self.status {
        case .needPhrase:
            hash = phraseHash
        case .needPhraseUnknown:
            hash = phraseUnknown
        case .needUnknownPhrase:
            hash = unknownPhrase
        }
        
        return hash
    }
    
    init(phrase1: String, phrase2: String) {
        self.phrase1 = phrase1.stableHash
        self.phrase2 = phrase2.stableHash
        self.phraseUnknown = (phrase1 + " <unknown>").stableHash
        self.unknownPhrase = ("<unknown> " + phrase2).stableHash
        
        super.init(hash: (phrase1 + " " + phrase2).stableHash)
    }
    
    func setupWeight(weightDic: inout [UInt64: Weight]) {
        /* add weight1 to Biweight */
        if let weight1 = weightDic[self.phrase1] {
            self.phrase1Weight = weight1
        } else {
            let newWeight = Weight(hash: self.phrase1)
            weightDic[self.phrase1] = newWeight
            self.phrase1Weight = newWeight
        }
        /* add weight2 to Biweight */
        if let weight2 = weightDic[self.phrase2] {
            self.phrase2Weight = weight2
        } else {
            let newWeight = Weight(hash: self.phrase2)
            weightDic[self.phrase2] = newWeight
            self.phrase2Weight = newWeight
        }
    }
}

class LanguageModel {
    var lexicon: LexiconTree
    var db: DatabaseQueue // connection to unigram/bigram databse
    
    let unknown: String = "<unknown>"
    let infiniteEstimation: Double = 1e-100
    let E: Double = 2.71828
    
    var cache: LRUCache = LRUCache<UInt64, Double>(cacheLimit: 2000)
    
    var weightQuery: [UInt64: Weight] = [:]
    var biweightQuery: [UInt64: BiWeight] = [:]
    
    init(lexicon: LexiconTree, databaseConnection connection: DatabaseQueue) {
        self.lexicon = lexicon
        self.db = connection
    }
    
    func getUnigram(phrase: String) -> Weight {
        let phraseHash = phrase.stableHash
        
        if let weight = weightQuery[phraseHash] {
            return weight
        }
        
        /* add weight to weight Query if it does not exist in weightQury */
        let weight = Weight(hash: phraseHash)
        weightQuery[phraseHash] = weight
        
        return weight
    }
    
    func getBigram(phrase1: String, phrase2: String) -> BiWeight {
        let phraseHash = (phrase1 + " " + phrase2).stableHash
        if let weight = biweightQuery[phraseHash] {
            return weight
        }
        
        let weight = BiWeight(phrase1: phrase1, phrase2: phrase2)
        biweightQuery[phraseHash] = weight
        
        return weight
    }
    
    func queryProbability() {
        for _ in 0..<3 {
            var hashes: Set<UInt64> = Set() // a set to store hashs to query
            for weight in biweightQuery.values {
                if weight.isDone { // skip this one if we query it already
                    continue
                }
                            
                if let prob = cache[weight.hashToQuery] { // check cache
                    if weight.status == .needPhrase {
                        weight.probability = prob
                    } else {
                        weight.delta = prob + E
                        weight.setupWeight(weightDic: &weightQuery)
                    }
                    weight.isDone = true
                } else {
                    hashes.insert(weight.hashToQuery)
                }
            }
            
            /* compose query string */
            let query = Array(hashes).map{ String($0) }.joined(separator: ", ")
            var queryResult: [UInt64: Double] = [:]
            
            db.read { db in
                if let rows = try? Row.fetchAll(db, sql: "select * from bigram where hash in (\(query))") {
                    for row in rows {
                        queryResult[row["hash"]] = row["probability"]
                    }
                }
            }
            
            /* put queried result back to weight */
            for weight in biweightQuery.values {
                if weight.isDone {
                    continue
                }
                
                if let prob = queryResult[weight.hashToQuery] {
                    switch weight.status {
                    case .needPhrase:
                        weight.probability = prob
                    case .needPhraseUnknown, .needUnknownPhrase:
                        weight.delta = prob + E
                        weight.setupWeight(weightDic: &weightQuery)
                    }
                    cache[weight.hashToQuery] = prob
                    weight.isDone = true
                } else {
                    /* move to next status if missed */
                    switch weight.status {
                    case .needPhrase:
                        weight.status = .needPhraseUnknown
                    case .needPhraseUnknown:
                        weight.status = .needUnknownPhrase
                    case .needUnknownPhrase:
                        weight.delta = E
                        weight.setupWeight(weightDic: &weightQuery)
                    }
                }
            }
        }
        
        /* query all the uni-weight */
        var unWeightHashes: Set<UInt64> = Set()
        for weight in weightQuery.values {
            if let prob = cache[weight.phraseHash] {
                weight.probability = prob
            } else {
                unWeightHashes.insert(weight.phraseHash)
            }
        }
        
        let query = Array(unWeightHashes).map{ String($0) }.joined(separator: ", ")
        var queryResult: [UInt64: Double] = [:]
        
        db.read { db in
            if let rows = try? Row.fetchAll(db, sql: "select * from unigram where hash in (\(query))") {
                for row in rows {
                    queryResult[row["hash"]] = row["probability"]
                }
            }
        }
        
        /* update uni-weight w/ query result */
        for weight in weightQuery.values {
            if weight.probability == nil {
                if let prob = queryResult[weight.phraseHash] {
                    weight.probability = prob
                    cache[weight.phraseHash] = prob
                } else {
                    weight.probability = infiniteEstimation
                }
            }
        }
        
        /* update Biweight */
        for weight in biweightQuery.values {
            if weight.probability == nil {
                let probability = weight.phrase1Weight!.probability! * weight.phrase2Weight!.probability! * weight.delta!
                weight.probability = probability
                cache[weight.hashToQuery] = probability
            }
        }
        
        weightQuery.removeAll()
        biweightQuery.removeAll()
    }
}
