import Foundation
import CoreGraphics

struct GridPoint: Hashable, Equatable, CustomStringConvertible {
    let x: Int
    let y: Int
    
    var description: String {
        return "(\(x), \(y))"
    }
}

class Pathfinder {
    
    static func findPath(start: CGPoint, end: CGPoint, gridWidth: Int, gridHeight: Int, obstacles: [LayoutElement]) -> [CGPoint] {
        
        let startNode = GridPoint(x: Int(start.x), y: Int(start.y))
        let targetNode = GridPoint(x: Int(end.x), y: Int(end.y))
        
        // 1. Hindernis-Map erstellen
        var blockedCells: Set<GridPoint> = []
        
        for element in obstacles {
            if element.type == "beacon" || element.type == "entrance" { continue }
            
            let ex = Int(element.x)
            let ey = Int(element.y)
            let ew = Int(element.width ?? 1)
            let eh = Int(element.height ?? 1)
            
            for x in ex..<(ex + ew) {
                for y in ey..<(ey + eh) {
                    blockedCells.insert(GridPoint(x: x, y: y))
                }
            }
        }
        
        // 2. Ziel-Validierung
        var effectiveTarget = targetNode
        
        // Wenn das Ziel im Regal liegt, suchen wir den nächsten freien Gang
        if blockedCells.contains(targetNode) {
            if let nearestWalkable = findNearestWalkable(from: targetNode, blocked: blockedCells, w: gridWidth, h: gridHeight) {
                effectiveTarget = nearestWalkable
            } else {
                return []
            }
        }
        
        // 3. A* Algorithmus (Erweitert)
        var openSet: Set<GridPoint> = [startNode]
        var cameFrom: [GridPoint: GridPoint] = [:]
        
        var gScore: [GridPoint: Double] = [:]
        gScore[startNode] = 0
        
        var fScore: [GridPoint: Double] = [:]
        fScore[startNode] = heuristic(from: startNode, to: effectiveTarget)
        
        while !openSet.isEmpty {
            guard let current = openSet.min(by: { (fScore[$0] ?? Double.infinity) < (fScore[$1] ?? Double.infinity) }) else {
                break
            }
            
            if current == effectiveTarget {
                var path = reconstructPath(cameFrom: cameFrom, current: current)
                // Visuelle Verbindung zum echten Zielpunkt
                if effectiveTarget != targetNode {
                    path.append(end)
                }
                return path
            }
            
            openSet.remove(current)
            
            // NEU: 8 Richtungen (inkl. Diagonal) mit realistischen Kosten
            let neighbors: [(point: GridPoint, cost: Double, isDiagonal: Bool)] = [
                (GridPoint(x: current.x + 1, y: current.y), 1.0, false), // Rechts
                (GridPoint(x: current.x - 1, y: current.y), 1.0, false), // Links
                (GridPoint(x: current.x, y: current.y + 1), 1.0, false), // Unten
                (GridPoint(x: current.x, y: current.y - 1), 1.0, false), // Oben
                // Diagonalen (Kosten = Wurzel aus 2 = ca. 1.414)
                (GridPoint(x: current.x + 1, y: current.y + 1), 1.414, true),
                (GridPoint(x: current.x - 1, y: current.y - 1), 1.414, true),
                (GridPoint(x: current.x + 1, y: current.y - 1), 1.414, true),
                (GridPoint(x: current.x - 1, y: current.y + 1), 1.414, true)
            ]
            
            for neighborData in neighbors {
                let neighbor = neighborData.point
                let stepCost = neighborData.cost
                
                // Im Grid?
                if neighbor.x < 0 || neighbor.x >= gridWidth || neighbor.y < 0 || neighbor.y >= gridHeight { continue }
                // Hindernis?
                if blockedCells.contains(neighbor) { continue }
                
                // VERHINDERE ECKEN-SCHNEIDEN:
                // Wenn wir uns diagonal bewegen, dürfen die beiden direkt angrenzenden Felder nicht blockiert sein
                if neighborData.isDiagonal {
                    let check1 = GridPoint(x: current.x, y: neighbor.y)
                    let check2 = GridPoint(x: neighbor.x, y: current.y)
                    if blockedCells.contains(check1) || blockedCells.contains(check2) {
                        continue // Die "Tür" ist zu schmal, nicht diagonal durch die Wand schneiden!
                    }
                }
                
                // NEU: STRAFE FÜR ZICK-ZACK (Turn Penalty)
                // Dies zwingt die Linie dazu, lange gerade Strecken ("10 rüber") zu bevorzugen.
                var turnPenalty = 0.0
                if let parent = cameFrom[current] {
                    let dx1 = current.x - parent.x
                    let dy1 = current.y - parent.y
                    let dx2 = neighbor.x - current.x
                    let dy2 = neighbor.y - current.y
                    
                    // Wenn wir nicht in exakt dieselbe Richtung weitergehen, gibt es eine fette Strafe
                    if dx1 != dx2 || dy1 != dy2 {
                        turnPenalty = 1.5 // Abbiegen ist "teurer" als ein normaler Schritt
                    }
                }
                
                let tentativeGScore = (gScore[current] ?? Double.infinity) + stepCost + turnPenalty
                
                if tentativeGScore < (gScore[neighbor] ?? Double.infinity) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(from: neighbor, to: effectiveTarget)
                    openSet.insert(neighbor)
                }
            }
        }
        
        return []
    }
    
    // NEU: Euklidische Distanz (Luftlinie) statt Manhattan-Distanz für natürlicheres Verhalten
    private static func heuristic(from: GridPoint, to: GridPoint) -> Double {
        let dx = Double(from.x - to.x)
        let dy = Double(from.y - to.y)
        return sqrt(dx * dx + dy * dy)
    }
    
    private static func findNearestWalkable(from start: GridPoint, blocked: Set<GridPoint>, w: Int, h: Int) -> GridPoint? {
        var queue = [start]
        var visited = Set([start])
        
        var loops = 0
        while !queue.isEmpty && loops < 500 {
            loops += 1
            let current = queue.removeFirst()
            
            if !blocked.contains(current) {
                return current
            }
            
            let neighbors = [
                GridPoint(x: current.x + 1, y: current.y),
                GridPoint(x: current.x - 1, y: current.y),
                GridPoint(x: current.x, y: current.y + 1),
                GridPoint(x: current.x, y: current.y - 1)
            ]
            
            for n in neighbors {
                if n.x >= 0 && n.x < w && n.y >= 0 && n.y < h && !visited.contains(n) {
                    visited.insert(n)
                    queue.append(n)
                }
            }
        }
        return nil
    }
    
    private static func reconstructPath(cameFrom: [GridPoint: GridPoint], current: GridPoint) -> [CGPoint] {
        var path = [CGPoint(x: Double(current.x) + 0.5, y: Double(current.y) + 0.5)]
        var curr = current
        
        while let prev = cameFrom[curr] {
            curr = prev
            path.append(CGPoint(x: Double(curr.x) + 0.5, y: Double(curr.y) + 0.5))
        }
        
        return path.reversed()
    }
}
