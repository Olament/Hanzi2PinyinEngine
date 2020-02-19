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
        var edge: Graph<VertexData, Double>.Edge?
        
        init(distance: Double, edge: Graph<VertexData, Double>.Edge) {
            self.distance = distance
            self.edge = edge
        }
        
        init(distance: Double) {
            self.distance = distance
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
    
    func calculatedPath(vertex current: SLMGraph.Vertex) {
        current.data!.isCalculated = true // mark itself as visited
        
        for edge in current.from {
            let prev = edge.from
            if !prev.data!.isCalculated {
                calculatedPath(vertex: prev)
            }
            
            for prevDistance in (prev.data?.distanceSet.distanceList)! {
                if !current.data!.distanceSet.add(newDistance: Distance(distance: prevDistance.distance, edge: edge)) {
                    break // do not ask me why
                }
            }
        }
    }
    
    private var phraseSequence: [SLMGraph.VertexData]  = []
    private var sentences: [Solution] = []
    
    private func makeSentence(currentVertex: SLMGraph.Vertex, probability: Double) {
        phraseSequence.insert(currentVertex.data!, at: 0)
        
        for distance in currentVertex.data!.distanceSet.distanceList {
            if let prevEdge = distance.edge {
                // since we log transform each weight
                // w1*w2*w3 -> log(w1*w2*w3) = log(w1) + log(w2) + log(w3)
                makeSentence(currentVertex: prevEdge.from, probability: probability + prevEdge.data!)
            } else {
                var sentence: String = ""
                var pinyins: [String] = []
                
                for vertexData in phraseSequence {
                    if let phrase = vertexData.phrase, let pinyinSequence = vertexData.pinyinSequence {
                        sentence.append(phrase)
                        for sequence in pinyinSequence.pinyinSequence {
                            pinyins.append(sequence)
                        }
                    }
                }
                
                let newSolution = Solution() //TODO: rewrite this part
                newSolution.sentence = sentence
                newSolution.probability = probability
                newSolution.pinyin = pinyins
                
                sentences.append(newSolution)
            }
        }
        
        phraseSequence.remove(at: 0)
    }
    
    func makeSentence() -> [Solution] {
        /* set vertex (S) such that search terminate here */
        self.vertices[0].data?.isCalculated = true
        _ = self.vertices[0].data?.distanceSet.add(newDistance: Distance(distance: 0.0))
        
        calculatedPath(vertex: self.vertices[self.vertexCount - 1])
        makeSentence(currentVertex: self.vertices[self.vertexCount - 1], probability: 0.0)
        
        sentences.sort(by: {$0 < $1})
        var finalSentences: [Solution] = [] // sentences w/o duplicate
        
        /* removing duplicate solution from solution set */
        for i in 0..<sentences.count {
            var isDuplicate = false
            for sentence in finalSentences {
                if sentence == sentences[i] {
                    isDuplicate = true
                    break
                }
            }
            
            if !isDuplicate {
                print("\(sentences[i].sentence) \(sentences[i].probability)")
                finalSentences.append(sentences[i])
                
                if finalSentences.count > solutionSizeLimit {
                    break
                }
            }
        }
        
        return finalSentences
    }
}
