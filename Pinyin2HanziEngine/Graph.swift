//
//  Graph.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/5/20.
//

import Foundation

class Graph<V, E> {
    /// define vertex and edge class graph used
    class Vertex {
        var from: [Edge] = []
        var to: [Edge] = []
        var data: V?
        var id: Int
        
        init(id: Int) {
            self.id = id
        }
    }
    
    class Edge {
        var from: Vertex
        var to: Vertex
        var data: E?
        
        init(from: Vertex, to: Vertex) {
            self.from = from
            self.to = to
        }
    }
    
    /// property of the graph
    var vertices: [Vertex] = []
    var edgeCount: Int = 0
    var vertexCount: Int {
        return vertices.count
    }
    
    init(numberOfVertices: Int) {
        for i in 0..<numberOfVertices {
            self.vertices.append(Vertex(id: i))
        }
    }
    
    init() {
        // do nothing
    }
    
    func addEdge(from: Vertex, to: Vertex) -> Edge {
        let edge = Edge(from: from, to: to)
        from.to.append(edge)
        to.from.append(edge)
        edgeCount += 1
        
        return edge
    }
}
