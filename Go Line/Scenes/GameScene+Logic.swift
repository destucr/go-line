internal import SpriteKit

extension GameScene {
    
    // MARK: - Game Loop
    func updateGameLogic(dt: TimeInterval) {
        // Update Day Cycle
        DayCycleManager.shared.update(dt: dt)
        
        // Spawn Intervals based on Level
        var baseInterval: TimeInterval = 4.0
        if level >= 2 { baseInterval = 3.0 }
        if level >= 3 { baseInterval = 2.0 }
        if level >= 4 { baseInterval = 1.5 }
        
        currentSpawnInterval = baseInterval
        
        // 1. Spawn Passengers
        passengerSpawnTimer += dt
        if passengerSpawnTimer >= currentSpawnInterval {
            passengerSpawnTimer = 0
            spawnRandomPassenger()
        }
        
        // 2. Spawn New Stations
        stationSpawnTimer += dt
        if stationSpawnTimer >= stationSpawnInterval {
            stationSpawnTimer = 0
            spawnNewStation()
        }
        
        // 3. Move Trains
        moveTrains(dt: dt)
        
        // 4. Check Tension
        updateTension(dt: dt)
        
        // 5. Update Visuals
        updateTrainVisuals()
        // updateStationVisuals() called inside updateTension loop now
    }
    
    func spawnCityStations() {
        gameStations.removeAll()
        stationNodes.removeAll()
        children.forEach { if $0.name?.starts(with: "station") == true { $0.removeFromParent() } }
        
        // Initial Seed: 3 Common Stations (Triangle, Circle, Square)
        // Placed roughly in a triangle in the center
        let safeInsets: UIEdgeInsets = view?.safeAreaInsets ?? .zero
        let padding: CGFloat = 100
        let w = size.width
        let h = size.height
        
        let seeds: [(CGPoint, StationType)] = [
            (CGPoint(x: w * 0.5, y: h * 0.6), .triangle),
            (CGPoint(x: w * 0.3, y: h * 0.4), .circle),
            (CGPoint(x: w * 0.7, y: h * 0.4), .square)
        ]
        
        for (pos, type) in seeds {
            let s = Station(id: UUID(), position: pos, type: type)
            gameStations.append(s)
            renderStation(s)
        }
    }
    
    func spawnNewStation() {
        guard let view = view else { return }
        
        // 1. Determine Type (Weighted)
        // Common: Circle (40%), Triangle (30%), Square (20%)
        // Unique: 10% (Star, Pentagon, Diamond, Cross, Wedge, Oval)
        let roll = Int.random(in: 1...100)
        var newType: StationType = .circle
        
        if roll <= 40 { newType = .circle }
        else if roll <= 70 { newType = .triangle }
        else if roll <= 90 { newType = .square }
        else {
            let uniques: [StationType] = [.pentagon, .star, .diamond, .cross, .wedge, .oval]
            newType = uniques.randomElement() ?? .pentagon
        }
        
        // 2. Determine Position (Relatively close to center, expanding outwards)
        // Instead of pure edge, let's spawn in a circle that grows with level
        let expansionFactors: [CGFloat] = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
        let factor = expansionFactors[min(level - 1, expansionFactors.count - 1)]
        
        let centerX = worldSize.width / 2
        let centerY = worldSize.height / 2
        
        // Base radius is half of initial screen dimension
        let baseRadius = min(size.width, size.height) * 0.4
        let maxRadius = baseRadius * factor
        
        var candidate: CGPoint = .zero
        var validPos = false
        
        for _ in 0..<10 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: baseRadius...maxRadius)
            
            let x = centerX + cos(angle) * dist
            let y = centerY + sin(angle) * dist
            
            // Constrain to world bounds with padding
            let padding: CGFloat = 60
            let clampedX = max(padding, min(worldSize.width - padding, x))
            let clampedY = max(padding, min(worldSize.height - padding, y))
            
            candidate = CGPoint(x: clampedX, y: clampedY)
            
            // Distance check
            var tooClose = false
            for s in gameStations {
                if hypot(s.position.x - candidate.x, s.position.y - candidate.y) < 100 {
                    tooClose = true
                    break
                }
            }
            
