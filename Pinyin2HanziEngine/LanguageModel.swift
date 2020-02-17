//
//  LanguageModel.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import Darwin

class LanguageModel {
    let unknown = "<unknown>"
    let infiniteEstimation: Double = 1e-100
    
    var lexicon: LexiconTree
    var unigram: [String: Double] = [:]
    var bigram: [String: [String: Double]] = [:]
    
    init(lexicon: LexiconTree, unigram: [String: Double], bigram: [String: [String: Double]]) {
        self.lexicon = lexicon
        self.unigram = unigram
        self.bigram = bigram
    }
    
    /* get P(w_i) */
    func getUnigram(phrase: String) -> Double {
        if let probability = unigram[phrase] {
            return probability
        }
        return infiniteEstimation
    }
    
    /* get P(w_i|w_j) */
    func getBigram(phrase1: String, phrase2: String) -> Double {
        var delta: Double = 0.0
        if let dict = bigram[phrase1] {
            if let prob = dict[phrase2] {
                return prob // P(phrase1|phrase2)
            } else if let unknownProb = dict[unknown] {
                delta = unknownProb // P(phrase1|unknown)
            }
        } else if let unknownDict = bigram[unknown] {
            if let unknownPhrase2 = unknownDict[phrase2] {
                delta = unknownPhrase2 // p(unknown|phrase2)
            }
        }
        return getUnigram(phrase: phrase1) * getUnigram(phrase: phrase2) * (Darwin.M_E + delta)
    }
}

