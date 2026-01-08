internal import SpriteKit

extension GameScene {
    
    func renderStation(_ station: Station) {
        let node = GraphicsManager.createStationShape(type: station.type, radius: stationRadius)
        node.position = station.position
        node.name = "station_\(station.id)"
        node.zPosition = 10
        node.fillColor = UIColor(named: "BackgroundColor") ?? .white
        addChild(node)
        
        // Fix: stationNodes is [UUID: SKShapeNode]
        stationNodes[station.id] = node
    }
    
    func updateStationVisuals(station: Station) {
        guard let node = stationNodes[station.id] else { return }
        
        // 1. Handle Overcrowding / Tension Pulse
        if station.isOvercrowded {
            if node.childNode(withName: "overcrowd_ring") == nil {
                // Outer glowing ring
                let ring = SKShapeNode(circleOfRadius: stationRadius + 8)
                ring.name = "overcrowd_ring"
                ring.strokeColor = .systemRed
                ring.lineWidth = 3
                ring.zPosition = -1
                node.addChild(ring)
                
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5)
                ])
                ring.run(SKAction.repeatForever(pulse))
                
                // Alert icon
                let alert = SKLabelNode(text: "!")
                alert.name = "overcrowd_alert"
                alert.fontName = "AvenirNext-Bold"
                alert.fontSize = 20
                alert.fontColor = .systemRed
                alert.position = CGPoint(x: 0, y: stationRadius + 15)
                node.addChild(alert)
                
