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
    //var unigram: [String: Double] = [:]
    //var bigram: [String: [String: Double]] = [:]
    var database: DatabaseQueue!

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
        
        // init Lexicon Tree
        print("load lexicon tree")
        lexiconTree = LexiconTree(pinyinSyllable: syllableSet)
        if let path = Bundle.main.path(forResource: "lexicon", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let lines = data.split(separator:"\n")
                for word in lines {
                    let parts = word.split(separator: "\t")
                    let phrase = String(parts[1])
                    let pinyins = parts[0].split(separator: "'").map(String.init)
                    lexiconTree.insertPhrase(phrase: phrase, pinyins: pinyins)
                }
            } catch {
                print(error)
            }
        }
        
        if let path = Bundle.main.path(forResource: "db", ofType: "sqlite3") {
            do {
                let db = try DatabaseQueue(path: path)
                self.database = db
            } catch {
                print("failed to load database")
            }
        }
        
        /*
        // init unigram
        print("load unigram")
        if let path = Bundle.main.path(forResource: "unigram", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let lines = data.split(separator: "\n")
                for line in lines {
                    let parts = line.split(separator: " ")
                    let phrase = String(parts[0])
                    let probability = Double(parts[1])
                    unigram[phrase] = probability
                }
            } catch {
                print(error)
            }
        }

        //init bigram
        print("load bigram")
        if let path = Bundle.main.path(forResource: "bigram", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let unknown = "<unknown>"
                let lines = data.split(separator: "\n")
                for line in lines {
                    let parts = line.split(separator: " ")
                    let phrase1 = String(parts[0])
                    let phrase2 = String(parts[1])
                    let probability = Double(parts[2])

                    if phrase1 != unknown && !syllableSet.contains(phrase1) {
                        continue
                    }
                    if phrase2 != unknown && !syllableSet.contains(phrase2) {
                        continue
                    }

                    var dict: [String: Double]
                    if bigram[phrase1] != nil {
                        dict = bigram[phrase1]!
                    } else {
                        dict = [:]
                        bigram[phrase1] = dict
                    }
                    dict[phrase2] = probability
                }
            } catch {
                print(error)
            }
        }
        */
    }
    
    func getSentence(pinyin: String) -> [Solution] {
        // init syllable graph
        print("initialize syllable graph")
        let syllableGraph = SyllableGraph(pinyin: pinyin, validSyllable: self.syllableSet)
        
        // init lexicon graph
        print("initialize lexicon graph")
        let lexiconGraph = LexiconGraph(numberOfVertex: syllableGraph.vertexCount,
                                        pinyinSequences: syllableGraph.getPinyinSequence(maxLength: 6),
                                        tree: lexiconTree)
                
        // langauge model
        print("initialize language model")
        let languageModel = LanguageModel(lexicon: lexiconTree, databaseConnection: database)
        print("initialize SLMGraph")
        let slmGraph = SLMGraph(lexiconGraph: lexiconGraph, model: languageModel, limit: 6)

        print("make sentence")
        return slmGraph.makeSentence()
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
