# Metro Manager - PRD v1.0

## Core Identity
**Type**: iOS landscape train/metro management sim  
**Goal**: Build profitable transit network via line creation, train ops, passenger satisfaction

## Functional Requirements

### F1: Line Management
- **CREATE**: Draw routes connecting stations (touch-drag interface)
- **EDIT**: Modify existing routes (add/remove stations)
- **DELETE**: Remove unprofitable lines
- **VIEW**: Visual overlay showing all active lines (color-coded)

### F2: Train Operations
- **DEPLOY**: Assign trains to lines (1-N trains per line)
- **ANIMATE**: Real-time train movement along routes
  - Speed varies by train type
  - Stops at stations (3-5s dwell time)
  - Collision avoidance at junctions
- **UPGRADE**: Improve capacity/speed

### F3: Passenger System
- **SPAWN**: Generate passengers at stations (demand-based)
- **QUEUE**: Visual waiting passengers at platforms
- **BOARD**: Auto-board when train arrives (capacity limits)
- **DESTINATION**: Each passenger has target station
- **SATISFACTION**: Time-based happiness decay

### F4: Rating System
**Per-Line Metrics**:
- Efficiency: avg trip time / optimal time (target: >0.7)
- Coverage: stations served / total stations
- Utilization: passengers carried / capacity
- Punctuality: on-time arrivals %

**Overall Score**: Weighted average → star rating (1-5★)

### F5: Line-Specific Management
**Per-Line Controls**:
- Train count adjustment
- Frequency tuning (headway)
- Upgrade allocation
- Enable/disable toggle

**Dashboard View**:
- Revenue vs cost per line
- Passenger throughput
- Problem indicators (overcrowding, delays)

## Technical Constraints
- **Platform**: iOS 15+, landscape only
- **Framework**: Swift + SpriteKit
- **Performance**: 60fps with 10+ active trains
- **Save**: Local persistence (CoreData/Realm)
- **Monetization**: [TBD - freemium/premium]

## Success Metrics
- Session length: >10min avg
- D1 retention: >40%
- Rating submission: >60% of games

## Out of Scope (v1)
- Multiplayer, disasters, weather, real-world maps