                let bounce = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 5, duration: 0.3),
                    SKAction.moveBy(x: 0, y: -5, duration: 0.3)
                ])
                alert.run(SKAction.repeatForever(bounce))
            }
        } else {
            node.childNode(withName: "overcrowd_ring")?.removeFromParent()
            node.childNode(withName: "overcrowd_alert")?.removeFromParent()
            node.setScale(1.0)
            node.fillColor = UIColor(named: "BackgroundColor") ?? .white
        }
        
        // 2. Handle passenger dots/icons
        // Simple way: clear previous dot container or dots
        node.children.filter { $0.name == "passenger_container" }.forEach { $0.removeFromParent() }
        
        let container = SKNode()
        container.name = "passenger_container"
        node.addChild(container)
        
        let rowSize = 3
        let spacing: CGFloat = 8.0
        
        for (index, passenger) in station.passengers.enumerated() {
            let row = index / rowSize
            let col = index % rowSize
            
            let pNode = GraphicsManager.createStationShape(type: passenger.destinationType, radius: 4)
            pNode.fillColor = .darkGray
            pNode.strokeColor = .clear
            pNode.position = CGPoint(
                x: CGFloat(col - 1) * spacing,
                y: CGFloat(row) * spacing + 25
            )
            container.addChild(pNode)
        }
    }
    
    private struct TrainRenderContext {
        let train: Train
        let line: MetroLine
        let headDist: CGFloat
        let pathPoints: [CGPoint]
        let stationDistances: [CGFloat]
        let carriageWidth: CGFloat
        let spacing: CGFloat
        let offsetPerCarriage: CGFloat
    }

    func updateTrainVisuals() {
        let currentTrainIDs = Set(trains.map { $0.id })
        for (id, node) in trainNodes where !currentTrainIDs.contains(id) {
            node.removeFromParent()
            trainNodes.removeValue(forKey: id)
        }
        
        for train in trains {
            guard let line = metroLines.values.first(where: { $0.id == train.lineID }) else { continue }
            
            var node = trainNodes[train.id]
            if node == nil {
                node = SKNode() // Use generic SKNode as container
                node?.zPosition = 5
                addChild(node!)
                trainNodes[train.id] = node
            }
            
            node?.removeAllChildren()
            
            let pathPoints = getLinePathPoints(line: line)
            guard pathPoints.count >= 2 else { continue }
            
            // Calculate segment lengths and station distances for alpha animation
            var segmentLengths: [CGFloat] = []
            var stationDistances: [CGFloat] = [0]
            var currentTotal: CGFloat = 0
            for i in 0..<line.stations.count - 1 {
                guard let p1 = getStationPos(id: line.stations[i]),
                      let p2 = getStationPos(id: line.stations[i + 1]) else {
                    segmentLengths.append(0)
                    continue
                }
                let segPoints = getStructuredPathPoints(from: p1, to: p2)
                let d = calculateTotalDistance(points: segPoints)
                segmentLengths.append(d)
                currentTotal += d
                stationDistances.append(currentTotal)
            }
            
            // Distance of head from station 0
            var headDist: CGFloat = 0
            if !train.isReversed {
                for i in 0..<train.currentSegmentIndex where i < segmentLengths.count {
                    headDist += segmentLengths[i]
                }
                if train.currentSegmentIndex < segmentLengths.count {
                    headDist += train.progress * segmentLengths[train.currentSegmentIndex]
                }
            } else {
                let segmentIndex = train.currentSegmentIndex - 1
                if segmentIndex >= 0 {
                    for i in 0..<segmentIndex where i < segmentLengths.count {
                        headDist += segmentLengths[i]
                    }
                    if segmentIndex < segmentLengths.count {
                        headDist += (1.0 - train.progress) * segmentLengths[segmentIndex]
                    }
                }
            }
            
            let carriageWidth: CGFloat = 28
            let spacing: CGFloat = 4.0
            let offsetPerCarriage = carriageWidth + spacing
            
            let context = TrainRenderContext(
                train: train,
                line: line,
                headDist: headDist,
                pathPoints: pathPoints,
                stationDistances: stationDistances,
                carriageWidth: carriageWidth,
                spacing: spacing,
                offsetPerCarriage: offsetPerCarriage
            )
            
            let totalCarriages = 1 + train.carriages
            for i in 0..<totalCarriages {
                renderCarriage(index: i, context: context, node: node)
            }
            
            node?.alpha = 1.0
        }
    }

    private func renderCarriage(index: Int, context: TrainRenderContext, node: SKNode?) {
        let distOffset = CGFloat(index) * context.offsetPerCarriage
        // No waitOffset: Train stays at the stopping point
        let currentHeadDist = context.headDist
        // Fix: Always trail "behind" the head in terms of distance (towards 0).
        // This keeps carriages on the track even when reversing from the end of the line.
        let targetDist = currentHeadDist - distOffset
        
        guard let state = getPointAtDistance(points: context.pathPoints, distance: targetDist) else { return }
        
        // Connector (except for the first carriage)
        if index > 0 {
            let connectorOffset = distOffset - (context.carriageWidth / 2 + context.spacing / 2)
            let connectorDist = currentHeadDist - connectorOffset
            if let cState = getPointAtDistance(points: context.pathPoints, distance: connectorDist) {
                let connector = SKShapeNode(rectOf: CGSize(width: context.spacing + 2, height: 4), cornerRadius: 1)
                connector.fillColor = .darkGray
                connector.strokeColor = .clear
                connector.position = cState.point
                connector.zRotation = context.train.isReversed ? cState.angle + .pi : cState.angle
                connector.zPosition = -1
                
                // Smooth Fade for connector
                var cAlpha: CGFloat = 1.0
                for sDist in context.stationDistances {
                    let d = abs(connectorDist - sDist)
                    if d < 20 {
                        // Smooth cubic fade
                        let t = d / 20.0
                        cAlpha = min(cAlpha, t * t * (3 - 2 * t))
                    }
                }
                connector.alpha = cAlpha
                
                node?.addChild(connector)
            }
        }
        
        let cNode = GraphicsManager.createTrainShape(color: context.line.color)
        cNode.position = state.point
        cNode.zRotation = context.train.isReversed ? state.angle + .pi : state.angle
        
        // Professional Smooth Transition (Scale + Alpha)
        var carriageAlpha: CGFloat = 1.0
        var carriageScale: CGFloat = 1.0
        
        for sDist in context.stationDistances {
            let d = abs(targetDist - sDist)
            if d < 25 {
                // Extended range for smoother feel (25pt)
                // Normalize t from 0 (center) to 1 (edge)
                let t = max(0, min(1.0, d / 25.0))
                
                // Ease In Cubic for Alpha: Starts slow, speeds up
                // t=0 -> alpha=0, t=1 -> alpha=1
                let smoothT = t * t * (3 - 2 * t)
                carriageAlpha = min(carriageAlpha, 0.2 + 0.8 * smoothT) // Never fully invisible (0.2 min)
                
                // Scale Down slightly: 80% size at center
                carriageScale = min(carriageScale, 0.85 + 0.15 * smoothT)
            }
        }
        
        cNode.alpha = carriageAlpha
        cNode.setScale(carriageScale)
        
        node?.addChild(cNode)
        
        // Passengers indicators inside carriages (2x2 Grid)
        let capacityPerCarriage = 4 // As updated in Train.swift
        let startIdx = index * capacityPerCarriage
        let endIdx = min(startIdx + capacityPerCarriage, context.train.passengers.count)
        
        if startIdx < endIdx {
            let carriagePassengers = Array(context.train.passengers[startIdx..<endIdx])
            
            let colSpacing: CGFloat = 5.0 // Slightly increased to accommodate balanced sizes
            let rowSpacing: CGFloat = 5.0 
            
            // Center the grid
            let startX: CGFloat = -colSpacing / 2
            let startY: CGFloat = rowSpacing / 2
            
            for localIdx in 0..<carriagePassengers.count {
                let passenger = carriagePassengers[localIdx]
                
                // Fill columns from back (0) to front (1)
                let col = localIdx / 2
                let row = localIdx % 2
                
                let x = startX + CGFloat(col) * colSpacing
                let y = startY - CGFloat(row) * rowSpacing
                
                let pShape = GraphicsManager.createStationShape(type: passenger.destinationType, radius: 2.0, lineWidth: 1.0)
                pShape.position = CGPoint(x: x, y: y)
                
                // Orientation: Base faces the wall, Tip faces the aisle
                if passenger.destinationType == .triangle {
                    pShape.zRotation = (row == 0) ? .pi : 0
                }
                
                // Revert to original cleaner colors
                pShape.strokeColor = UIColor(white: 0.1, alpha: 1.0)
                pShape.fillColor = .white
                cNode.addChild(pShape)
            }
        }
    }

}
