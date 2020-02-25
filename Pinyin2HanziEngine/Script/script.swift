//
//  script.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/25/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation
import GRDB

func generateDatabase() {
    // init unigram
    print("load unigram")
    let databasePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    let dbQueue = try? DatabaseQueue(path: "\(databasePath)/db.sqlite3")
    print(databasePath)

    do {
        try dbQueue!.write { db in
            try db.create(table: "unigram") { t in
                t.column("hash", .integer).unique().notNull()
                t.column("probability", .double).notNull()
            }
        }
    } catch {
        print("failed to create unigram table")
    }
            
    print("start unigram")
    if let path = Bundle.main.path(forResource: "unigram", ofType: "txt") {
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            let lines = data.split(separator: "\n")
            let length = lines.count
            for (index, line) in lines.enumerated() {
                let parts = line.split(separator: " ")
                let phrase = String(parts[0])
                let probability = Double(parts[1])
                do {
                    try dbQueue!.write { db in
                        try db.execute(sql: "INSERT INTO unigram (hash, probability) VALUES (?, ?)",
                                       arguments: [phrase.stableHash, probability!])
                    }
                } catch {
                    print("failed to write w/ \(phrase) and \(phrase.stableHash)")
                    print(phrase)
                }
                if index % 1000 == 0 {
                    print("\(index)/\(length)")
                }
            }
        } catch {
            print(error)
        }
    }

    do {
        try dbQueue!.write { db in
            try db.create(table: "bigram") { t in
                t.column("hash", .integer).unique().notNull()
                t.column("probability", .double).notNull()
            }
        }
    } catch {
        print("failed to create bigram table")
    }

    print("start bigram")
    if let path = Bundle.main.path(forResource: "bigram", ofType: "txt") {
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            let lines = data.split(separator: "\n")
            let length = lines.count
            for (index, line) in lines.enumerated() {
                let parts = line.split(separator: " ")
                let phrase = String(parts[0] + " " + parts[1])
                let probability = Double(parts[2])
                do {
                    try dbQueue!.write { db in
                        try db.execute(sql: "INSERT INTO bigram (hash, probability) VALUES (?, ?)",
                                       arguments: [phrase.stableHash, probability])
                    }
                } catch {
                    print("failed to write w/ \(phrase) and \(phrase.stableHash)")
                }
                if index % 1000 == 0 {
                    print("\(index)/\(length)")
                }
            }
        } catch {
            print(error)
        }
    }
    
    print("end")
}


func stableHash(string: String) -> UInt64 {
    var result = UInt64 (5381)
    let buf = [UInt8](string.utf8)
    for b in buf {
        result = 127 * (result & 0x00ffffffffffffff) + UInt64(b)
    }
    return result
}
