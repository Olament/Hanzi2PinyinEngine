//
//  Lexion.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/15/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

/*
 This is a data structure like R-Trie, where edge is valid syllable and node store possible phrase
 */
class LexiconTree {
    class Node {
        var children: [String: Node] = [:]
        var phrase: [String] = [] // the chinese phrase/vocab
    }
    
    var root: Node = Node()
    var pinyinSyllable: Set<String> = [] // a hash set contains valid syllable
    var lexicon: Set<String> = Set()
    var maxLength: Int = 0 // maximum length of phrase
    
    var count: Int {
        return lexicon.count
    }
    
    func insertPhrase(phrase: String, pinyins: [String]) {
        insertPhrase(currentNode: self.root, phrase: phrase, pinyins: pinyins, index: 0)
    }
    
    private func insertPhrase(currentNode: Node, phrase: String, pinyins: [String], index: Int) {
        if !pinyinSyllable.contains(pinyins[index]) { // check if pinyin is valid
            return
        }
        
        let child: Node
        if let node = currentNode.children[pinyins[index]] { // check if we have a child with pinyin[index] already
            child = node
        } else {
            child = Node()
            currentNode.children[pinyins[index]] = child
        }
        
        if index == pinyins.count - 1 { // reach the end of tree
            child.phrase.append(phrase)
            lexicon.insert(phrase)
            maxLength = max(maxLength, phrase.count)
        } else {
            insertPhrase(currentNode: child, phrase: phrase, pinyins: pinyins, index: index+1)
        }
    }
    
    func searchPhrase(pinyins: [String]) -> [String]? {
        return self.searchPhrase(currentNode: root, pinyins: pinyins, index: 0)
    }
    
    private func searchPhrase(currentNode: Node, pinyins: [String], index: Int) -> [String]? {
        if let child = currentNode.children[pinyins[index]] {
            if index == pinyins.count - 1 {
                return child.phrase
            } else {
                return searchPhrase(currentNode: child, pinyins: pinyins, index: index+1)
            }
        }
        
        return nil
    }
}
