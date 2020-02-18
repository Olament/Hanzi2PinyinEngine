//
//  ViewController.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/8/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        ///data loading
        // init syllable
        print("load valid syllable")
        var syllableSet: Set<String> = Set()
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
        let lexiconTree: LexiconTree = LexiconTree()
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
        
        // init unigram
        print("load unigram")
        var unigram: [String: Double] = [:]
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
        var bigram: [String: [String: Double]] = [:]
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
        
        // init syllable graph
        print("initialize syllable graph")
        let syllableGraph = SyllableGraph(pinyin: "nihao", validSyllable: syllableSet)
        
        // init lexicon graph
        print("initialize lexicon graph")
        let lexiconGraph = LexiconGraph(numberOfVertex: syllableGraph.vertexCount,
                                        pinyinSequences: syllableGraph.getPinyinSequence(maxLength: 6),
                                        tree: lexiconTree)
        // langauge model
        print("initialize language model")
        let languageModel = LanguageModel(lexicon: lexiconTree, unigram: unigram, bigram: bigram)
        print("initialize SLMGraph")
        let slmGraph = SLMGraph(lexiconGraph: lexiconGraph, model: languageModel, limit: 6)
        
        print("make sentence")
        print(slmGraph.makeSentence())
    }
}

