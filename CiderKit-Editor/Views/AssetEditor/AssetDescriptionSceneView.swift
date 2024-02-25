import SpriteKit
import CiderKit_Engine

protocol AssetDescriptionSceneViewDelegate: AnyObject {
    
    var selectedAssetElement: TransformAssetElement? { get }
    
    func descriptionSceneView(_ view: AssetDescriptionSceneView, zoomUpdated newZoomFactor: Int)
    
}

class AssetDescriptionSceneView: LitSceneView, ObservableObject {
    
    private static let defaultSize: Int = 320
    
    private static let lights = [
        matrix_float3x3([vector_float3(0, 0, 5), vector_float3(1, 1, 1), vector_float3(0, 20, 0.5)]),
        matrix_float3x3([vector_float3(5, 1, 1), vector_float3(0.5, 0.4, 0.4), vector_float3(0, 20, 0.5)]),
        matrix_float3x3([vector_float3(1, 5, 1), vector_float3(0.4, 0.4, 0.5), vector_float3(0, 20, 0.5)]),
    ]
    
    private static var gridTexture: SKTexture? = nil
    
    private let resetCameraButton: NSButton
    
    private let lightControls: NSSegmentedControl
    
    private let zoomInButton: NSButton
    private let neutralZoomButton: NSButton
    private let zoomOutButton: NSButton
    private let zoomIndicator: NSTextField
    
    private var zoomFactor: Int = 1

    private var returnToStartButton: NSButton
    private var previousKeyButton: NSButton
    private var playStopButton: NSButton
    private var nextKeyButton: NSButton
    private var skactionPreviewButton: NSButton
    private var currentFrameIndicator: NSTextField
    
    private var lastUpdateTime: TimeInterval? = nil
    private var isPreviewingSKActions: Bool = true
    
    private var shouldApplyDefaults: Bool = true
    
    private let backBoundingBoxShape: SKShapeNode
    private let frontBoundingBoxShape: SKShapeNode
    private var boundingBoxIsShown: Bool = false
    
    private let gridRoot: SKNode
    private let elementsRoot: SKNode
    
    private var lightingEnabled = true
    
    public var assetInstance: EditorAssetInstance {
        didSet {
            if assetInstance !== oldValue {
                oldValue.node!.removeFromParent()
                elementsRoot.addChild(assetInstance.node!)
            }
        }
    }
    
    var assetDescription: AssetDescription { assetInstance.assetDescription }
    
    public weak var descriptionSceneViewDelegate: AssetDescriptionSceneViewDelegate? = nil
    
