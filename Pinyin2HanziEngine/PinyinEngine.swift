//
//  PinyinEngine.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/18/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

class PinyinEngine {
    var syllableSet: Set<String> = Set()
    var lexiconTree: LexiconTree
    var languageModel: LanguageModel
    
    var database: DatabaseQueue! // grams database
    var lexicon: DatabaseQueue! // phrase database

    init() {
        // init syllable
        print("load valid syllable")
        if let path = Bundle.main.path(forResource: "syllable", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let lines = data.split(separator:"\n")
                for word in lines {
                    syllableSet.insert(String(word))
                }
            } catch {
                print(error)
            }
        }
        
        if let path = Bundle.main.path(forResource: "lexicon", ofType: "sqlite3") {
            do {
                let db = try DatabaseQueue(path: path)
                self.lexicon = db
            } catch {
                print("failed to load lexicon database")
            }
        }
        
        self.lexiconTree = LexiconTree(database: self.lexicon)
        
        if let path = Bundle.main.path(forResource: "db", ofType: "sqlite3") {
            do {
                var config = Configuration()
                config.prepareDatabase = { db in
                    try? db.execute(sql: "PRAGMA synchronous=OFF")
                    try? db.execute(sql: "PRAGMA journal_mode=OFF")
                    try? db.execute(sql: "PRAGMA locking_mode=EXCLUSIVE")
                    try? db.execute(sql: "PRAGMA query_only=1")
                    try? db.execute(sql: "PRAGMA optimize")
                }
                config.readonly = true
                let db = try DatabaseQueue(path: path, configuration: config)
                self.database = db
            } catch {
                print("failed to load database")
            }
        }
        
        self.languageModel = LanguageModel(lexicon: lexiconTree, databaseConnection: database)
    }
    
    func getSentence(pinyin: String) -> [Solution] {
        var time: [DispatchTime] = []
        // init syllable graph
        time.append(DispatchTime.now())
        print("initialize syllable graph")
        let syllableGraph = SyllableGraph(pinyin: pinyin, validSyllable: self.syllableSet)
        time.append(DispatchTime.now())
        
        // init lexicon graph
        print("initialize lexicon graph")
        let lexiconGraph = LexiconGraph(numberOfVertex: syllableGraph.vertexCount,
                                        pinyinSequences: syllableGraph.getPinyinSequence(maxLength: 5),
                                        tree: lexiconTree)
        time.append(DispatchTime.now())
        
        print("initialize SLMGraph")
        let slmGraph = SLMGraph(lexiconGraph: lexiconGraph, model: languageModel, limit: 5)
        time.append(DispatchTime.now())

        print("make sentence")
        let result = slmGraph.makeSentence()
        time.append(DispatchTime.now())
        
        let description = ["syllable graph", "lexicon graph", "SLMGraph", "Make sentence"]
        for i in 1..<time.count {
            let elapsed = Double(time[i].uptimeNanoseconds - time[i-1].uptimeNanoseconds) / 1_000_000
            print("\(description[i-1]): \(elapsed)")
        }
        print("Cache size: \(self.languageModel.cache.count)")
//        let cacheRaio: String = String(format: "%.2f", Double(languageModel.cacheHit)/Double(languageModel.totalQuery)*100)
//        print("Cache hit ratio: \(languageModel.cacheHit)/\(languageModel.totalQuery) \(cacheRaio)")

        
        return result
    }
}

extension String {
    var stableHash: UInt64 {
        var result = UInt64 (5381)
        let buf = [UInt8](self.utf8)
        for b in buf {
            result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
        }
        return result
    }
}
