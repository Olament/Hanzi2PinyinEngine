//
//  File.swift
//  
//
//  Created by Zixuan on 2/6/20.
//

import Foundation


class SyllableGraph: Graph<SyllableGraph.VertexData, String>, CustomStringConvertible {
    
    var description: String {
        var desc: String = ""
        for edge in edges {
            if edge.from.data!.shrinkID == -1 || edge.to.data!.shrinkID == -1 {
                continue
            }
            
            desc.append("\(edge.from.data!.shrinkID) \(edge.to.data!.shrinkID) \"\(edge.data!)\"\n")
        }
        
        return desc
    }
    
    class VertexData {
        var isForwardAccess: Bool = false
        var isBackwardAccess: Bool = false
        var shrinkID: Int = -1
    }
    
    var pinyinString: String
    var validSyllable: Set<String>
    
    init(pinyin: String, validSyllable: Set<String>) {
        self.pinyinString = pinyin
        self.validSyllable = validSyllable
        
        super.init(numberOfVertices: self.pinyinString.count+1)
        
        /* init vertices */
        for i in 0..<self.vertices.count { // pinyin.count + 1 vertices in total
            vertices[i].data = VertexData()
        }
        
        /* init edges */
        for i in 0..<pinyinString.count {
            for j in 1...6 where i + j <= pinyinString.count { // since longest possible pinyin syllable is 6
                let substring = self.pinyinString[i..<i+j]
                if validSyllable.contains(substring) {
                    let edge = addEdge(from: vertices[i], to: vertices[i+j])
                    edge.data = substring
                }
            }
        }
                
        shrinkGraph()
    }
    
    /*
     Shrink the graph such that only valid syllable remains in the graph
     */
    func shrinkGraph() {
        searchForward(start: vertices[0])
        if !vertices[vertices.count-1].data!.isForwardAccess {
            //TODO: error handling
        }
        
        searchBackward(start: self.vertices[self.vertexCount - 1])
        
        var validVerticesCount = 0 // number of vertices we will keep after "shrink"
        for vertex in vertices {
            // a vertex is valid iff it is connected to first vertex and reverse-connected to last vertex
            if vertex.data!.isForwardAccess && vertex.data!.isBackwardAccess {
                vertex.data!.shrinkID = validVerticesCount
                validVerticesCount += 1
            }
        }
        
        
        // init our new vertices
        var validVertices: [Vertex] = []
        for i in 0..<validVerticesCount {
            validVertices.append(Vertex(id: i))
            validVertices[i].data = VertexData()
            validVertices[i].data!.shrinkID = i
        }
        
        // transfer edge to the new vertices
        var newEdgeCount = 0
        for vertex in vertices {
            if vertex.data!.shrinkID > -1 {
                for edge in vertex.to {
                    if edge.to.data!.shrinkID > -1 {
                        let newEdge = addEdge(from: validVertices[vertex.data!.shrinkID], to: validVertices[edge.to.data!.shrinkID])
                        newEdge.data = edge.data
                        newEdgeCount += 1
                    }
                }
            }
        }
        
        self.vertices = validVertices
        self.edgeCount = newEdgeCount
    }
    
    /*
     mark every vertices "connected" to the start vertex
     Connected: there exist a walk from start vertex to vertex i
     */
    func searchForward(start vertex: Vertex) {
        vertex.data!.isForwardAccess = true
        for edge in vertex.to {
            if !edge.to.data!.isForwardAccess {
                searchForward(start: edge.to)
            }
        }
    }
    
    /*
     mark every vertices reverse-"connected" to the start vertex
     Reverse-connected: there exist a walk from vertex i to start vertex
     */
    func searchBackward(start vertex: Vertex) {
        vertex.data!.isBackwardAccess = true
        for edge in vertex.from {
            if !edge.from.data!.isBackwardAccess {
                searchBackward(start: edge.from)
            }
        }
    }
    
    var pinyin: [String] = []
    var pinyinSequences: [PinyinSequence] = []
    
    func getPinyinSequence(maxLength: Int) -> [PinyinSequence] {
        for i in 0..<self.vertices.count {
            pinyinSequenceSearch(v: vertices[i], from: i, limit: maxLength)
        }
        
        return self.pinyinSequences
    }
    
    private func pinyinSequenceSearch(v: Vertex, from: Int, limit: Int) {
        for edge in v.to {
            self.pinyin.append(edge.data!)
            self.pinyinSequences.append(PinyinSequence(sequences: pinyin, from: from, to: edge.to.data!.shrinkID))
            
            if (limit > 1) {
                pinyinSequenceSearch(v: edge.to, from: from, limit: limit - 1)
            }
            pinyin.remove(at: pinyin.count - 1)
        }
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
