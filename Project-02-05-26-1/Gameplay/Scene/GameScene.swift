import SpriteKit
import SwiftUI

class GameScene: SKScene {
    var engine: GameEngine?
    
    // Physics categories
    private let coinCategory: UInt32 = 0x1 << 0
    private let floorCategory: UInt32 = 0x1 << 1
    
    // Nodes
    private let world = SKNode()              // shaken on crash
    private var floorNode: SKShapeNode!
    private var emblem: SKShapeNode!          // central tap target
    private var emblemLabel: SKLabelNode!
    private var locationLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var comboBarBg: SKShapeNode!
    private var comboBarFill: SKShapeNode!
    private var flashOverlay: SKSpriteNode!
    
    // Combo state
    private var combo: Int = 0
    private var lastTapTime: TimeInterval = 0
    private var comboWindow: TimeInterval = 1.3
    private var lastUpdate: TimeInterval = 0
    
    // Colors
    private let gold = SKColor(red: 1.0, green: 0.77, blue: 0.0, alpha: 1.0)
    private let goldDark = SKColor(red: 0.8, green: 0.55, blue: 0.0, alpha: 1.0)
    private let coral = SKColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0)
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        addChild(world)
        
        setupBackground()
        setupGridFloor()
        setupEmblem()
        setupComboUI()
        setupFlashOverlay()
        
        updateLocation(to: engine?.state?.currentRank ?? .streetHustler)
        startBonusCoinLoop()
    }
    
    // MARK: - Setup
    
    private func setupBackground() {
        let bg = SKSpriteNode(color: SKColor(white: 0.06, alpha: 1.0), size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -100
        bg.name = "bg"
        world.addChild(bg)
        
        locationLabel = SKLabelNode(text: "")
        locationLabel.fontName = "Menlo-Bold"
        locationLabel.fontSize = 22
        locationLabel.fontColor = .white
        locationLabel.alpha = 0.18
        locationLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.74)
        locationLabel.zPosition = -50
        world.addChild(locationLabel)
    }
    
    private func setupGridFloor() {
        // Neon grid lines along the floor area for a "terminal" depth feel.
        let grid = SKNode()
        grid.zPosition = -40
        let rows = 6
        for i in 0...rows {
            let y = CGFloat(i) * 14
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.position = CGPoint(x: size.width / 2, y: 30 + y)
            line.fillColor = gold.withAlphaComponent(0.10 - Double(i) * 0.012)
            line.strokeColor = .clear
            grid.addChild(line)
        }
        world.addChild(grid)
        
        floorNode = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 40))
        floorNode.position = CGPoint(x: size.width / 2, y: 20)
        floorNode.fillColor = SKColor(white: 0.04, alpha: 1.0)
        floorNode.strokeColor = .clear
        floorNode.physicsBody = SKPhysicsBody(rectangleOf: floorNode.frame.size)
        floorNode.physicsBody?.isDynamic = false
        floorNode.physicsBody?.categoryBitMask = floorCategory
        world.addChild(floorNode)
    }
    
    private func setupEmblem() {
        let radius: CGFloat = 64
        emblem = SKShapeNode(circleOfRadius: radius)
        emblem.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        emblem.fillColor = gold.withAlphaComponent(0.18)
        emblem.strokeColor = gold
        emblem.lineWidth = 3
        emblem.glowWidth = 6
        emblem.zPosition = 10
        emblem.name = "emblem"
        
        emblemLabel = SKLabelNode(text: "$")
        emblemLabel.fontName = "AvenirNext-Heavy"
        emblemLabel.fontSize = 60
        emblemLabel.fontColor = gold
        emblemLabel.verticalAlignmentMode = .center
        emblemLabel.horizontalAlignmentMode = .center
        emblem.addChild(emblemLabel)
        
        // Idle breathing pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9)
        ])
        emblem.run(SKAction.repeatForever(pulse))
        
        // Rotating ring around the emblem
        let ring = SKShapeNode(circleOfRadius: radius + 16)
        ring.strokeColor = gold.withAlphaComponent(0.35)
        ring.lineWidth = 2
        ring.fillColor = .clear
        ring.name = "ring"
        let dash = SKShapeNode(circleOfRadius: radius + 16)
        dash.strokeColor = gold.withAlphaComponent(0.0)
        dash.lineWidth = 0
        emblem.addChild(ring)
        ring.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 8)))
        
        world.addChild(emblem)
    }
    
    private func setupComboUI() {
        comboLabel = SKLabelNode(text: "")
        comboLabel.fontName = "Menlo-Bold"
        comboLabel.fontSize = 20
        comboLabel.fontColor = gold
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.42 + 100)
        comboLabel.zPosition = 20
        world.addChild(comboLabel)
        
        let barWidth: CGFloat = 160
        comboBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 6), cornerRadius: 3)
        comboBarBg.position = CGPoint(x: size.width / 2, y: size.height * 0.42 + 84)
        comboBarBg.fillColor = SKColor(white: 1, alpha: 0.12)
        comboBarBg.strokeColor = .clear
        comboBarBg.zPosition = 20
        comboBarBg.alpha = 0
        world.addChild(comboBarBg)
        
        comboBarFill = SKShapeNode(rectOf: CGSize(width: barWidth, height: 6), cornerRadius: 3)
        comboBarFill.fillColor = gold
        comboBarFill.strokeColor = .clear
        comboBarFill.zPosition = 21
        comboBarFill.alpha = 0
        comboBarFill.position = comboBarBg.position
        world.addChild(comboBarFill)
    }
    
    private func setupFlashOverlay() {
        flashOverlay = SKSpriteNode(color: coral, size: size)
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.zPosition = 500
        flashOverlay.alpha = 0
        addChild(flashOverlay) // not in world, so it covers during shake
    }
    
    // MARK: - Touch handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let worldLocation = touch.location(in: world)
        
        // Did we tap a flying bonus coin?
        let tapped = nodes(at: location)
        if let bonus = tapped.first(where: { $0.name == "bonus" || $0.parent?.name == "bonus" }) {
            let node = bonus.name == "bonus" ? bonus : bonus.parent!
            collectBonus(node)
            return
        }
        
        registerTap(at: worldLocation)
    }
    
    private func registerTap(at point: CGPoint) {
        guard let engine = engine else { return }
        let now = CACurrentMediaTime()
        
        if now - lastTapTime < comboWindow {
            combo += 1
        } else {
            combo = 1
        }
        lastTapTime = now
        
        let comboMult = 1.0 + Double(min(combo, 50)) * 0.08
        let isCrit = Double.random(in: 0...1) < 0.10
        let critMult = isCrit ? 10.0 : 1.0
        let amount = engine.tapBaseValue * comboMult * critMult
        
        engine.applyTapEarnings(amount)
        
        squashEmblem()
        burst(at: emblem.position, color: isCrit ? coral : gold, count: isCrit ? 16 : 8)
        spawnFloatingLabel(amount: amount, isCrit: isCrit, at: emblem.position)
        spawnCoin(at: CGPoint(x: emblem.position.x + CGFloat.random(in: -30...30), y: emblem.position.y))
        updateComboUI()
        
        Task { @MainActor in SoundManager.shared.playGameTap() }
        let generator = UIImpactFeedbackGenerator(style: isCrit ? .heavy : .light)
        generator.impactOccurred()
    }
    
    private func squashEmblem() {
        emblem.removeAction(forKey: "squash")
        let down = SKAction.scale(to: 0.86, duration: 0.05)
        let up = SKAction.scale(to: 1.0, duration: 0.18)
        up.timingMode = .easeOut
        emblem.run(SKAction.sequence([down, up]), withKey: "squash")
    }
    
    private func updateComboUI() {
        if combo >= 2 {
            comboLabel.text = "КОМБО x\(combo)"
            comboLabel.fontColor = combo >= 20 ? coral : gold
            comboBarBg.alpha = 1
            comboBarFill.alpha = 1
            // pop animation
            comboLabel.removeAction(forKey: "pop")
            comboLabel.setScale(1.3)
            comboLabel.run(SKAction.scale(to: 1.0, duration: 0.15), withKey: "pop")
        } else {
            comboLabel.text = ""
        }
    }
    
    // MARK: - Effects
    
    private func spawnFloatingLabel(amount: Double, isCrit: Bool, at point: CGPoint) {
        let container = SKNode()
        container.position = CGPoint(x: point.x + CGFloat.random(in: -20...20), y: point.y + 50)
        container.zPosition = 50
        
        let label = SKLabelNode(text: "+\(formatMoneyShort(amount))")
        label.fontName = "Menlo-Bold"
        label.fontSize = isCrit ? 28 : 18
        label.fontColor = isCrit ? coral : gold
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        if isCrit {
            let crit = SKLabelNode(text: "КРИТ!")
            crit.fontName = "Menlo-Bold"
            crit.fontSize = 14
            crit.fontColor = coral
            crit.position = CGPoint(x: 0, y: 24)
            container.addChild(crit)
        }
        
        world.addChild(container)
        
        let move = SKAction.moveBy(x: 0, y: 80, duration: 0.9)
        move.timingMode = .easeOut
        let fade = SKAction.sequence([SKAction.wait(forDuration: 0.4), SKAction.fadeOut(withDuration: 0.5)])
        container.run(SKAction.group([move, fade])) { container.removeFromParent() }
    }
    
    private func burst(at point: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            p.fillColor = color
            p.strokeColor = .clear
            p.position = point
            p.zPosition = 40
            world.addChild(p)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 30...90)
            let dest = CGPoint(x: point.x + cos(angle) * dist, y: point.y + sin(angle) * dist)
            let move = SKAction.move(to: dest, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            p.run(SKAction.group([move, fade])) { p.removeFromParent() }
        }
    }
    
    private func spawnCoin(at position: CGPoint) {
        let coinSize = CGSize(width: 40, height: 40)
        let coin = SKSpriteNode(imageNamed: "default-coin")
        coin.size = coinSize
        coin.position = position
        
        coin.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        coin.physicsBody?.restitution = 0.6
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.collisionBitMask = floorCategory | coinCategory
        world.addChild(coin)
        
        coin.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -14...14), dy: CGFloat.random(in: 14...34)))
        coin.physicsBody?.applyTorque(CGFloat.random(in: -0.5...0.5))
        
        coin.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.fadeOut(withDuration: 0.8),
            SKAction.removeFromParent()
        ]))
    }
    
    func spawnPassiveIncomeCoin() {
        let randomX = CGFloat.random(in: 40...(size.width - 40))
        spawnCoin(at: CGPoint(x: randomX, y: size.height + 40))
    }
    
    // MARK: - Bonus coins (catch mechanic)
    
    private func startBonusCoinLoop() {
        let wait = SKAction.wait(forDuration: 9, withRange: 6)
        let spawn = SKAction.run { [weak self] in self?.spawnBonusCoin() }
        run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
    }
    
    private func spawnBonusCoin() {
        let fromLeft = Bool.random()
        let y = CGFloat.random(in: size.height * 0.35...size.height * 0.7)
        let startX: CGFloat = fromLeft ? -40 : size.width + 40
        let endX: CGFloat = fromLeft ? size.width + 40 : -40
        
        let bonusImage = Bool.random() ? "bonus-coin-1" : "bonus-coin-2"
        let node = SKSpriteNode(imageNamed: bonusImage)
        node.name = "bonus"
        node.size = CGSize(width: 50, height: 50)
        node.position = CGPoint(x: startX, y: y)
        node.zPosition = 60
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.5)))
        
        addChild(node) // not in world; stays catchable during shake
        
        let cross = SKAction.move(to: CGPoint(x: endX, y: y), duration: 4.0)
        node.run(SKAction.sequence([cross, SKAction.removeFromParent()]))
    }
    
    private func collectBonus(_ node: SKNode) {
        guard let engine = engine else { return }
        let reward = max(50, engine.tapBaseValue * 40)
        engine.applyTapEarnings(reward)
        
        burst(at: convert(node.position, to: world), color: gold, count: 24)
        spawnFloatingLabel(amount: reward, isCrit: true, at: convert(node.position, to: world))
        node.removeFromParent()
        
        Task { @MainActor in SoundManager.shared.playBonusCollect() }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Big events
    
    func crashEffect() {
        // Red flash
        flashOverlay.color = coral
        flashOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.08),
            SKAction.fadeAlpha(to: 0, duration: 0.5)
        ]))
        shake()
        
        let warn = SKLabelNode(text: "КРАХ РЫНКА")
        warn.fontName = "Menlo-Bold"
        warn.fontSize = 26
        warn.fontColor = coral
        warn.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        warn.zPosition = 600
        addChild(warn)
        warn.setScale(0.5)
        warn.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.2, duration: 0.2), SKAction.fadeIn(withDuration: 0.2)]),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
    
    func rankUpEffect() {
        flashOverlay.color = gold
        flashOverlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.35, duration: 0.1),
            SKAction.fadeAlpha(to: 0, duration: 0.6)
        ]))
        burst(at: emblem.position, color: gold, count: 40)
        
        let warn = SKLabelNode(text: "НОВЫЙ РАНГ!")
        warn.fontName = "Menlo-Bold"
        warn.fontSize = 30
        warn.fontColor = gold
        warn.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        warn.zPosition = 600
        addChild(warn)
        warn.setScale(0.5)
        warn.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.3, duration: 0.25), SKAction.fadeIn(withDuration: 0.2)]),
            SKAction.wait(forDuration: 0.9),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
    
    private func shake() {
        world.removeAction(forKey: "shake")
        var actions: [SKAction] = []
        for _ in 0..<8 {
            let dx = CGFloat.random(in: -10...10)
            let dy = CGFloat.random(in: -10...10)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.04))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.04))
        }
        actions.append(SKAction.move(to: .zero, duration: 0.05))
        world.run(SKAction.sequence(actions), withKey: "shake")
    }
    
    func updateLocation(to rank: Rank) {
        locationLabel?.text = rank.locationName.uppercased()
        let newColor: SKColor
        switch rank {
        case .streetHustler: newColor = SKColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
        case .officeRookie: newColor = SKColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1.0)
        case .floorTrader: newColor = SKColor(red: 0.12, green: 0.14, blue: 0.10, alpha: 1.0)
        case .whale: newColor = SKColor(red: 0.14, green: 0.10, blue: 0.16, alpha: 1.0)
        case .wallStreetLegend: newColor = SKColor(red: 0.16, green: 0.13, blue: 0.05, alpha: 1.0)
        case .orbitalCEO: newColor = SKColor(red: 0.04, green: 0.05, blue: 0.16, alpha: 1.0)
        }
        if let bg = world.childNode(withName: "bg") as? SKSpriteNode {
            bg.run(SKAction.colorize(with: newColor, colorBlendFactor: 1.0, duration: 1.0))
        }
    }
    
    // MARK: - Update loop (combo decay)
    
    override func update(_ currentTime: TimeInterval) {
        if combo > 0 {
            let elapsed = currentTime - lastTapTime
            let remaining = max(0, 1.0 - (elapsed / comboWindow))
            comboBarFill.xScale = CGFloat(remaining)
            comboBarFill.position.x = comboBarBg.position.x - (comboBarBg.frame.width * (1 - CGFloat(remaining)) / 2)
            
            if elapsed > comboWindow {
                combo = 0
                comboLabel.text = ""
                comboBarBg.run(SKAction.fadeOut(withDuration: 0.3))
                comboBarFill.run(SKAction.fadeOut(withDuration: 0.3))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatMoneyShort(_ value: Double) -> String {
        let absV = abs(value)
        if absV >= 1_000_000_000 { return "$\(String(format: "%.1f", value / 1_000_000_000))B" }
        if absV >= 1_000_000 { return "$\(String(format: "%.1f", value / 1_000_000))M" }
        if absV >= 1_000 { return "$\(String(format: "%.1f", value / 1_000))K" }
        return "$\(String(format: "%.0f", value))"
    }
}
