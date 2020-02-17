//
//  Solution.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/17/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

class Solution: Comparable {
    var sentence: String = ""
    var pinyin: [String] = []
    var probability: Double = 0.0
    
    func getPinyinString() -> String {
        return self.pinyin.joined(separator: " ")
    }
    
    static func < (lhs: Solution, rhs: Solution) -> Bool {
        return lhs.probability < rhs.probability
    }
    
    static func == (lhs: Solution, rhs: Solution) -> Bool {
        return lhs.probability == rhs.probability
    }
}
