internal import SpriteKit

extension GameScene {
    
    func renderStation(_ station: Station) {
        let node = GraphicsManager.createStationShape(type: station.type, radius: stationRadius)
        node.position = station.position
        node.name = "station_\(station.id)"
        node.zPosition = 10
        addChild(node)
        
        // Fix: stationNodes is [UUID: SKShapeNode]
        stationNodes[station.id] = node
    }
    
    func updateStationVisuals(station: Station) {
        guard let node = stationNodes[station.id] else { return }
        
        // 1. Handle Overcrowding / Tension Pulse
        if station.isOvercrowded {
            if node.action(forKey: "pulse") == nil {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                node.run(SKAction.repeatForever(pulse), withKey: "pulse")
                node.fillColor = .systemRed // Tint red
            }
        } else {
            node.removeAction(forKey: "pulse")
            node.setScale(1.0)
            node.fillColor = .white // Restore white fill
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
        // Remove old train nodes that aren't in the state anymore
        let currentTrainIDs = Set(trains.map { $0.id })
        for (id, node) in trainNodes {
            if !currentTrainIDs.contains(id) {
                node.removeFromParent()
                trainNodes.removeValue(forKey: id)
            }
        }
        
        for train in trains {
            var node = trainNodes[train.id]
            if node == nil {
                // Fix: remove unused 'line' variable
                guard metroLines.values.contains(where: { $0.id == train.lineID }) else { continue }
                node = GraphicsManager.createTrainShape(color: .black)
                node?.zPosition = 20
                addChild(node!)
                trainNodes[train.id] = node
            }
            
            node?.position = train.position
            node?.zRotation = train.rotation
            
            // Update passenger dots inside train
            node?.removeAllChildren()
            let pSpacing: CGFloat = 5.0
            // Fix: use _ for unused 'passenger' in loop
            for (index, _) in train.passengers.enumerated() {
                let pNode = SKShapeNode(circleOfRadius: 2)
                pNode.fillColor = .white
                pNode.strokeColor = .clear
                pNode.position = CGPoint(x: CGFloat(index) * pSpacing - 8, y: 0)
                node?.addChild(pNode)
            }
            
            // Disappear if waiting at station (if user requested that earlier)
            node?.alpha = train.isWaiting ? 0.0 : 1.0
        }
    }
}
