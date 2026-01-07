# iOS Auto Layout for Landscape Games

Use this skill when implementing responsive layouts for landscape-oriented iOS games that need to adapt across iPhone and iPad screen sizes.

## When to Apply

- Creating landscape game layouts
- Adapting UI for iPhone/iPad size classes
- Building responsive HUD and control interfaces
- Handling safe areas (notch, home indicator)
- Supporting both landscape left and right orientations

## Instructions

### 1. Programmatic Layout Foundation

**Always disable autoresizing masks**:
```swift
view.translatesAutoresizingMaskIntoConstraints = false
```

**Activation pattern**:
```swift
NSLayoutConstraint.activate([
    // List all constraints here
])
```

### 2. Safe Area Anchors (Critical for Landscape)

iPhone notch/Dynamic Island affects landscape edges:

```swift
// Top HUD - avoid notch
hudView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
hudView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
hudView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)

// Bottom controls - avoid home indicator
controlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
controlsView.heightAnchor.constraint(equalToConstant: 60)
```

**Safe area insets vary**:
- iPhone portrait: top ~47pt, bottom ~34pt
- iPhone landscape: leading/trailing ~47pt (notch side), ~21pt (other side)
- iPad: Minimal (no notch)

### 3. Aspect Ratio Constraints

Lock game canvas to specific ratio:

```swift
// 16:9 game board
gameBoardView.widthAnchor.constraint(
    equalTo: gameBoardView.heightAnchor, 
    multiplier: 16.0/9.0
).isActive = true

// Center it
gameBoardView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
gameBoardView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

// Max size constraints
gameBoardView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32).isActive = true
gameBoardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, constant: -120).isActive = true
```

### 4. Priority System

Use priorities to handle conflicting constraints:

```swift
// Prefer specific size, but allow compression
let widthConstraint = view.widthAnchor.constraint(equalToConstant: 800)
widthConstraint.priority = .defaultHigh // 750

let maxWidthConstraint = view.widthAnchor.constraint(lessThanOrEqualTo: superview.widthAnchor)
maxWidthConstraint.priority = .required // 1000

NSLayoutConstraint.activate([widthConstraint, maxWidthConstraint])
```

**Priority levels**:
- `.required` (1000) - Must be satisfied
- `.defaultHigh` (750) - Preferred size
- `.defaultLow` (250) - Nice to have
- Custom: `UILayoutPriority(rawValue: 900)`

### 5. Size Classes for iPhone/iPad

Detect device type and adjust:

```swift
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    updateLayoutForTraits(traitCollection)
}

func updateLayoutForTraits(_ traits: UITraitCollection) {
    if traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular {
        // iPad
        buttonHeight = 80
        fontSize = 24
        spacing = 24
    } else {
        // iPhone
        buttonHeight = 60
        fontSize = 18
        spacing = 16
    }
    
    view.setNeedsLayout()
}
```

**Size class combinations**:
- iPhone landscape: `compact width, compact height`
- iPad landscape: `regular width, regular height`
- iPad portrait: `regular width, regular height`

### 6. Dynamic Spacing with UIStackView

Simplify button layouts:

```swift
let buttonStack = UIStackView(arrangedSubviews: [btn1, btn2, btn3])
buttonStack.axis = .horizontal
buttonStack.distribution = .fillEqually
buttonStack.spacing = 16
buttonStack.translatesAutoresizingMaskIntoConstraints = false

view.addSubview(buttonStack)
NSLayoutConstraint.activate([
    buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
    buttonStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
    buttonStack.heightAnchor.constraint(equalToConstant: 60)
])
```

**Distribution options**:
- `.fillEqually` - All subviews equal size
- `.equalSpacing` - Equal gaps between views
- `.fillProportionally` - Based on intrinsic content size

### 7. Constraint Animation

Animate layout changes smoothly:

```swift
// Change constraint constant
heightConstraint.constant = isExpanded ? 200 : 100

// Animate
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
    self.view.layoutIfNeeded() // Triggers constraint recalculation
}
```

### 8. Common Layout Patterns

**HUD Overlay** (non-intrusive):
```swift
let hudContainer = UIView()
hudContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
hudContainer.layer.cornerRadius = 12

NSLayoutConstraint.activate([
    hudContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
    hudContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
    hudContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
    hudContainer.heightAnchor.constraint(equalToConstant: 44)
])
```

**Bottom Control Bar**:
```swift
NSLayoutConstraint.activate([
    controlBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
    controlBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
    controlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    controlBar.heightAnchor.constraint(equalToConstant: 80)
])
```

**Centered Modal**:
```swift
NSLayoutConstraint.activate([
    modal.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    modal.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    modal.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
    modal.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.8)
])
```

### 9. Debugging Constraints

**Identify ambiguous layouts**:
```swift
#if DEBUG
print(view.hasAmbiguousLayout) // true if under-constrained
view.exerciseAmbiguityInLayout() // Randomly pick valid layout
#endif
```

**Visual debugging**:
```swift
// Print constraint issues
po [[UIWindow keyWindow] _autolayoutTrace]

// Constraint identifier
constraint.identifier = "GameBoard.Width"
```

### 10. Performance Considerations

- Minimize constraint changes per frame
- Use `setNeedsLayout()` then `layoutIfNeeded()` in batch
- Avoid adding/removing views frequently (use `isHidden` instead)
- Cache constraints for repeated animations

```swift
// Good: Change once, animate once
constraint1.constant = newValue1
constraint2.constant = newValue2
UIView.animate(withDuration: 0.3) {
    self.view.layoutIfNeeded()
}

// Bad: Multiple layout passes
UIView.animate(withDuration: 0.3) {
    constraint1.constant = newValue1
    self.view.layoutIfNeeded()
}
UIView.animate(withDuration: 0.3) {
    constraint2.constant = newValue2
    self.view.layoutIfNeeded()
}
```

## Landscape Layout Blueprint

```
┌─────────────────────────────────────────────────────────┐
│ Safe Leading (44pt)                  Safe Trailing (44pt)│
│  ┌──────────────────────────────────────────────┐       │
│  │ [HUD: Score, Time, Menu] (Height: 44-60pt)  │       │
│  └──────────────────────────────────────────────┘       │
│                                                          │
│  ┌──────────────────────────────────────────────┐       │
│  │                                              │       │
│  │          [Game Canvas]                       │       │
│  │        (Aspect Ratio Locked)                 │       │
│  │                                              │       │
│  └──────────────────────────────────────────────┘       │
│                                                          │
│  ┌──────────────────────────────────────────────┐       │
│  │ [Controls: Buttons] (Height: 60-80pt)        │       │
│  └──────────────────────────────────────────────┘       │
│ Safe Bottom (21-34pt)                                    │
└─────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Always use safe area guides** in landscape
2. **Test both orientations** (left and right)
3. **Set intrinsicContentSize** for custom views
4. **Use stackViews** for button groups
5. **Cache frequently changed constraints**
6. **Provide fallback widths** with priorities
7. **Test on smallest target device** (iPhone SE)
8. **Use constraint identifiers** for debugging

## Testing Checklist

- [ ] Layout correct on iPhone SE (smallest)
- [ ] Layout correct on iPhone 15 Pro Max (largest iPhone)
- [ ] Layout correct on iPad Pro 12.9"
- [ ] No constraint conflicts in console
- [ ] Safe areas respected (no notch overlap)
- [ ] Both landscape orientations work
- [ ] UI readable after device rotation
- [ ] Modals center properly on all sizes