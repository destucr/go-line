# Go Line 🧵

**Connect the City.**

Go Line is a zen transit management simulator. Draw colorful transit lines to transport passengers, managing efficiency and flow as your city grows.

![Gameplay Preview](screenshots/goline-gameplay-full.webp)

## Stats

![Swift](https://img.shields.io/badge/Swift-5.10-orange?style=flat-square&logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-lightgrey?style=flat-square&logo=apple)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Build](https://img.shields.io/badge/Build-Passing-success?style=flat-square)
![PRs](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square)

![GitHub repo size](https://img.shields.io/github/repo-size/destucr/go-line?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/destucr/go-line?style=social)
![GitHub forks](https://img.shields.io/github/forks/destucr/go-line?style=social)
![GitHub issues](https://img.shields.io/github/issues/destucr/go-line?style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/destucr/go-line?style=flat-square)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/destucr/go-line?style=flat-square)
![GitHub language count](https://img.shields.io/github/languages/count/destucr/go-line?style=flat-square)
![GitHub top language](https://img.shields.io/github/languages/top/destucr/go-line?style=flat-square)

## Core Identity

Go Line is a strategic transit puzzle with a clean, industrial aesthetic. Every line you draw stitches the map together. Every delivery keeps your network stable.

## Key Features

### Progressive Network Expansion

Start with a single red line. Complete shifts to unlock new colors—Blue, Green, Orange, Purple—and build complex multi-line systems.

### Day Cycle Management

Manage your network through timed shifts. The Day Progress Bar tracks your progress. Each successful day earns currency and unlocks.

### Systematic Upgrades

Spend Thread (currency) in the shop to improve your fleet:

- 🚆 **Add Carriages:** Increase train capacity for high-traffic stations.
- ⚡ **Faster Needle:** Boost train speed to reduce wait times.
- 💪 **Network Strength:** Handle higher tension and overcrowding.

### Interactive Camera & UI

- **Industrial UI:** Metallic textures, progress bars, clean typography.
- **Pinch-to-Zoom:** Explore your network with intuitive gestures.

### Smooth Geometry

Draw curved, stitched paths between stations with touch-drag controls. Quadratic Bezier curves and dashed patterns create a clean, handcrafted look.

## How to Play

1. **Connect:** Drag between stations to create a transit line.
2. **Deliver:** Transport passengers (geometric shapes) to matching stations.
3. **Manage Tension:** Prevent overcrowding. High tension leads to network failure.
4. **Advance:** Complete shifts to earn Thread, buy upgrades, unlock colors.

## Gallery

| Menu | Shop | Gameplay |
| :---: | :---: | :---: |
| ![Menu](screenshots/goline-homescreen.webp) | ![Shop](screenshots/goline-upgrade-shop.webp) | ![Guide](screenshots/goline-gameplay-full.webp) |

## 🛠️ Technical Stack
- **Engine:** SpriteKit (2D Game Engine)
- **UI:** SwiftUI (HUD, Shop, and Menus)
- **Reactive Logic:** RxSwift / RxCocoa
- **Dependency Management:** CocoaPods
- **Language:** Swift 5.10
- **Architecture:** Reactive state management with Manager-based relays.
- **Visuals:** Custom GLSL Shaders for paper textures and dashed path rendering.

1. Clone the repository.
2. Ensure you have [CocoaPods](https://cocoapods.org/) installed (`brew install cocoapods`).
3. Run `pod install` in the project root.
4. **Important:** Open **`Go Line.xcworkspace`** in Xcode 15+.
5. Select a Landscape-oriented Simulator (e.g., iPhone 15 Pro).
6. Build and Run!

---

*For fans of minimalist strategy and transit sims.*

[![Made with Swift](https://img.shields.io/badge/Made%20with-Swift-orange?style=for-the-badge&logo=swift)](https://swift.org)
[![SpriteKit](https://img.shields.io/badge/Built%20with-SpriteKit-blue?style=for-the-badge)](https://developer.apple.com/spritekit/)
