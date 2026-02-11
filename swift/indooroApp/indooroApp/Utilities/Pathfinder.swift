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
        
        // 2. Ziel-Validierung (Der Fix!)
        var effectiveTarget = targetNode
        
        // Wenn das Ziel im Regal liegt, suchen wir den nächsten freien Punkt (BFS Suche)
        if blockedCells.contains(targetNode) {
            print("⚠️ Ziel \(targetNode) liegt im Regal. Suche nächsten freien Gang...")
            if let nearestWalkable = findNearestWalkable(from: targetNode, blocked: blockedCells, w: gridWidth, h: gridHeight) {
                print("✅ Ausweichziel gefunden: \(nearestWalkable)")
                effectiveTarget = nearestWalkable
            } else {
                print("❌ Kein freier Punkt in der Nähe gefunden!")
                return []
            }
        }
        
        // 3. A* Algorithmus (Start -> EffectiveTarget)
        var openSet: Set<GridPoint> = [startNode]
        var cameFrom: [GridPoint: GridPoint] = [:]
        
        var gScore: [GridPoint: Double] = [:]
        gScore[startNode] = 0
        
        var fScore: [GridPoint: Double] = [:]
        fScore[startNode] = heuristic(from: startNode, to: effectiveTarget)
        
        while !openSet.isEmpty {
            // Knoten mit niedrigstem fScore finden
            guard let current = openSet.min(by: { (fScore[$0] ?? Double.infinity) < (fScore[$1] ?? Double.infinity) }) else {
                break
            }
            
            if current == effectiveTarget {
                // Pfad rekonstruieren
                var path = reconstructPath(cameFrom: cameFrom, current: current)
                
                // OPTISCHER TRICK:
                // Wenn wir zu einem Ausweichpunkt gelaufen sind, ziehen wir am Ende
                // noch eine gerade Linie zum echten Ziel (mitten ins Regal),
                // damit es visuell verbunden aussieht.
                if effectiveTarget != targetNode {
                    path.append(end)
                }
                
                return path
            }
            
            openSet.remove(current)
            
            let neighbors = [
                GridPoint(x: current.x + 1, y: current.y),
                GridPoint(x: current.x - 1, y: current.y),
                GridPoint(x: current.x, y: current.y + 1),
                GridPoint(x: current.x, y: current.y - 1)
            ]
            
            for neighbor in neighbors {
                if neighbor.x < 0 || neighbor.x >= gridWidth || neighbor.y < 0 || neighbor.y >= gridHeight { continue }
                if blockedCells.contains(neighbor) { continue }
                
                let tentativeGScore = (gScore[current] ?? Double.infinity) + 1.0
                
                if tentativeGScore < (gScore[neighbor] ?? Double.infinity) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(from: neighbor, to: effectiveTarget)
                    openSet.insert(neighbor)
                }
            }
        }
        
        print("❌ A* hat keinen Weg gefunden.")
        return []
    }
    
    // Hilfsfunktion: Sucht spiralförmig nach außen nach dem nächsten freien Punkt
    private static func findNearestWalkable(from start: GridPoint, blocked: Set<GridPoint>, w: Int, h: Int) -> GridPoint? {
        var queue = [start]
        var visited = Set([start])
        
        // Wir suchen maximal 10 Schritte weit, um Performance zu sparen
        var loops = 0
        
        while !queue.isEmpty && loops < 200 {
            loops += 1
            let current = queue.removeFirst()
            
            // Wenn dieser Punkt NICHT blockiert ist -> Gefunden!
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
    
    private static func heuristic(from: GridPoint, to: GridPoint) -> Double {
        return Double(abs(from.x - to.x) + abs(from.y - to.y))
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
