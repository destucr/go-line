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
        for station in gameStations {
            if hypot(station.position.x - location.x, station.position.y - location.y) < touchAreaRadius {
                return (station.id, station.position)
            }
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
        
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        if line == nil {
            line = MetroLine(id: UUID(), color: currentLineColor, stations: [start, end])
            metroLines[currentLineColor] = line
            spawnTrain(for: line!)
            createVisualLineSegment(from: start, to: end, color: currentLineColor)
        } else {
            var newLine = line!
            
            if newLine.stations.last == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.append(end)
                    metroLines[currentLineColor] = newLine
                    createVisualLineSegment(from: start, to: end, color: currentLineColor)
                }
            } else if newLine.stations.first == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.insert(end, at: 0)
                    metroLines[currentLineColor] = newLine
                    createVisualLineSegment(from: start, to: end, color: currentLineColor)
                }
            } else if newLine.stations.last == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.append(start)
                     metroLines[currentLineColor] = newLine
                     createVisualLineSegment(from: end, to: start, color: currentLineColor)
                 }
             } else if newLine.stations.first == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.insert(start, at: 0)
                     metroLines[currentLineColor] = newLine
                     createVisualLineSegment(from: end, to: start, color: currentLineColor)
                 }
             }
        }
    }
    
    func spawnTrain(for line: MetroLine) {
        let train = Train(id: UUID(), lineID: line.id)
        trains.append(train)
    }
    
    func createVisualLineSegment(from startID: UUID, to endID: UUID, color: UIColor) {
        guard let startNode = stationNodes[startID],
              let endNode = stationNodes[endID] else { return }
        
        let startPos = startNode.position
        let endPos = endNode.position
        
        let points = getStructuredPathPoints(from: startPos, to: endPos)
        let path = createRoundedPath(points: points, radius: 30) // Use smooth radius
        
        let lineSeg = SKShapeNode(path: path)
        lineSeg.strokeColor = color
        lineSeg.lineWidth = 5
        lineSeg.lineCap = .round
        
        let stitch = SKShapeNode(
            path: path.copy(dashingWithPhase: 0, lengths: [6, 4])
        )
        stitch.strokeColor = color.withAlphaComponent(0.5)
        stitch.lineWidth = 2
        lineSeg.addChild(stitch)
        
        lineSeg.zPosition = 1
        lineSeg.alpha = 0
        lineSeg.run(SKAction.fadeIn(withDuration: 0.3))
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        startNode.run(pulse)
        endNode.run(pulse)
        
        addChild(lineSeg)
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
                let p0 = points[i-1]
                let p1 = points[i]
                let p2 = points[i+1]
                
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
        for i in 0..<points.count-1 {
            total += hypot(points[i+1].x - points[i].x, points[i+1].y - points[i].y)
        }
        return total
    }
    
    func getPointOnPath(points: [CGPoint], progress: CGFloat) -> (point: CGPoint, angle: CGFloat) {
        let sampled = getSampledPointsFromPath(points: points)
        guard sampled.count >= 2 else { return (points.first ?? .zero, 0) }
        
        let roundedProgress = max(0, min(1, progress))
        let total = calculateTotalDistance(points: sampled)
        var targetDist = total * roundedProgress
        
        for i in 0..<sampled.count-1 {
            let p1 = sampled[i]
            let p2 = sampled[i+1]
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
}
