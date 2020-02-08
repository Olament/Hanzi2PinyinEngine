//
//  PinyinSequence.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/8/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

class PinyinSequence {
    var pinyinSequence: [String]
    var from: Int
    var to: Int
    
    init(sequences: [String], from: Int, to: Int) {
        self.pinyinSequence = sequences
        self.from = from
        self.to = to
    }
}
