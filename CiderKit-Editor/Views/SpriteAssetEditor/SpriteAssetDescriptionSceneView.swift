import SpriteKit
import CiderKit_Engine

protocol SpriteAssetDescriptionSceneViewDelegate: AnyObject {
    
    func descriptionSceneView(_ view: SpriteAssetDescriptionSceneView, zoomUpdated newZoomFactor: Int)
    
}

class SpriteAssetDescriptionSceneView: SKView, ObservableObject, SKSceneDelegate {
    
    private let resetCameraButton: NSButton
    
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
    
    var assetDescription: SpriteAssetDescription
    
    public weak var descriptionSceneViewDelegate: SpriteAssetDescriptionSceneViewDelegate? = nil
    
    public weak var animationControlDelegate: SpriteAssetAnimationControlDelegate? = nil {
        didSet {
            if oldValue !== animationControlDelegate {
                NotificationCenter.default.removeObserver(self)
            }
            
            if let animationControlDelegate {
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentFrameDidChange(_:)), name: .animationCurrentFrameDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentTrackDidChange(_:)), name: .animationCurrentTrackDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.currentStateDidChange(_:)), name: .animationCurrentStateDidChange, object: animationControlDelegate)
                NotificationCenter.default.addObserver(self, selector: #selector(Self.playStatusDidChange(_:)), name: .animationPlayingDidChange, object: animationControlDelegate)

                updateCurrentFrameIndicator()
                updateNodesForCurrentFrame(applyDefaults: true)
            }
        }
    }
    
    init(assetDescription: SpriteAssetDescription) {
        self.assetDescription = assetDescription
        
        resetCameraButton = NSButton(title: "Reset Camera", systemSymbolName: "camera.metering.center.weighted", action: #selector(Self.resetCamera))
        resetCameraButton.translatesAutoresizingMaskIntoConstraints = false

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

        super.init(frame: NSZeroRect)
        
        resetCameraButton.target = self
        
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
        
        addSubview(resetCameraButton)
        
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
            NSLayoutConstraint(item: resetCameraButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: resetCameraButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 8),
            
            NSLayoutConstraint(item: zoomControlsStack, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: zoomControlsStack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 8),
            
            NSLayoutConstraint(item: animationControlsStack, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: animationControlsStack, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func presentScene(_ scene: SKScene?) {
        super.presentScene(scene)
        scene?.delegate = self
        
        updateNodesForCurrentFrame(applyDefaults: true)
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
        (scene as? SpriteAssetDescriptionScene)?.setZoomFactor(newZoomFactor)
        zoomInButton.isEnabled = newZoomFactor < 16
        zoomOutButton.isEnabled = newZoomFactor > -1
        switch newZoomFactor {
        case 0:
            zoomIndicator.stringValue = "50%"
        case -1:
            zoomIndicator.stringValue = "25%"
        default:
            zoomIndicator.stringValue = "\(newZoomFactor * 100)%"
        }
        zoomFactor = newZoomFactor
        
        descriptionSceneViewDelegate?.descriptionSceneView(self, zoomUpdated: newZoomFactor)
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
            let stateName = animationControlDelegate.currentAnimationState,
            let skactionsByElement = assetDescription.getSKActionsByElement(in: stateName)
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
        
        for (element, action) in skactionsByElement {
            let initialUpdateAction = SKAction.run {
                self.updateElementNode(element, in: stateName, at: 0, applyDefaults: true)
            }
            let sequence = SKAction.repeatForever(SKAction.sequence([initialUpdateAction, action]))
            (scene as? SpriteAssetDescriptionScene)?.playSKAction(sequence, on: element)
        }
    }
    
    private func stopPreviewingSKActionsIfNeeded() {
        if isPreviewingSKActions {
            (scene as? SpriteAssetDescriptionScene)?.killAllSKActions()
            isPreviewingSKActions = false;
            setPlayStopButtonImage(isPlaying: false)
            skactionPreviewButton.isEnabled = true
            updateNodesForCurrentFrame(applyDefaults: true)
        }
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
        updateNodesForCurrentFrame(applyDefaults: shouldApplyDefaults)
    }
    
    @objc
    private func currentTrackDidChange(_ notif: Notification) {
        stopPreviewingSKActionsIfNeeded()
        updatePreviousAndKeyButtons()
    }
        
    @objc
    private func currentStateDidChange(_ notif: Notification) {
        stopPreviewingSKActionsIfNeeded()
        shouldApplyDefaults = true
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
        playStopButton.isEnabled = animationControlDelegate.currentAnimationStateFrameCount > 0

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
    
    private func updateNodesForCurrentFrame(applyDefaults: Bool) {
        let rootElement = assetDescription.rootElement
        for childElement in rootElement.children {
            updateElementNodeForCurrentFrame(childElement, applyDefaults: applyDefaults)
        }
        shouldApplyDefaults = false
    }
    
    private func updateElementNodeForCurrentFrame(_ element: SpriteAssetElement, applyDefaults: Bool) {
        if let animationControlDelegate {
            updateElementNode(element, in: animationControlDelegate.currentAnimationState, at: animationControlDelegate.currentAnimationFrame, applyDefaults: applyDefaults)
        }
    }
    
    private func updateElementNode(_ element: SpriteAssetElement, in stateName: String?, at frame: Int, applyDefaults: Bool) {
        if let scene = scene as? SpriteAssetDescriptionScene {
            let animationData = assetDescription.getAnimationData(for: element, in: stateName, at: frame)
            scene.updateElement(element, with: animationData, applyDefaults: applyDefaults)
        }
    }
    
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        guard
            let animationControlDelegate,
            animationControlDelegate.isPlaying,
            animationControlDelegate.currentAnimationStateFrameCount > 1
        else { return }
        
        if let lastUpdateTime {
            let frameDuration = 1.0 / Double(preferredFramesPerSecond)
            let diff = currentTime - lastUpdateTime
            if diff > frameDuration {
                let frameCountToAdvance = Int((diff / frameDuration).rounded(.down))
                let nextFrameToDisplay = (animationControlDelegate.currentAnimationFrame + frameCountToAdvance) % animationControlDelegate.currentAnimationStateFrameCount
                animationControlDelegate.animationGoToFrame(self, frame: nextFrameToDisplay)
            }
        }
        lastUpdateTime = currentTime
    }
    
}
