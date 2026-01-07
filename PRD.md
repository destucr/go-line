# Metro Stitcher - PRD v1.1

## Core Identity
**Type**: iOS landscape transit management sim with embroidery aesthetics  
**Goal**: Embroider a beautiful transit network via curved thread creation, train movement (shuttles), and passenger satisfaction (stitches).

## Functional Requirements

### F1: Stitch Management (Lines)
- **CREATE**: Draw curved threads connecting stations (touch-drag interface).
- **CURVES**: Threads use quadratic Bezier curves for a soft, woven look.
- **EDIT**: Modify existing threads (add/remove stations).
- **DELETE**: Remove inefficient stitches.
- **VIEW**: Visual overlay showing all active threads (color-coded embroidery floss).

### F2: Shuttle Operations (Trains)
- **DEPLOY**: Assign shuttles to threads (1-N per thread).
- **ANIMATE**: Real-time movement along curved paths.
  - Speed varies by shuttle type.
  - Stops at stations (3-5s dwell time).
  - Collision avoidance at junctions (simulated via offset).
- **UPGRADE**: Improve capacity/speed.

### F3: Passenger System (Stitches)
- **SPAWN**: Generate passengers (buttons) at stations.
- **QUEUE**: Visual waiting buttons at platforms.
- **BOARD**: Auto-board when shuttle arrives (capacity limits).
- **DESTINATION**: Each passenger (button) has a target station shape.
- **SATISFACTION**: Time-based happiness decay.

### F4: Rating System (Pattern Quality)
**Per-Thread Metrics**:
- Efficiency: avg trip time / optimal time (target: >0.7).
- Coverage: stations served / total stations.
- Utilization: passengers carried / capacity.
- Punctuality: on-time arrivals %.

**Overall Pattern Score**: Weighted average → star rating (1-5★).

### F5: Thread-Specific Management
**Per-Thread Controls**:
- Shuttle count adjustment.
- Frequency tuning.
- Upgrade allocation.
- Enable/disable toggle.

**Pattern Dashboard**:
- Revenue vs cost per thread.
- Passenger throughput (stitches/min).
- Problem indicators (Fabric Fraying, delays).

## Technical Requirements
- **Platform**: iOS 15+, landscape only.
- **Framework**: Swift + SpriteKit.
- **Visuals**: Bezier curves for threads, embroidery textures (GraphicsManager).
- **Performance**: 60fps with 10+ active shuttles and curved path calculations.
- **Save**: Local persistence (CoreData/Realm).

## Success Metrics
- Session length: >10min avg.
- D1 retention: >40%.
- Rating submission: >60% of games.

## Out of Scope (v1)
- Multiplayer, disasters, weather, real-world maps.
