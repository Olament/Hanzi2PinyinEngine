//
//  LinkedList.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 3/5/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation

class Stack<E>: Sequence {
    class Node<E> {
        var item: E
        var next: Node?
        
        init(item: E, next: Node?) {
            self.item = item
            self.next = next
        }
    }
    
    private var head: Node<E>?
    
    var count = 0
    
    func pop() -> E {
        let returnElement: E = self.head!.item
        self.head!.next = nil // GC
        self.head = self.head?.next
        
        count -= 1
        
        return returnElement
    }
    
    func push(newElement: E) {
        let newNode = Node(item: newElement, next: self.head)
        self.head = newNode
        
        count += 1
    }
    
    func isEmpty() -> Bool {
        return count == 0
    }
    
    func makeIterator() -> StackIterator<E> {
        return StackIterator<E>(self.head)
    }
}

struct StackIterator<E>: IteratorProtocol {
    typealias Element = E
    
    var currentNode: Stack<E>.Node<E>?
    
    init(_ node: Stack<E>.Node<E>?) {
        self.currentNode = node
    }
    
    mutating func next() -> Element? {
        if let current = currentNode {
            self.currentNode = current.next
            return current.item
        }
        return nil
    }
}
