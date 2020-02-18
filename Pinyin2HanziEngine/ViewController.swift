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
        let lexiconTree: LexiconTree = LexiconTree()
        if let path = Bundle.main.path(forResource: "lexicon", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                let lines = data.split(separator:"\n")
                for word in lines {
                    let parts = word.split(separator: "\t")
                    let phrase = String(parts[1])
                    let pinyins = parts[0].split(separator: "'").map(String.init)
                    print(pinyins)
                    lexiconTree.insertPhrase(phrase: phrase, pinyins: pinyins)
                }
            } catch {
                print(error)
            }
        }
        
        // init syllable graph
        let syllableGraph = SyllableGraph(pinyin: "nihao", validSyllable: syllableSet)
        
        // init lexicon graph
        let lexiconGraph = LexiconGraph(numberOfVertex: syllableGraph.vertexCount,
                                        pinyinSequences: syllableGraph.getPinyinSequence(maxLength: 6),
                                        tree: lexiconTree)
    }
}