    public weak var animationControlDelegate: AssetAnimationControlDelegate? = nil {
        didSet {
            if oldValue !== animationControlDelegate {
                NotificationCenter.default.removeObserver(self)
            }
            
            if let animationControlDelegate {
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentFrameDidChange(_:)), name: .animationCurrentFrameDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentTrackDidChange(_:)), name: .animationCurrentTrackDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentAnimationDidChange(_:)), name: .animationCurrentAnimationDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.playStatusDidChange(_:)), name: .animationPlayingDidChange, object: animationControlDelegate)

                updateCurrentFrameIndicator()
                assetInstance.currentAnimationName = animationControlDelegate.currentAnimationName
                assetInstance.currentFrame = animationControlDelegate.currentAnimationFrame
            }
        }
    }
    
    override var ambientLightColorRGB: SIMD3<Float> { lightingEnabled ? SIMD3() : super.ambientLightColorRGB }
    
    override var preferredSceneWidth: Int { Self.defaultSize }
    override var preferredSceneHeight: Int { Self.defaultSize }
    
    init(assetInstance: EditorAssetInstance) {
        self.assetInstance = assetInstance
        
        resetCameraButton = NSButton(title: "Reset Camera", systemSymbolName: "camera.metering.center.weighted", action: #selector(Self.resetCamera))
        resetCameraButton.translatesAutoresizingMaskIntoConstraints = false

        lightControls = NSSegmentedControl(images: [
            NSImage(systemSymbolName: "lightbulb", accessibilityDescription: "")!,
            NSImage(systemSymbolName: "lightbulb.max.fill", accessibilityDescription: "")!
        ], trackingMode: .selectOne, target: nil, action: #selector(Self.onLightControlSelected(_:)))
        lightControls.selectedSegment = 1
        
        zoomInButton = NSButton(systemSymbolName: "plus.magnifyingglass", action: #selector(Self.zoomIn))
        neutralZoomButton = NSButton(systemSymbolName: "1.magnifyingglass", action: #selector(Self.resetZoom))
        zoomOutButton = NSButton(systemSymbolName: "minus.magnifyingglass", action: #selector(Self.zoomOut))
        zoomOutButton.isEnabled = false
        zoomIndicator = NSTextField(labelWithString: "100%")
        
        returnToStartButton = NSButton(systemSymbolName: "backward.end.alt.fill", action: #selector(Self.returnToTrackStart))
        previousKeyButton = NSButton(systemSymbolName: "backward.end.fill", action: #selector(Self.goToPreviousKey))
        playStopButton = NSButton(systemSymbolName: "play.fill", action: #selector(Self.togglePlay))
        nextKeyButton = NSButton(systemSymbolName: "forward.end.fill", action: #selector(Self.goToNextKey))
        skactionPreviewButton = NSButton(title: "Preview w/ SKActions", systemSymbolName: "play.circle", action: #selector(Self.previewWithSKActions))
        currentFrameIndicator = NSTextField(labelWithString: "Test")
        
        backBoundingBoxShape = SKShapeNode()
        backBoundingBoxShape.strokeColor = .purple.shadow(withLevel: 0.5)!
        backBoundingBoxShape.isHidden = true
        backBoundingBoxShape.zPosition = -1
        frontBoundingBoxShape = SKShapeNode()
        frontBoundingBoxShape.strokeColor = .purple
        frontBoundingBoxShape.isHidden = true
        
        gridRoot = SKNode()
        gridRoot.zPosition = -2
        elementsRoot = SKNode()

        super.init(frame: NSRect(x: 0, y: 0, width: Self.defaultSize, height: Self.defaultSize))
        
        resetCameraButton.target = self
        lightControls.target = self
        
        zoomInButton.target = self
        neutralZoomButton.target = self
        zoomOutButton.target = self
        
        returnToStartButton.target = self
        returnToStartButton.isEnabled = false
        previousKeyButton.target = self
        previousKeyButton.isEnabled = false
        playStopButton.target = self
        nextKeyButton.target = self
        nextKeyButton.isEnabled = false
        skactionPreviewButton.target = self
        
        translatesAutoresizingMaskIntoConstraints = false
        showsFPS = true
        showsNodeCount = true
        showsDrawCount = true
        preferredFramesPerSecond = 60
        
        let cameraControlsStack = NSStackView(views: [resetCameraButton, lightControls])
        cameraControlsStack.orientation = .horizontal
        addSubview(cameraControlsStack)
        
        let zoomButtonsStack = NSStackView(views: [zoomInButton, neutralZoomButton, zoomOutButton])
        zoomButtonsStack.orientation = .horizontal
        let zoomControlsStack = NSStackView(views: [zoomButtonsStack, zoomIndicator])
        zoomControlsStack.orientation = .vertical
        addSubview(zoomControlsStack)
        
        let animationButtonsStack = NSStackView(views: [returnToStartButton, previousKeyButton, playStopButton, nextKeyButton, skactionPreviewButton])
        animationButtonsStack.orientation = .horizontal
        let animationControlsStack = NSStackView(views: [currentFrameIndicator, animationButtonsStack])
        animationControlsStack.orientation = .vertical
        animationControlsStack.alignment = .left
        addSubview(animationControlsStack)
        
        addConstraints([
            NSLayoutConstraint(item: cameraControlsStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: cameraControlsStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 8),
            
            NSLayoutConstraint(item: zoomControlsStack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: zoomControlsStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 8),
            
            NSLayoutConstraint(item: animationControlsStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: animationControlsStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -8)
        ])
                
        if Self.gridTexture == nil {
            Self.gridTexture = Atlases["grid"]!["grid_tile_Base"]!
        }
        
        let litNodesRootIndex = litNodesRoot.parent!.children.firstIndex(of: litNodesRoot)!
        litNodesRoot.parent!.insertChild(backBoundingBoxShape, at: litNodesRootIndex)
        litNodesRoot.parent!.insertChild(gridRoot, at: litNodesRootIndex)
        setFootprintGrid(vector_uint2(1, 1))
        
        litNodesRoot.parent!.addChild(frontBoundingBoxShape)

        litNodesRoot.addChild(elementsRoot)
        
        elementsRoot.addChild(assetInstance.node!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onLightControlSelected(_ sender : NSSegmentedControl) {
        lightingEnabled = sender.selectedSegment == 1
    }
    
    @objc
    private func zoomIn() {
        updateZoom(min(16, zoomFactor + 1))
    }
    
    @objc
    private func resetZoom() {
        updateZoom(1)
    }
    
    @objc
    private func zoomOut() {
        updateZoom(max(-1, zoomFactor - 1))
    }
    
    public func updateZoom(_ newZoomFactor: Int) {
        zoomFactor = newZoomFactor
        
        let newScale: CGFloat
        switch zoomFactor {
        case 0:
            newScale = 0.5
        case -1:
            newScale = 0.25
        default:
            newScale = CGFloat(zoomFactor)
        }
        gridRoot.setScale(newScale)
        elementsRoot.setScale(newScale)
        backBoundingBoxShape.setScale(newScale)
        frontBoundingBoxShape.setScale(newScale)
        
        zoomInButton.isEnabled = zoomFactor < 16
        zoomOutButton.isEnabled = zoomFactor > -1
        switch zoomFactor {
        case 0:
            zoomIndicator.stringValue = "50%"
        case -1:
            zoomIndicator.stringValue = "25%"
        default:
            zoomIndicator.stringValue = "\(zoomFactor * 100)%"
        }
        
        descriptionSceneViewDelegate?.descriptionSceneView(self, zoomUpdated: zoomFactor)
    }
    
    @objc
    private func resetCamera() {
        if let scene = scene, let camera = scene.camera {
            camera.position = CGPoint()
        }
    }
    
    @objc
    private func returnToTrackStart() {
        animationControlDelegate?.animationGoToFrame(self, frame: 0)
    }
    
    @objc
    private func goToPreviousKey() {
        animationControlDelegate?.animationGoToPreviousKey(self)
    }
    
    @objc
    private func togglePlay() {
        if isPreviewingSKActions {
            stopPreviewingSKActionsIfNeeded()
        }
        else {
            animationControlDelegate?.animationTogglePlay(self)
        }
    }
    
    @objc
    private func goToNextKey() {
        animationControlDelegate?.animationGoToNextKey(self)
    }
    
    @objc
    private func previewWithSKActions() {
        guard
            let animationControlDelegate,
            let animationName = animationControlDelegate.currentAnimationName,
            let skactionsByElement = assetInstance.getSKActionsByElement(in: animationName)
        else { return }
        
        if animationControlDelegate.isPlaying {
            togglePlay()
        }
        setPlayStopButtonImage(isPlaying: true)
        
        skactionPreviewButton.isEnabled = false
        returnToStartButton.isEnabled = false
        previousKeyButton.isEnabled = false
        nextKeyButton.isEnabled = false
        playStopButton.isEnabled = true
        isPreviewingSKActions = true
        
        hideBoundingBox()
        
        for (element, action) in skactionsByElement {
            let initialUpdateAction = SKAction.run {
                self.assetInstance.applyDefaults(for: element)
            }
            let sequence = SKAction.repeatForever(SKAction.sequence([initialUpdateAction, action]))
            assetInstance.playSKAction(sequence, on: element)
        }
    }
    
    private func stopPreviewingSKActionsIfNeeded() {
        if isPreviewingSKActions {
            assetInstance.killAllSKActions()
            isPreviewingSKActions = false;
            setPlayStopButtonImage(isPlaying: false)
            skactionPreviewButton.isEnabled = true
            assetInstance.currentFrame = 0
            
            if let selectedAssetElement = descriptionSceneViewDelegate?.selectedAssetElement {
                showBoundingBox(for: selectedAssetElement)
            }
        }
    }
    
    public func setFootprintGrid(_ footprint: vector_uint2) {
        guard let gridTexture = Self.gridTexture else { return }
        
        let gridRootChildren = gridRoot.children
        gridRootChildren.forEach { $0.removeFromParent() }
        
        for x in -Int(footprint.x - 1)...0 {
            for y in 0..<Int(footprint.y) {
                let sprite = SKSpriteNode(texture: gridTexture)
                sprite.anchorPoint = CGPoint(x: 0.5, y: 1)
                sprite.position = CGPoint(
                    x: MapNode.halfWidth * (x + y),
                    y: MapNode.halfHeight * (y - x)
                )
                gridRoot.addChild(sprite)
            }
        }
    }
    
    public func showBoundingBox(for element: TransformAssetElement) {
        guard
            element is SpriteAssetElement || element is ReferenceAssetElement,
            let instance = assetInstance[element],
            let boundingBox = instance.boundingBox
        else {
            hideBoundingBox()
            return
        }
        
        showBoundingBox(position: boundingBox.min, size: boundingBox.size * SIMD3(1, 1, 4))
    }
    
    public func showBoundingBox(position: SIMD3<Float>, size: SIMD3<Float>) {
        let origin = MapNode.xVector * position.x + MapNode.yVector * position.y + MapNode.zVector * position.z

        let bottomBack = origin
        let bottomLeft = bottomBack + MapNode.yVector * size.y
        let bottomFront = bottomLeft + MapNode.xVector * size.x
        let bottomRight = bottomBack + MapNode.xVector * size.x

        let topBack = bottomBack + MapNode.zVector * size.z
        let topLeft = topBack + MapNode.yVector * size.y
        let topRight = topBack + MapNode.xVector * size.x
        let topFront = topLeft + MapNode.xVector * size.x
        
        let pathBack = CGMutablePath()
        pathBack.move(to: bottomBack)
        pathBack.addLine(to: topBack)
        pathBack.move(to: bottomBack)
        pathBack.addLine(to: bottomLeft)
        pathBack.move(to: bottomBack)
        pathBack.addLine(to: bottomRight)
        backBoundingBoxShape.path = pathBack
        backBoundingBoxShape.isHidden = false
        
        let pathFront = CGMutablePath()
        pathFront.move(to: bottomFront)
        pathFront.addLine(to: bottomRight)
        pathFront.addLine(to: topRight)
        pathFront.addLine(to: topFront)
        pathFront.addLine(to: bottomFront)
        pathFront.addLine(to: bottomLeft)
        pathFront.addLine(to: topLeft)
        pathFront.addLine(to: topBack)
        pathFront.addLine(to: topRight)
        pathFront.move(to: topFront)
        pathFront.addLine(to: topLeft)
        frontBoundingBoxShape.path = pathFront
        frontBoundingBoxShape.isHidden = false
        
        boundingBoxIsShown = true
    }
    
    public func hideBoundingBox() {
        backBoundingBoxShape.isHidden = true
        frontBoundingBoxShape.isHidden = true
        boundingBoxIsShown = false
    }
    
    override func prepareSceneForPrepasses() {
        super.prepareSceneForPrepasses()
        gridRoot.isHidden = true
        backBoundingBoxShape.isHidden = true
        frontBoundingBoxShape.isHidden = true
    }
    
    override func prepassesDidComplete() {
        super.prepassesDidComplete()
        gridRoot.isHidden = false
        backBoundingBoxShape.isHidden = !boundingBoxIsShown
        frontBoundingBoxShape.isHidden = !boundingBoxIsShown
    }
    
    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == 2 else {
            return
        }
        NSCursor.closedHand.push()
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        guard
            let scene = scene,
            let camera = scene.camera,
            event.buttonNumber == 2
        else {
            return
        }

        let diff = CGPoint(x: event.deltaX, y: -event.deltaY)

        let contentViewSize = visibleRect.size
        let sceneSize = scene.size
        let viewToSceneMultipliers = CGPoint(
            x: sceneSize.width / max(contentViewSize.width, contentViewSize.height),
            y: sceneSize.height / max(contentViewSize.width, contentViewSize.height)
        )

        let worldDiff = diff.applying(CGAffineTransform.init(scaleX: viewToSceneMultipliers.x, y: viewToSceneMultipliers.y))
        camera.position = camera.position.applying(CGAffineTransform(translationX: worldDiff.x, y: worldDiff.y).inverted())
    }
    
    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            NSCursor.pop()
        }
    }
    
    @objc
    private func currentFrameDidChange(_ notif: Notification) {
        stopPreviewingSKActionsIfNeeded()
        updatePreviousAndKeyButtons()
        updateCurrentFrameIndicator()
        if let animationControlDelegate {
            assetInstance.currentFrame = animationControlDelegate.currentAnimationFrame
        }
        if let selectAssetElement = descriptionSceneViewDelegate?.selectedAssetElement {
            showBoundingBox(for: selectAssetElement)
        }
    }
    
    @objc
    private func currentTrackDidChange(_ notif: Notification) {
        stopPreviewingSKActionsIfNeeded()
        updatePreviousAndKeyButtons()
    }
    
    @objc
    private func currentAnimationDidChange(_ notif: Notification) {
        stopPreviewingSKActionsIfNeeded()
        assetInstance.currentAnimationName = animationControlDelegate?.currentAnimationName
    }
    
    @objc
    private func playStatusDidChange(_ notif: Notification) {
        guard let animationControlDelegate else { return }
        
        lastUpdateTime = nil
        setPlayStopButtonImage(isPlaying: animationControlDelegate.isPlaying)
    }
    
    private func setPlayStopButtonImage(isPlaying: Bool) {
        let symbolName = isPlaying ? "stop.fill" : "play.fill"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        playStopButton.image = image
    }
    
    private func updatePreviousAndKeyButtons() {
        guard let animationControlDelegate else { return }
        
        returnToStartButton.isEnabled = animationControlDelegate.currentAnimationFrame > 0
        playStopButton.isEnabled = animationControlDelegate.currentAnimationFrameCount > 0

        if let animationTrack = animationControlDelegate.currentAnimationTrack {
            if animationTrack.hasAnyKey {
                previousKeyButton.isEnabled = animationControlDelegate.currentAnimationFrame > animationTrack.firstKey!.frame
                nextKeyButton.isEnabled = animationControlDelegate.currentAnimationFrame < animationTrack.lastKey!.frame
            }
            else {
                previousKeyButton.isEnabled = false
                nextKeyButton.isEnabled = false
            }
        }
        else {
            previousKeyButton.isEnabled = false
            nextKeyButton.isEnabled = false
        }
    }
    
    private func updateCurrentFrameIndicator() {
        guard let animationControlDelegate else { return }
        
        currentFrameIndicator.stringValue = "Current Frame: \(animationControlDelegate.currentAnimationFrame)"
    }
    
    func updateElement(_ element: TransformAssetElement) {
        assetInstance.updateElement(element)
    }
    
    override func update(_ currentTime: TimeInterval, for scene: SKScene) {
        super.update(currentTime, for: scene)
        
        guard
            let animationControlDelegate,
            animationControlDelegate.isPlaying,
            animationControlDelegate.currentAnimationFrameCount > 1
        else { return }
        
        if let lastUpdateTime {
            let frameDuration = 1.0 / Double(preferredFramesPerSecond)
            let diff = currentTime - lastUpdateTime
            if diff > frameDuration {
                let frameCountToAdvance = UInt((diff / frameDuration).rounded(.down))
                let nextFrameToDisplay = (animationControlDelegate.currentAnimationFrame + frameCountToAdvance) % animationControlDelegate.currentAnimationFrameCount
                animationControlDelegate.animationGoToFrame(self, frame: nextFrameToDisplay)
                assetInstance.currentFrame = nextFrameToDisplay
            }
        }
        lastUpdateTime = currentTime
    }
    
    override func computePositionMatrix() -> matrix_float3x3 {
        let bb = assetInstance.boundingBox
        let min = bb?.min ?? SIMD3()
        let max = bb?.max ?? SIMD3()
        return matrix_float3x3([ min, max, SIMD3() ])
    }
    
    override func getLightMatrix(_ index: Int) -> matrix_float3x3 {
        guard lightingEnabled && index < Self.lights.count else { return super.getLightMatrix(index) }
        return Self.lights[index]
    }
    
}
