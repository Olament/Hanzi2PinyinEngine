//
//  SLMGraph.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/16/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import Foundation


class SLMGraph: Graph<SLMGraph.VertexData, Double> {
    class VertexData {
        var phrase: String?
        var pinyinSequence: PinyinSequence?
        var isCalculated = false
        var distanceSet: DistanceSet

        init(solutionSizeLimit limit: Int) {
            self.distanceSet = DistanceSet(limit: limit)
        }
    }

    class Distance {
        var distance = -Double.infinity
        var edge: Graph<VertexData, Double>.Edge
        
        init(distance: Double, edge: Graph<VertexData, Double>.Edge) {
            self.distance = distance
            self.edge = edge
        }
    }

    class DistanceSet {
        var sizeLimit: Int
        var distanceList: [Distance] = []
        
        init(limit: Int) {
            self.sizeLimit = limit
        }
        
        func add(newDistance distance: Distance) -> Bool {
            var isAdd = false
            for i in 0..<distanceList.count {
                if distance.distance > distanceList[i].distance {
                    distanceList.insert(distance, at: i)
                    isAdd = true
                    if distanceList.count > sizeLimit {
                        distanceList.remove(at: distanceList.count-1)
                    }
                    break
                }
            }
            
            if !isAdd {
                if distanceList.count == sizeLimit {
                    return false
                }
                distanceList.append(distance)
            }
            
            return true
        }
    }

    var solutionSizeLimit: Int
    
    init(lexiconGraph: LexiconGraph, model: LanguageModel, limit: Int) {
        self.solutionSizeLimit = limit
        super.init(numberOfVertices: lexiconGraph.edgeCount + 2)
        
        for vertex in self.vertices {
            vertex.data = VertexData(solutionSizeLimit: self.solutionSizeLimit)
        }
        
        /* making line graph of lexicon graph */
        
        // each vertex is an edge in lexicon graph
        for edge in lexiconGraph.edges {
            self.vertices[edge.data!.id].data?.phrase = edge.data?.phrase
            self.vertices[edge.data!.id].data?.pinyinSequence = edge.data?.pinyinSequence
        }
        
        for edge in lexiconGraph.vertices[0].to {
            _ = addEdge(from: 0, to: edge.data!.id, weight: model.getUnigram(phrase: edge.data!.phrase))
        }
        
        for edge in lexiconGraph.vertices[lexiconGraph.vertices.count - 1].from {
            _ = addEdge(from: edge.data!.id, to: self.vertexCount - 1, weight: 1.0)
        }
        
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
    }
    
    func addEdge(from: Int, to: Int, weight: Double) -> Graph<SLMGraph.VertexData, Double>.Edge {
        let edge = super.addEdge(from: self.vertices[from], to: self.vertices[to])
        edge.data = log2(weight)
        return edge
    }
}