            if !tooClose {
                validPos = true
                break
            }
        }
        
        guard validPos else { return }
        
        let s = Station(id: UUID(), position: candidate, type: newType)
        gameStations.append(s)
        renderStation(s)
        
        run(SKAction.playSoundFileNamed("sfx_passenger_spawn.wav", waitForCompletion: false))
    }

    func checkLevelUp() {
        var newLevel = level
        
        if score >= 150 {
            triggerGameOver(reason: "MASTER HUB!\nLegendary Efficiency")
            return
        }
        
        if score >= 100 && level < 6 { newLevel = 6 }
        else if score >= 75 && level < 5 { newLevel = 5 }
        else if score >= 50 && level < 4 { newLevel = 4 }
        else if score >= 30 && level < 3 { newLevel = 3 }
        else if score >= 15 && level < 2 { newLevel = 2 }
        
        if newLevel > level {
            level = newLevel
            handleLevelUp()
            updateAllStationsCapacity()
        }
    }
    
    func updateAllStationsCapacity() {
        let bonus = Int(UpgradeManager.shared.maxTensionBonus / 10.0) // Scaled bonus for capacity
        let baseCap = 6
        for i in 0..<gameStations.count {
            gameStations[i].maxCapacity = baseCap + bonus
        }
    }
    
    func handleLevelUp() {
        showLevelUpPopup()
        
        // Map Expansion
        let expansionFactors: [CGFloat] = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
        let factor = expansionFactors[min(level - 1, expansionFactors.count - 1)]
        let newWorldSize = CGSize(width: size.width * factor, height: size.height * factor)
        worldSize = newWorldSize
        
        // Camera Auto-Zoom and Re-center
        let zoom = 1.0 / factor
        let newCenter = CGPoint(x: newWorldSize.width / 2, y: newWorldSize.height / 2)
        
        let zoomAction = SKAction.scale(to: zoom, duration: 1.5)
        let moveAction = SKAction.move(to: newCenter, duration: 1.5)
        moveAction.timingMode = .easeInEaseOut
        zoomAction.timingMode = .easeInEaseOut
        
        cameraNode.run(SKAction.group([zoomAction, moveAction]))
        
        let confetti = GraphicsManager.createConfettiEmitter()
        confetti.position = newCenter // Center on new world center
        confetti.zPosition = 1001
        addChild(confetti)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run { confetti.removeFromParent() }
        ]))
        
        updateLockedLines()
        onLevelUpdate?(level)
        
        run(SKAction.playSoundFileNamed("sfx_levelup.wav", waitForCompletion: false))
        
        if level >= 4 {
            trainSpeedMultiplier = 1.3
        }
    }
    
    func updateLockedLines() {
        if let blueBtn = uiNodes["line_blue"] {
            let isUnlocked = level >= 2
            blueBtn.isHidden = !isUnlocked
            blueBtn.alpha = isUnlocked ? 1.0 : 0.3
            if !isUnlocked {
                blueBtn.setScale(0.8)
            } else {
                blueBtn.setScale(1.0)
            }
            
            if !isUnlocked && currentLineColor == .systemBlue {
                currentLineColor = .systemRed
                updateHUD()
            }
        }
        
        if let greenBtn = uiNodes["line_green"] {
            let isUnlocked = level >= 3
            greenBtn.isHidden = !isUnlocked
            greenBtn.alpha = isUnlocked ? 1.0 : 0.3
            greenBtn.setScale(isUnlocked ? 1.0 : 0.8)
            
            if !isUnlocked && currentLineColor == .systemGreen {
                currentLineColor = .systemRed
                updateHUD()
            }
        }
        
        if let orangeBtn = uiNodes["line_orange"] {
            let isUnlocked = level >= 4
            orangeBtn.isHidden = !isUnlocked
            orangeBtn.alpha = isUnlocked ? 1.0 : 0.3
            orangeBtn.setScale(isUnlocked ? 1.0 : 0.8)
            
            if !isUnlocked && currentLineColor == .systemOrange {
                currentLineColor = .systemRed
                updateHUD()
            }
        }
        
        if let purpleBtn = uiNodes["line_purple"] {
            let isUnlocked = level >= 5
            purpleBtn.isHidden = !isUnlocked
            purpleBtn.alpha = isUnlocked ? 1.0 : 0.3
            purpleBtn.setScale(isUnlocked ? 1.0 : 0.8)
            
            if !isUnlocked && currentLineColor == .systemPurple {
                currentLineColor = .systemRed
                updateHUD()
            }
        }
    }
    
    func updateTension(dt: TimeInterval) {
        var anyOvercrowded = false
        for i in 0..<gameStations.count {
            let cap = gameStations[i].maxCapacity
            if gameStations[i].passengers.count > cap {
                anyOvercrowded = true
                gameStations[i].overcrowdTimer += dt
                
                // Add Tension based on severity
                let severity = CGFloat(gameStations[i].passengers.count - cap)
                tension += severity * CGFloat(dt) * 0.5
            } else {
                gameStations[i].overcrowdTimer = max(0, gameStations[i].overcrowdTimer - dt)
            }
            // Update node visual
            updateStationVisuals(station: gameStations[i])
        }
        
        // Healing over time (slow) if stable
        if !anyOvercrowded {
            tension = max(0, tension - CGFloat(dt) * 1.0)
        }
        
        // Game Over Check
        if tension >= maxTension {
             triggerGameOver(reason: "Fabric ripped!\nTension Critical")
        }
    }
    

    
    func triggerGameOver(reason: String) {
        isGameOver = true
        // Thematic copy for metro management
        let themedReason = "Metro Network Failure: Line Overload"
        onGameOver?(score, themedReason)
    }
    
    func spawnRandomPassenger() {
        guard !gameStations.isEmpty else { return }
        
        let stationIndex = Int.random(in: 0..<gameStations.count)
        var station = gameStations[stationIndex]
        
        // Get all available station types currently on the map
        let existingTypes = Array(Set(gameStations.map { $0.type }))
        
        // Filter out the current station's type to ensure they have somewhere to go
        let validDestinations = existingTypes.filter { $0 != station.type }
        
        // If no other station types exist (e.g. only Circles on map), pick any other type
        // This edge case shouldn't happen often if we spawn diverse stations, 
        // but as a fallback we can pick a random type or just return to avoid ghost passengers.
        guard let destType = validDestinations.randomElement() else {
             // Fallback: if only one type of station exists, maybe just don't spawn? 
             // Or spawn for a future station? Let's skip spawning to avoid overcrowding with un-movable passengers.
             return 
        }
        
        let passenger = Passenger(id: UUID(), destinationType: destType, spawnTime: lastUpdateTime)
        
        station.passengers.append(passenger)
        gameStations[stationIndex] = station
        
        run(SKAction.playSoundFileNamed("sfx_passenger_spawn.wav", waitForCompletion: false))
    }
    
    func moveTrains(dt: TimeInterval) {
        let baseSpeed: CGFloat = 100.0
        // Apply Upgrades
        let speed = baseSpeed * trainSpeedMultiplier * CGFloat(UpgradeManager.shared.speedMultiplier)
        
        for i in 0..<trains.count {
            var train = trains[i]
            
            // Sync Upgrades
            train.carriages = UpgradeManager.shared.carriageCount
            
            // Handle Waiting/Pause at Station
            if train.isWaiting {
                train.waitTimer -= dt
                if train.waitTimer <= 0 {
                    train.isWaiting = false
                }
                trains[i] = train
                continue
            }
            
            guard let line = metroLines.values.first(where: { $0.id == train.lineID }) else { continue }
            let stations = line.stations
            guard stations.count >= 2 else { continue }
            
            let fromIndex = train.currentSegmentIndex
            let toIndex = train.isReversed ? fromIndex - 1 : fromIndex + 1
            
            if toIndex < 0 || toIndex >= stations.count {
                train.isReversed.toggle()
                trains[i] = train
                continue
            }
            
            let fromID = stations[fromIndex]
            let toID = stations[toIndex]
            
            guard let fromPos = getStationPos(id: fromID),
                  let toPos = getStationPos(id: toID) else { continue }
            
            let distanceTravelled = speed * CGFloat(dt)
            let pathPoints = getStructuredPathPoints(from: fromPos, to: toPos)
            let totalPathDist = calculateTotalDistance(points: pathPoints)
            
            let progressDelta = distanceTravelled / totalPathDist
            train.progress += progressDelta
            
            if train.progress >= 1.0 {
                train.progress = 0.0
                train.currentSegmentIndex = toIndex
                handleStationArrival(train: &train, stationID: toID)
                
                // Center at station and trigger Wait/Pause
                train.position = toPos
                train.isWaiting = true
                train.waitTimer = 2.0 // 2 second pause
                
                if train.currentSegmentIndex == stations.count - 1 {
                    train.isReversed = true
                } else if train.currentSegmentIndex == 0 {
                    train.isReversed = false
                }
            } else {
                let pathState = getPointOnPath(points: pathPoints, progress: train.progress)
                train.position = pathState.point
                train.rotation = pathState.angle
            }
            
            trains[i] = train
        }
    }
    
    func handleStationArrival(train: inout Train, stationID: UUID) {
        guard let stationIndex = gameStations.firstIndex(where: { $0.id == stationID }) else { return }
        var station = gameStations[stationIndex]
        
        // Offboard passengers
        let offboardCount = train.offboard(at: station.type)
        if offboardCount > 0 {
            let earningPerPassenger = 10
            let earnings = offboardCount * earningPerPassenger
            
            print("Offboarded \(offboardCount) passengers at \(station.type). Earnings: \(earnings)")
            
            // Update Progression
            score += offboardCount
            CurrencyManager.shared.addThread(earnings)
            
            // Heal Tension
            tension = max(0, tension - CGFloat(offboardCount) * 5.0)
            
            // Visual Feedback
            showScorePopup(amount: offboardCount, earnings: earnings, at: station.position)
            run(SKAction.playSoundFileNamed("sfx_score.wav", waitForCompletion: false))
        } else {
            // print("Train arrived at \(station.type) but no passengers offboarded.")
        }
        
        // Onboard passengers
        for i in (0..<station.passengers.count).reversed() {
            let p = station.passengers[i]
            // Smart boarding: check capacity
            if train.board(passenger: p) {
                station.passengers.remove(at: i)
            } else {
                break
            }
        }
        
        gameStations[stationIndex] = station
    }
    
    func createCityMap() {
        let riverPath = CGMutablePath()
        riverPath.move(to: CGPoint(x: size.width + 50, y: size.height * 0.55))
        riverPath.addCurve(to: CGPoint(x: size.width * 0.7, y: size.height * 0.45),
                           control1: CGPoint(x: size.width * 0.9, y: size.height * 0.55),
                           control2: CGPoint(x: size.width * 0.8, y: size.height * 0.45))
        riverPath.addCurve(to: CGPoint(x: size.width * 0.4, y: size.height * 0.6),
                           control1: CGPoint(x: size.width * 0.6, y: size.height * 0.45),
                           control2: CGPoint(x: size.width * 0.5, y: size.height * 0.65))
        riverPath.addCurve(to: CGPoint(x: -50, y: size.height * 0.5),
                           control1: CGPoint(x: size.width * 0.2, y: size.height * 0.55),
                           control2: CGPoint(x: size.width * 0.1, y: size.height * 0.5))
        
        let riverShape = SKShapeNode(path: riverPath)
        riverShape.strokeColor = UIColor(red: 0.6, green: 0.8, blue: 0.9, alpha: 0.5)
        riverShape.lineWidth = 50
        riverShape.zPosition = -10
        riverShape.lineCap = .round
        
        let border = SKShapeNode(path: riverPath.copy(dashingWithPhase: 0, lengths: [5, 5]))
        border.strokeColor = .white
        border.lineWidth = 2
        riverShape.addChild(border)
        addChild(riverShape)
        
        let towerNode = SKNode()
        towerNode.position = CGPoint(x: size.width * 0.55, y: size.height * 0.65)
        towerNode.zPosition = -5
        towerNode.alpha = 0.6
        
        let sphere = SKShapeNode(circleOfRadius: 12)
        sphere.strokeColor = .lightGray
        sphere.lineWidth = 2
        sphere.fillColor = .clear
        
        let needlePath = CGMutablePath()
        needlePath.move(to: CGPoint(x: 0, y: 12))
        needlePath.addLine(to: CGPoint(x: 0, y: 40))
        needlePath.move(to: CGPoint(x: 0, y: -12))
        needlePath.addLine(to: CGPoint(x: -10, y: -60))
        needlePath.move(to: CGPoint(x: 0, y: -12))
        needlePath.addLine(to: CGPoint(x: 10, y: -60))
        
        let needle = SKShapeNode(path: needlePath)
        needle.strokeColor = .lightGray
        needle.lineWidth = 2
        
        towerNode.addChild(sphere)
        towerNode.addChild(needle)
        addChild(towerNode)
    }
    

    
    func createSewingScraps() {
        let w = worldSize.width > 0 ? worldSize.width : size.width * 2
        let h = worldSize.height > 0 ? worldSize.height : size.height * 2
        
        for _ in 0..<30 {
            let scrap = GraphicsManager.createScrapNode()
            scrap.position = CGPoint(
                x: CGFloat.random(in: 100...w-100),
                y: CGFloat.random(in: 100...h-100)
            )
            scrap.zPosition = -50
            addChild(scrap)
        }
    }
    
    func calculateTrainRotation(for train: Train) -> CGFloat? {
        guard let line = metroLines.values.first(where: { $0.id == train.lineID }) else { return nil }
        let stations = line.stations
        let fromIndex = train.currentSegmentIndex
        let toIndex = train.isReversed ? fromIndex - 1 : fromIndex + 1
        
        guard stations.indices.contains(fromIndex), stations.indices.contains(toIndex) else { return nil }
        
        let fromPos = getStationPos(id: stations[fromIndex]) ?? .zero
        let toPos = getStationPos(id: stations[toIndex]) ?? .zero
        
        let pathPoints = getStructuredPathPoints(from: fromPos, to: toPos)
        let pathState = getPointOnPath(points: pathPoints, progress: train.progress)
        
        return pathState.angle
    }
}
