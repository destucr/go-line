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
                alert.fontName = "ChalkboardSE-Bold"
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
    
    func updateTrainVisuals() {
        let currentTrainIDs = Set(trains.map { $0.id })
        for (id, node) in trainNodes {
            if !currentTrainIDs.contains(id) {
                node.removeFromParent()
                trainNodes.removeValue(forKey: id)
            }
        }
        
        for train in trains {
            guard let line = metroLines.values.first(where: { $0.id == train.lineID }) else { continue }
            
            var node = trainNodes[train.id]
            if node == nil {
                node = SKNode() // Use generic SKNode as container
                node?.zPosition = 20
                addChild(node!)
                trainNodes[train.id] = node
            }
            
            node?.removeAllChildren()
            
            let pathPoints = getLinePathPoints(line: line)
            guard pathPoints.count >= 2 else { continue }
            
            // Calculate segment lengths for total distance mapping
            var segmentLengths: [CGFloat] = []
            for i in 0..<line.stations.count - 1 {
                guard let p1 = getStationPos(id: line.stations[i]),
                      let p2 = getStationPos(id: line.stations[i+1]) else {
                    segmentLengths.append(0)
                    continue
                }
                let segPoints = getStructuredPathPoints(from: p1, to: p2)
                segmentLengths.append(calculateTotalDistance(points: segPoints))
            }
            
            // Distance of head from station 0
            var headDist: CGFloat = 0
            if !train.isReversed {
                for i in 0..<train.currentSegmentIndex { headDist += segmentLengths[i] }
                headDist += train.progress * segmentLengths[train.currentSegmentIndex]
            } else {
                for i in 0..<train.currentSegmentIndex - 1 { headDist += segmentLengths[i] }
                headDist += (1.0 - train.progress) * segmentLengths[train.currentSegmentIndex - 1]
            }
            
            let carriageWidth: CGFloat = 28
            let spacing: CGFloat = 4.0
            let offsetPerCarriage = carriageWidth + spacing
            
            let totalCarriages = 1 + train.carriages
            
            for i in 0..<totalCarriages {
                let distOffset = CGFloat(i) * offsetPerCarriage
                let targetDist = train.isReversed ? (headDist + distOffset) : (headDist - distOffset)
                
                guard let state = getPointAtDistance(points: pathPoints, distance: targetDist) else { continue }
                
                // Connector (except for the first carriage)
                if i > 0 {
                    let connectorOffset = distOffset - (carriageWidth/2 + spacing/2)
                    let connectorDist = train.isReversed ? (headDist + connectorOffset) : (headDist - connectorOffset)
                    if let cState = getPointAtDistance(points: pathPoints, distance: connectorDist) {
                        let connector = SKShapeNode(rectOf: CGSize(width: spacing + 2, height: 4), cornerRadius: 1)
                        connector.fillColor = .darkGray
                        connector.strokeColor = .clear
                        connector.position = cState.point
                        connector.zRotation = train.isReversed ? cState.angle + .pi : cState.angle
                        connector.zPosition = -1
                        node?.addChild(connector)
                    }
                }
                
                let cNode = GraphicsManager.createTrainShape(color: line.color)
                cNode.position = state.point
                cNode.zRotation = train.isReversed ? state.angle + .pi : state.angle
                node?.addChild(cNode)
                
                // Passengers indicators inside carriages
                let startIdx = i * 6
                let endIdx = min(startIdx + 6, train.passengers.count)
                if startIdx < train.passengers.count {
                    let carriagePassengers = train.passengers[startIdx..<endIdx]
                    let pSpacing: CGFloat = 4.0
                    for localIdx in 0..<carriagePassengers.count {
                        let pDot = SKShapeNode(circleOfRadius: 1.5)
                        pDot.fillColor = .white
                        pDot.strokeColor = .clear
                        pDot.position = CGPoint(x: CGFloat(localIdx) * pSpacing - 10, y: -2)
                        cNode.addChild(pDot)
                    }
                }
            }
            
            node?.alpha = 1.0
        }
    }

}
