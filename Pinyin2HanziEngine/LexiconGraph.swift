//
//  LexiconGraph.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/15/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

class EdgeData {
    var phrase: String
    var id: Int
    var pinyinSequence: PinyinSequence
    
    init(phrase: String, id: Int, pinyinSequence: PinyinSequence) {
        self.phrase = phrase
        self.id = id
        self.pinyinSequence = pinyinSequence
    }
}

class LexiconGraph: Graph<Int, EdgeData> {
    init(numberOfVertex count: Int, pinyinSequences: [PinyinSequence], tree: LexiconTree) {
        super.init(numberOfVertices: count)
        
        for sequence in pinyinSequences {
            if let phrases = tree.searchPhrase(pinyins: sequence.pinyinSequence) {
                for phrase in phrases {
                    let edge = addEdge(from: self.vertices[sequence.from], to: self.vertices[sequence.to])
                    edge.data = EdgeData(phrase: phrase, id: self.edgeCount, pinyinSequence: sequence) // add id in sequence
                }
            }
        }
    }
}
