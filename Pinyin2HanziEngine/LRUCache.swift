//
//  LRUCache.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/26/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

class Node<K: Equatable, V>: Equatable {
    var prev: Node<K, V>?
    var next: Node<K, V>?
    var key: K
    var value: V
    
    init(key: K, value: V) {
        self.key = key
        self.value = value
    }
    
    static func == (lhs: Node<K, V>, rhs: Node<K, V>) -> Bool {
        return lhs.key == rhs.key
    }
}

class DoubleLinkedList<Key: Equatable, Value> {
    var head: Node<Key, Value>? = nil
    var tail: Node<Key, Value>? = nil
    
    var count = 0
    
    func append(key: Key, value: Value) -> Node<Key, Value> {
        let newNode = Node(key: key, value: value)
        
        if let tail = self.tail {
            tail.next = newNode
            newNode.prev = tail
            self.tail = newNode
        } else {
            self.head = newNode
            self.tail = newNode
        }
        
        count += 1
        return newNode
    }
    
    func prepend(key: Key, value: Value) -> Node<Key, Value> {
        let newNode = Node(key: key, value: value)
        
        if let head = self.head {
            head.prev = newNode
            newNode.next = head
            self.head = newNode
        } else {
            self.head = newNode
            self.tail = newNode
        }
        
        count += 1
        return newNode
    }
    
    func swim(node: Node<Key, Value>) {
        if self.head == node {
            return // head already, no need to swim
        }
        
        if self.tail == node {
            self.tail = node.prev // move tail to its prev if necessary
        }
        
        /* disconnect node from current list */
        node.prev!.next = node.next // it must have a prev
        if let nextNode = node.next {
            nextNode.prev = node.prev
        }
        
        /* insert it to the head*/
        node.prev = nil
        node.next = self.head
        self.head!.prev = node
        self.head = node
    }
    
    func evict() -> Key? {
        var returnKey: Key?
        
        if self.head == nil {
            return returnKey
        }
        
        if let tail = self.tail {
            if self.head == tail { // special case when list has only one element
                returnKey = tail.key
                self.head = nil
                self.tail = nil
            } else {
                tail.prev!.next = nil
                self.tail = tail.prev
                tail.prev = nil
                returnKey = tail.key
            }
        }
        
        count -= 1
        return returnKey
    }
}


class LRUCache<Key: Hashable, Value> {
    var hashTable: [Key: Node<Key, Value>] = [:]
    var list: DoubleLinkedList<Key, Value> = DoubleLinkedList()
    var limit: Int
    
    init(cacheLimit: Int) {
        self.limit = cacheLimit
    }
    
    var count: Int {
        print("Internal: hashtable has \(self.hashTable.count) and list has \(self.list.count)")
        return self.hashTable.count
    }
    
    subscript(key: Key) -> Value? {
        get {
            if let node = hashTable[key] {
                list.swim(node: node)
                return node.value
            }
            return nil
        }
        set {
            if let value = newValue { // add newValue to Cache
                if let node = hashTable[key] { // update value
                    node.value = value
                    list.swim(node: node)
                } else { // insert new value
                    self.hashTable[key] = list.prepend(key: key, value: value)
                    if list.count > self.limit {
                        self.hashTable[list.evict()!] = nil
                    }
                }
            } else { // remove value from cache
                // do nothing
            }
        }
    }
}
