//
//  SLMGraph.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation


class SLMGraph: Graph<SLMGraph.VertexData, Weight>, CustomStringConvertible {
    class VertexData {
        var phrase: String?
        var pinyinSequence: PinyinSequence?
    }

    var solutionSizeLimit: Int
    
    init(lexiconGraph: LexiconGraph, model: LanguageModel, limit: Int) {
        var time: [DispatchTime] = []
        
        self.solutionSizeLimit = limit
        time.append(DispatchTime.now())
        super.init(numberOfVertices: lexiconGraph.edgeCount + 2)
        time.append(DispatchTime.now())
        
        for vertex in self.vertices {
            vertex.data = VertexData()
        }
        time.append(DispatchTime.now())
        
        /* making line graph of lexicon graph */
        
        // each vertex is an edge in lexicon graph
        for edge in lexiconGraph.edges {
            self.vertices[edge.data!.id].data?.phrase = edge.data?.phrase
            self.vertices[edge.data!.id].data?.pinyinSequence = edge.data?.pinyinSequence
        }
        time.append(DispatchTime.now())
        
        for edge in lexiconGraph.vertices[0].to {
            _ = addEdge(from: 0, to: edge.data!.id, weight: model.getUnigram(phrase: edge.data!.phrase))
        }
        time.append(DispatchTime.now())
        
        for edge in lexiconGraph.vertices[lexiconGraph.vertices.count - 1].from {
            let weight = Weight(hash: 0)
            weight.probability = 1.0
            _ = addEdge(from: edge.data!.id, to: self.vertexCount - 1, weight: weight)
        }
        time.append(DispatchTime.now())
        
        self.vertices[0].data!.phrase = "(S)"
        self.vertices[vertexCount-1].data!.phrase = "(E)"
        
        // add edge to the L(lexicon graph)
        // two edge in lexicon graph (vertex in SLMGraph) is adjacent iff two edge incident to the same vertex in Lexicon graph
        for i in 0..<lexiconGraph.vertexCount {
            for preEdge in lexiconGraph.vertices[i].from {
                let preID = preEdge.data!.id
                let prePhrase = preEdge.data!.phrase
                
                for postEdge in lexiconGraph.vertices[i].to {
                    _ = addEdge(from: preID, to: postEdge.data!.id, weight: model.getBigram(phrase1: prePhrase, phrase2: postEdge.data!.phrase))
                }
            }
        }
        
        model.queryProbability()
        time.append(DispatchTime.now())
        
        let description = ["Init base graph", "Set solution limit", "add vertex to SLM", "add vertex to start", "add vertex to end", "add edge"]
        for i in 1..<time.count {
            let elapsed = Double(time[i].uptimeNanoseconds - time[i-1].uptimeNanoseconds) / 1_000_000
            print("  \(description[i-1]): \(elapsed)")
        }
    }
    
    func addEdge(from: Int, to: Int, weight: Weight) -> Graph<SLMGraph.VertexData, Weight>.Edge {
        let edge = super.addEdge(from: self.vertices[from], to: self.vertices[to])
        edge.data = weight
        return edge
    }
    
    
    /// find optimal sentence
    lazy var isVisited = Array(repeating: false, count: self.vertices.count)
    var stack: Stack<Int> = Stack()
    
    private func topologicalSort() {
        for index in 0..<self.vertices.count {
            if !isVisited[index] {
                depthFirstSearch(at: index)
            }
        }
    }
    
    private func depthFirstSearch(at index: Int) {
        isVisited[index] = true
        for edge in self.vertices[index].to {
            if !isVisited[edge.to.id] {
                depthFirstSearch(at: edge.to.id)
            }
        }
        stack.push(newElement: index)
    }
    
    lazy var edgeTo: [SLMGraph.Edge?] = Array(repeating: nil, count: self.vertices.count) // store the edge to access this vertex in shortest path
    lazy var distanceTo: [Double] = Array(repeating: Double.infinity, count: self.vertices.count) // shortest distance to vertex i
    
    func makeSentence() -> Solution {
        self.distanceTo[0] = 0 // set the starting vertex to zero
        
        topologicalSort()
        for index in self.stack {
            relax(index: index)
        }
        
        /* find the shortest path from 0 to self.vertices.count - 1 */
        var currentIndex = self.edgeTo[self.vertexCount - 1]!.from.id // skip the last vertex
        let solution: Solution = Solution()
        solution.probability = self.distanceTo[self.vertexCount - 1]
        
        while currentIndex != 0 {
            solution.pinyin = self.vertices[currentIndex].data!.pinyinSequence!.pinyinSequence + solution.pinyin
            solution.sentence = self.vertices[currentIndex].data!.phrase! + solution.sentence
            currentIndex = self.edgeTo[currentIndex]!.from.id
        }
        
        return solution
    }
    
    private func relax(index: Int) {
        for edge in self.vertices[index].to { // relax adjacent vetex
            let vertexIndex = edge.to.id
            let newDistance = self.distanceTo[index] - log(edge.data!.probability!) // new distance from source to edge.to.id
            
            if newDistance < self.distanceTo[vertexIndex] {
                self.distanceTo[vertexIndex] = newDistance
                self.edgeTo[vertexIndex] = edge
            }
        }
    }
    
    var description: String {
        var desc: String = ""
        for edge in self.edges {
            let from = edge.from
            let to = edge.to
            desc.append("\(from.id)(\"\(from.data!.phrase!)\") \(to.id)(\"\(to.data!.phrase!)\") \(edge.data!.probability!)\n")
        }
        return desc
    }
}
