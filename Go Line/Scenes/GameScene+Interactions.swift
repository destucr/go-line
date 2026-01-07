internal import SpriteKit

extension GameScene {
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        guard !isGamePaused else { return }
        
        if let (stationID, stationPos) = getStationAt(location) {
            startDrawingLine(from: stationID, at: stationPos)
        } else {
            isPanning = true
            lastTouchPosition = touch.location(in: view)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first else { return }
        
        if let startID = startStationID, let startNode = stationNodes[startID] {
            let location = touch.location(in: self)
            updateDraftLine(from: startNode.position, to: location)
        } else if isPanning {
            let currentTouchPosition = touch.location(in: view)
            let dx = (currentTouchPosition.x - lastTouchPosition.x) * cameraNode.xScale
            let dy = (currentTouchPosition.y - lastTouchPosition.y) * cameraNode.yScale
            
            cameraNode.position = CGPoint(
                x: cameraNode.position.x - dx,
                y: cameraNode.position.y + dy
            )
            
            // Constrain camera to world bounds
            let w = worldSize.width
            let h = worldSize.height
            cameraNode.position.x = max(0, min(w, cameraNode.position.x))
            cameraNode.position.y = max(0, min(h, cameraNode.position.y))
            
            lastTouchPosition = currentTouchPosition
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        
        if isPanning {
            isPanning = false
            return
        }
        
        guard let touch = touches.first,
              let startID = startStationID else {
            resetDraft()
            return
        }
        
        let location = touch.location(in: self)
        if let (endID, _) = getStationAt(location), endID != startID {
            completeConnection(from: startID, to: endID)
        }
        
        resetDraft()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDraft()
        isPanning = false
    }
    
    // MARK: - Interaction Helpers
    func getStationAt(_ location: CGPoint) -> (UUID, CGPoint)? {
        for station in gameStations where hypot(station.position.x - location.x, station.position.y - location.y) < touchAreaRadius {
            return (station.id, station.position)
        }
        return nil
    }
    
    func getStationPos(id: UUID) -> CGPoint? {
        return gameStations.first(where: { $0.id == id })?.position
    }
    
    func startDrawingLine(from stationID: UUID, at position: CGPoint) {
        startStationID = stationID
        let draft = SKShapeNode()
        draft.strokeColor = currentLineColor.withAlphaComponent(0.5)
        draft.lineWidth = 4
        draft.lineCap = .round
        draft.zPosition = 5
        addChild(draft)
        currentDraftLine = draft
    }
    
    func updateDraftLine(from startPos: CGPoint, to currentPos: CGPoint) {
        guard let draft = currentDraftLine else { return }
        
        let points = getStructuredPathPoints(from: startPos, to: currentPos)
        let path = createRoundedPath(points: points, radius: 30) // Use smooth radius
        
        draft.path = path.copy(dashingWithPhase: 0, lengths: [6, 4])
    }
    
    func resetDraft() {
        currentDraftLine?.removeFromParent()
        currentDraftLine = nil
        startStationID = nil
    }
    
    func completeConnection(from start: UUID, to end: UUID) {
        var line = metroLines[currentLineColor]
        
        // Validate overlap
        if let existingLine = line {
             if isLineOverlapping(line: existingLine, newStartID: start, newEndID: end) {
                 SoundManager.shared.playSound("sfx_click_cancel")
                 return
             }
        }
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        if line == nil {
            line = MetroLine(id: UUID(), color: currentLineColor, stations: [start, end])
            metroLines[currentLineColor] = line
            spawnTrain(for: line!)
        } else {
            var newLine = line!
            
            if newLine.stations.last == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.append(end)
                    metroLines[currentLineColor] = newLine
                }
            } else if newLine.stations.first == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.insert(end, at: 0)
                    metroLines[currentLineColor] = newLine
                }
            } else if newLine.stations.last == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.append(start)
                     metroLines[currentLineColor] = newLine
                 }
             } else if newLine.stations.first == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.insert(start, at: 0)
                     metroLines[currentLineColor] = newLine
                 }
             }
        }
        
        redrawAllLines()
        
        // Visual feedback pulse
        if let startNode = stationNodes[start], let endNode = stationNodes[end] {
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            startNode.run(pulse)
            endNode.run(pulse)
        }
    }
    
    // MARK: - Overlap Validation
    
    func isLineOverlapping(line: MetroLine, newStartID: UUID, newEndID: UUID) -> Bool {
        // 1. Get new segment path
        let s1ID = newStartID.uuidString < newEndID.uuidString ? newStartID : newEndID
        let s2ID = newStartID.uuidString < newEndID.uuidString ? newEndID : newStartID
        
        guard let p1 = getStationPos(id: s1ID),
              let p2 = getStationPos(id: s2ID) else { return false }
              
        let newPathPoints = getStructuredPathPoints(from: p1, to: p2)
        
        // 2. Compare against all existing segments
        for i in 0..<line.stations.count - 1 {
            let es1 = line.stations[i]
            let es2 = line.stations[i + 1]
            
            // Normalize existing segment
            let eStartID = es1.uuidString < es2.uuidString ? es1 : es2
            let eEndID = es1.uuidString < es2.uuidString ? es2 : es1
            
            // Skip if this is the same connection (shouldn't happen due to logic, but safe)
            if eStartID == s1ID && eEndID == s2ID { continue }
            
            guard let ep1 = getStationPos(id: eStartID),
                  let ep2 = getStationPos(id: eEndID) else { continue }
                  
            let existingPathPoints = getStructuredPathPoints(from: ep1, to: ep2)
            
            // Check intersection between any segment of newPath and existingPath
            if pathsIntersect(path1: newPathPoints, path2: existingPathPoints) {
                return true
            }
        }
        return false
    }
    
    func pathsIntersect(path1: [CGPoint], path2: [CGPoint]) -> Bool {
        guard path1.count >= 2, path2.count >= 2 else { return false }
        
        for i in 0..<path1.count - 1 {
            let u1 = path1[i]
            let u2 = path1[i + 1]
            
            for j in 0..<path2.count - 1 {
                let v1 = path2[j]
                let v2 = path2[j + 1]
                
                if segmentsIntersect(p1: u1, p2: u2, p3: v1, p4: v2) {
                    return true
                }
            }
        }
        return false
    }
    
    func segmentsIntersect(p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> Bool {
        let epsilon: CGFloat = 1.0
        
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            return hypot(a.x - b.x, a.y - b.y)
        }
        
        func onSegment(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Bool {
            return q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) &&
                   q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y)
        }
        
        func orientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Int {
            let val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
            if abs(val) < 0.1 { return 0 }
            return (val > 0) ? 1 : 2
        }
        
        // Check if they share any endpoints
        let shareEndpoint = distance(p1, p3) < epsilon || distance(p1, p4) < epsilon ||
                            distance(p2, p3) < epsilon || distance(p2, p4) < epsilon
        
        let o1 = orientation(p1, p2, p3)
        let o2 = orientation(p1, p2, p4)
        let o3 = orientation(p3, p4, p1)
        let o4 = orientation(p3, p4, p2)
        
        if shareEndpoint {
            // If they share an endpoint, they intersect only if they overlap (collinear)
            // excluding the shared point itself.
            // Check if the non-shared point of one segment lies on the other segment.
            
            if o1 == 0 && onSegment(p1, p3, p2) && distance(p3, p1) > epsilon && distance(p3, p2) > epsilon { return true }
            if o2 == 0 && onSegment(p1, p4, p2) && distance(p4, p1) > epsilon && distance(p4, p2) > epsilon { return true }
            if o3 == 0 && onSegment(p3, p1, p4) && distance(p1, p3) > epsilon && distance(p1, p4) > epsilon { return true }
            if o4 == 0 && onSegment(p3, p2, p4) && distance(p2, p3) > epsilon && distance(p2, p4) > epsilon { return true }
            
            return false
        }
        
        // General intersection
        if o1 != o2 && o3 != o4 {
            return true
        }
        
        // Collinear but not sharing endpoints (overlapping)
        if o1 == 0 && onSegment(p1, p3, p2) { return true }
        if o2 == 0 && onSegment(p1, p4, p2) { return true }
        if o3 == 0 && onSegment(p3, p1, p4) { return true }
        if o4 == 0 && onSegment(p3, p2, p4) { return true }
        
        return false
    }
    
    func spawnTrain(for line: MetroLine) {
        let train = Train(id: UUID(), lineID: line.id)
        trains.append(train)
    }
    
    func redrawAllLines() {
        // Clear existing lines
        lineNodes.forEach { $0.removeFromParent() }
        lineNodes.removeAll()
        
        // 1. Map all unique segments across all lines
        // Key: Sorted tuple of Station IDs (A, B) -> List of Colors sharing it
        var sharedSegments: [Set<UUID>: [UIColor]] = [:]
        
        let allLines = Array(metroLines.values).sorted { $0.id.uuidString < $1.id.uuidString }
        
        for line in allLines {
            for i in 0..<line.stations.count - 1 {
                let s1 = line.stations[i]
                let s2 = line.stations[i + 1]
                let segmentKey: Set<UUID> = [s1, s2]
                
                if sharedSegments[segmentKey] == nil {
                    sharedSegments[segmentKey] = []
                }
                sharedSegments[segmentKey]?.append(line.color)
            }
        }
        
        // 2. Render each segment with its specific offset
        let lineSpacing: CGFloat = 6.0
        
        for (segmentSet, colors) in sharedSegments {
            let stations = Array(segmentSet)
            guard stations.count == 2 else { continue }
            
            // To maintain consistent orientation, always go from ID < to ID >
            let s1ID = stations[0].uuidString < stations[1].uuidString ? stations[0] : stations[1]
            let s2ID = stations[0].uuidString < stations[1].uuidString ? stations[1] : stations[0]
            
            guard let p1 = getStationPos(id: s1ID),
                  let p2 = getStationPos(id: s2ID) else { continue }
            
            let totalLines = CGFloat(colors.count)
            
            for (index, color) in colors.enumerated() {
                // Calculate offset: center the lines
                // e.g. for 2 lines: -3, +3
                // e.g. for 1 line: 0
                let offset = (CGFloat(index) - (totalLines - 1) / 2.0) * lineSpacing
                
                // Get structured path points
                let rawPoints = getStructuredPathPoints(from: p1, to: p2)
                
                // Apply offset to each point perpendicular to segment direction
                let offsetPoints = applyOffsetToPath(points: rawPoints, offset: offset)
                
                let path = createRoundedPath(points: offsetPoints, radius: 30)
                
                let lineSeg = SKShapeNode(path: path)
                lineSeg.strokeColor = color
                lineSeg.lineWidth = 5
                lineSeg.lineCap = .round
                lineSeg.zPosition = 1
                
                let stitch = SKShapeNode(path: path.copy(dashingWithPhase: 0, lengths: [6, 4]))
                stitch.strokeColor = color.withAlphaComponent(0.5)
                stitch.lineWidth = 2
                lineSeg.addChild(stitch)
                
                addChild(lineSeg)
                lineNodes.append(lineSeg)
            }
        }
    }
    
    func applyOffsetToPath(points: [CGPoint], offset: CGFloat) -> [CGPoint] {
        guard offset != 0, points.count >= 2 else { return points }
        var result: [CGPoint] = []
        
        for i in 0..<points.count {
            let p = points[i]
            let prev = i > 0 ? points[i - 1] : nil
            let next = i < points.count - 1 ? points[i + 1] : nil
            
            var normal: CGPoint = .zero
            
            if let next = next, let prev = prev {
                // Average normal at a corner
                let d1 = normalize(CGPoint(x: p.x - prev.x, y: p.y - prev.y))
                let d2 = normalize(CGPoint(x: next.x - p.x, y: next.y - p.y))
                let combined = normalize(CGPoint(x: d1.x + d2.x, y: d1.y + d2.y))
                normal = CGPoint(x: -combined.y, y: combined.x)
            } else if let next = next {
                // Start point normal
                let d = normalize(CGPoint(x: next.x - p.x, y: next.y - p.y))
                normal = CGPoint(x: -d.y, y: d.x)
            } else if let prev = prev {
                // End point normal
                let d = normalize(CGPoint(x: p.x - prev.x, y: p.y - prev.y))
                normal = CGPoint(x: -d.y, y: d.x)
            }
            
            result.append(CGPoint(x: p.x + normal.x * offset, y: p.y + normal.y * offset))
        }
        
        return result
    }
    
    private func normalize(_ point: CGPoint) -> CGPoint {
        let len = sqrt(point.x * point.x + point.y * point.y)
        return len > 0 ? CGPoint(x: point.x / len, y: point.y / len) : .zero
    }
    
    func createVisualLineSegment(from startID: UUID, to endID: UUID, color: UIColor) {
        // Redundant now, kept for signature compatibility if needed elsewhere
        redrawAllLines()
    }
    
    // MARK: - Geometry
    func getStructuredPathPoints(from: CGPoint, to: CGPoint) -> [CGPoint] {
        // Metro Style: Symmetric Octolinear with Hysteresis
        
        let dx = to.x - from.x
        let dy = to.y - from.y
        let adx = abs(dx)
        let ady = abs(dy)
        
        // Direct if close or straight
        if adx < 5 || ady < 5 || abs(adx - ady) < 5 {
            return [from, to]
        }
        
        // Hysteresis buffer (prevents rapid flipping)
        let buffer: CGFloat = 20.0
        var isHorizontalDominant = adx > ady
        
        if abs(adx - ady) < buffer {
            // Keep previous state if within buffer zone
            isHorizontalDominant = lastDominantAxisWasHorizontal
        } else {
            // Update state
            lastDominantAxisWasHorizontal = isHorizontalDominant
        }
        
        var c1: CGPoint
        var c2: CGPoint
        
        if isHorizontalDominant {
            // H -> D -> H
            let excess = adx - ady
            let split = excess / 2.0
            let signX = dx > 0 ? 1.0 : -1.0
            
            c1 = CGPoint(x: from.x + split * signX, y: from.y)
            c2 = CGPoint(x: to.x - split * signX, y: to.y)
        } else {
            // V -> D -> V
            let excess = ady - adx
            let split = excess / 2.0
            let signY = dy > 0 ? 1.0 : -1.0
            
            c1 = CGPoint(x: from.x, y: from.y + split * signY)
            c2 = CGPoint(x: to.x, y: to.y - split * signY)
        }
        
        return [from, c1, c2, to]
    }
    
    func createRoundedPath(points: [CGPoint], radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        guard points.count >= 2 else { return path }
        
        let maxRadius: CGFloat = 45.0
        
        path.move(to: points[0])
        
        if points.count == 2 {
            path.addLine(to: points[1])
        } else {
            for i in 1..<points.count - 1 {
                let p0 = points[i - 1]
                let p1 = points[i]
                let p2 = points[i + 1]
                
                // Calculate distances to clamp radius
                let d1 = hypot(p1.x - p0.x, p1.y - p0.y)
                let d2 = hypot(p2.x - p1.x, p2.y - p1.y)
                
                // Use the smaller of the two segment halves, capped at maxRadius
                let effectiveRadius = min(maxRadius, min(d1, d2) / 2.0)
                
                path.addArc(tangent1End: p1, tangent2End: p2, radius: effectiveRadius)
            }
            path.addLine(to: points[points.count - 1])
        }
        
        return path
    }
    
    func calculateTotalDistance(points: [CGPoint]) -> CGFloat {
        var total: CGFloat = 0
        for i in 0..<points.count - 1 {
            total += hypot(points[i + 1].x - points[i].x, points[i + 1].y - points[i].y)
        }
        return total
    }
    
    func getPointOnPath(points: [CGPoint], progress: CGFloat) -> (point: CGPoint, angle: CGFloat) {
        let sampled = getSampledPointsFromPath(points: points)
        guard sampled.count >= 2 else { return (points.first ?? .zero, 0) }
        
        let roundedProgress = max(0, min(1, progress))
        let total = calculateTotalDistance(points: sampled)
        var targetDist = total * roundedProgress
        
        for i in 0..<sampled.count - 1 {
            let p1 = sampled[i]
            let p2 = sampled[i + 1]
            let segDist = hypot(p2.x - p1.x, p2.y - p1.y)
            
            if targetDist <= segDist {
                let t = segDist > 0 ? targetDist / segDist : 0
                let x = p1.x + (p2.x - p1.x) * t
                let y = p1.y + (p2.y - p1.y) * t
                let angle = atan2(p2.y - p1.y, p2.x - p1.x)
                return (CGPoint(x: x, y: y), angle)
            }
            targetDist -= segDist
        }
        
        return (sampled.last ?? .zero, 0)
    }
    
    func getSampledPointsFromPath(points: [CGPoint]) -> [CGPoint] {
        let path = createRoundedPath(points: points, radius: 30.0)
        var sampledPoints: [CGPoint] = []
        
        path.applyWithBlock { element in
            let ptr = element.pointee.points
            switch element.pointee.type {
            case .moveToPoint:
                sampledPoints.append(ptr[0])
            case .addLineToPoint:
                sampledPoints.append(ptr[0])
            case .addQuadCurveToPoint:
                let start = sampledPoints.last ?? .zero
                let p1 = ptr[0]
                let p2 = ptr[1]
                for t in stride(from: 0.1, through: 1.0, by: 0.1) {
                    let t2 = t * t
                    let oneMinusT = 1.0 - t
                    let oneMinusT2 = oneMinusT * oneMinusT
                    
                    let x = (oneMinusT2 * start.x) + (2 * oneMinusT * t * p1.x) + (t2 * p2.x)
                    let y = (oneMinusT2 * start.y) + (2 * oneMinusT * t * p1.y) + (t2 * p2.y)
                    sampledPoints.append(CGPoint(x: x, y: y))
                }
            case .addCurveToPoint:
                let start = sampledPoints.last ?? .zero
                let p1 = ptr[0]
                let p2 = ptr[1]
                let p3 = ptr[2]
                for t in stride(from: 0.1, through: 1.0, by: 0.1) {
                    let t2 = t * t
                    let t3 = t2 * t
                    let oneMinusT = 1.0 - t
                    let oneMinusT2 = oneMinusT * oneMinusT
                    let oneMinusT3 = oneMinusT2 * oneMinusT
                    
                    let term1X = oneMinusT3 * start.x
                    let term2X = 3 * oneMinusT2 * t * p1.x
                    let term3X = 3 * oneMinusT * t2 * p2.x
                    let term4X = t3 * p3.x
                    
                    let term1Y = oneMinusT3 * start.y
                    let term2Y = 3 * oneMinusT2 * t * p1.y
                    let term3Y = 3 * oneMinusT * t2 * p2.y
                    let term4Y = t3 * p3.y
                    
                    let x = term1X + term2X + term3X + term4X
                    let y = term1Y + term2Y + term3Y + term4Y
                    sampledPoints.append(CGPoint(x: x, y: y))
                }
            default: break
            }
        }
        return sampledPoints
    }
    
    func getLinePathPoints(line: MetroLine) -> [CGPoint] {
        var allPoints: [CGPoint] = []
        let stationIDs = line.stations
        guard stationIDs.count >= 2 else { return [] }
        
        for i in 0..<stationIDs.count - 1 {
            guard let p1 = getStationPos(id: stationIDs[i]),
                  let p2 = getStationPos(id: stationIDs[i + 1]) else { continue }
            
            let segmentPoints = getStructuredPathPoints(from: p1, to: p2)
            let sampled = getSampledPointsFromPath(points: segmentPoints)
            
            if i == 0 {
                allPoints.append(contentsOf: sampled)
            } else {
                allPoints.append(contentsOf: sampled.dropFirst())
            }
        }
        return allPoints
    }
    
    func getPointAtDistance(points: [CGPoint], distance: CGFloat) -> (point: CGPoint, angle: CGFloat)? {
        guard points.count >= 2 else { return nil }
        
        var remainingDist = distance
        if distance <= 0 {
            let p1 = points[0]
            let p2 = points[1]
            let angle = atan2(p2.y - p1.y, p2.x - p1.x)
            return (p1, angle)
        }
        
        for i in 0..<points.count - 1 {
            let p1 = points[i]
            let p2 = points[i + 1]
            let d = hypot(p2.x - p1.x, p2.y - p1.y)
            
            if remainingDist <= d {
                let t = d > 0 ? remainingDist / d : 0
                let x = p1.x + (p2.x - p1.x) * t
                let y = p1.y + (p2.y - p1.y) * t
                let angle = atan2(p2.y - p1.y, p2.x - p1.x)
                return (CGPoint(x: x, y: y), angle)
            }
            remainingDist -= d
        }
        
        let last = points[points.count - 1]
        let prev = points[points.count - 2]
        let angle = atan2(last.y - prev.y, last.x - prev.x)
        return (last, angle)
    }
}
