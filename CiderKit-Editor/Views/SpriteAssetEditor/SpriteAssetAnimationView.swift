import AppKit
import CiderKit_Engine

extension NSUserInterfaceItemIdentifier {
    
    static let tracks = NSUserInterfaceItemIdentifier(rawValue: "tracks")
    static let dopeSheet = NSUserInterfaceItemIdentifier(rawValue: "dopeSheet")
    
}

final class SpriteAssetAnimationView: NSView, NSSplitViewDelegate, NSTableViewDelegate, SpriteAssetAnimationControlDelegate, SpriteAssetAnimationTrackNameViewDelegate {
    
    private let splitView: NSSplitView
    
    private let leftScrollView: NSScrollView
    private let rightScrollView: NSScrollView

    private var tracksDataSource: NSTableViewDataSource? = nil
    private let tracksView: NSTableView
    private var dopeSheetView: NSTableView
    
    private(set) var isPlaying: Bool = false
    
    private(set) var currentAnimationFrame: Int = 0
    
    private(set) var currentAnimationState: String? = nil {
        didSet {
            if currentAnimationState != oldValue {
                tracksDataSource = SpriteAssetAnimationTracksDataSource(asset: assetDescription, animationState: currentAnimationState)
                tracksView.dataSource = tracksDataSource
                dopeSheetView.dataSource = tracksDataSource
            }
        }
    }
    
    private(set) var currentAnimationTrackIdentifier: SpriteAssetAnimationTrackIdentifier? = nil
    
    var currentAnimationTrack: SpriteAssetAnimationTrack? {
        guard let currentAnimationState, let currentAnimationTrackIdentifier else { return nil }
        return assetDescription.animationStates[currentAnimationState]?.animationTracks[currentAnimationTrackIdentifier]
    }
    
    var currentAnimationStateFrameCount: Int {
        guard let currentAnimationState else { return 0 }
        
        let state = assetDescription.animationStates[currentAnimationState]!
        var maxFrame: Int = 0
        for (_, track) in state.animationTracks {
            if let lastKey = track.lastKey {
                maxFrame = max(maxFrame, lastKey.frame + 1)
            }
        }
        return maxFrame
    }
    
    var assetDescription: SpriteAssetDescription {
        didSet {
            if assetDescription !== oldValue {
                currentAnimationState = assetDescription.animationStates.keys.sorted().first
                tracksDataSource = SpriteAssetAnimationTracksDataSource(asset: assetDescription, animationState: currentAnimationState)
                tracksView.dataSource = tracksDataSource
                dopeSheetView.dataSource = tracksDataSource
            }
        }
    }
    
    init(assetDescription: SpriteAssetDescription) {
        self.assetDescription = assetDescription
        
        splitView = NSSplitView()

        leftScrollView = NSScrollView()
        rightScrollView = NSScrollView()
        
        tracksView = NSTableView()
        dopeSheetView = NSTableView()
        
        super.init(frame: NSZeroRect)

        translatesAutoresizingMaskIntoConstraints = false
        
        wantsLayer = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        splitView.isVertical = true
        splitView.delegate = self
        splitView.dividerStyle = .paneSplitter
        
        leftScrollView.hasVerticalScroller = false
        leftScrollView.hasHorizontalScroller = true
        leftScrollView.autohidesScrollers = true
        splitView.addArrangedSubview(leftScrollView)
        
        rightScrollView.hasVerticalScroller = true
        rightScrollView.hasHorizontalScroller = true
        rightScrollView.autohidesScrollers = true
        splitView.addArrangedSubview(rightScrollView)
        
        addSubview(splitView)
        
        currentAnimationState = assetDescription.animationStates.keys.sorted().first
        tracksDataSource = SpriteAssetAnimationTracksDataSource(asset: assetDescription, animationState: currentAnimationState)

        tracksView.intercellSpacing = NSZeroSize
        tracksView.style = .plain
        tracksView.rowHeight = 24
        tracksView.delegate = self
        let tracksColumn = NSTableColumn(identifier: .tracks)
        tracksColumn.title = "State"
        tracksView.addTableColumn(tracksColumn)
        tracksView.allowsColumnResizing = false
        tracksView.allowsColumnReordering = false
        tracksView.allowsColumnSelection = false
        tracksView.allowsEmptySelection = true
        tracksView.allowsMultipleSelection = false
        tracksView.usesAlternatingRowBackgroundColors = true
        let headerView = SpriteAssetAnimationTracksHeaderView(frame: tracksView.headerView!.frame, asset: assetDescription, animationState: currentAnimationState)
        headerView.animationControlDelegate = self
        tracksView.headerView = headerView
        tracksView.dataSource = tracksDataSource
        leftScrollView.documentView = tracksView
        leftScrollView.contentView.scroll(to: NSPoint())
        
        dopeSheetView.intercellSpacing = NSZeroSize
        dopeSheetView.style = .plain
        dopeSheetView.rowHeight = 24
        dopeSheetView.delegate = self
        let dopeSheetColumn = NSTableColumn(identifier: .dopeSheet)
        dopeSheetColumn.title = "Dope Sheet"
        dopeSheetColumn.width = 10000
        dopeSheetView.addTableColumn(dopeSheetColumn)
        dopeSheetView.allowsColumnResizing = false
        dopeSheetView.allowsColumnReordering = false
        dopeSheetView.allowsColumnSelection = false
        dopeSheetView.allowsEmptySelection = true
        dopeSheetView.allowsMultipleSelection = false
        dopeSheetView.usesAlternatingRowBackgroundColors = true
        dopeSheetView.selectionHighlightStyle = .none
        dopeSheetView.headerView = SpriteAssetAnimationDopeSheetHeaderView(frame: dopeSheetView.headerView!.frame, animationControlDelegate: self)
        dopeSheetView.dataSource = tracksDataSource
        rightScrollView.documentView = dopeSheetView
        rightScrollView.contentView.scroll(to: NSPoint())
        
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onScrollViewDidLiveScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: leftScrollView)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onScrollViewDidLiveScroll(_:)), name: NSScrollView.didLiveScrollNotification, object: rightScrollView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onTableViewSelectionDidChange(_:)), name: NSTableView.selectionDidChangeNotification, object: tracksView)
        NotificationCenter.default.addObserver(self, selector: #selector(Self.onTableViewSelectionDidChange(_:)), name: NSTableView.selectionDidChangeNotification, object: dopeSheetView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animationGoToFrame(_ sender: Any, frame: Int) {
        currentAnimationFrame = frame
        NotificationCenter.default.post(Notification(name: .animationCurrentFrameDidChange, object: self))
    }
    
    func animationChangeTrack(_ sender: Any, trackIdentifier: SpriteAssetAnimationTrackIdentifier?) {
        currentAnimationTrackIdentifier = trackIdentifier
        NotificationCenter.default.post(Notification(name: .animationCurrentTrackDidChange, object: self))
    }
    
    func animationChangeState(_ sender: Any, stateName: String?) {
        if isPlaying {
            animationTogglePlay(self)
        }
        
        currentAnimationState = stateName
        NotificationCenter.default.post(Notification(name: .animationCurrentStateDidChange, object: self))
        
        animationChangeTrack(self, trackIdentifier: nil)
        animationGoToFrame(self, frame: 0)
    }
    
    func animationGoToPreviousKey(_ sender: Any) {
        if let prevKey = currentAnimationTrack?.getPrevKey(from: currentAnimationFrame) {
            animationGoToFrame(self, frame: prevKey.frame)
        }
    }
    
    func animationTogglePlay(_ sender: Any) {
        isPlaying = !isPlaying
        NotificationCenter.default.post(Notification(name: .animationPlayingDidChange, object: self))
    }
    
    func animationGoToNextKey(_ sender: Any) {
        if let nextKey = currentAnimationTrack?.getNextKey(from: currentAnimationFrame) {
            animationGoToFrame(self, frame: nextKey.frame)
        }
    }
    
    override func viewWillDraw() {
        splitView.setPosition(300, ofDividerAt: 0)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        splitView.setFrameSize(frame.size)
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 300
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return splitView.frame.width * 2 / 3
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if
            let tableColumn = tableColumn,
            let item = tracksView.dataSource?.tableView?(tableView, objectValueFor: tableColumn, row: row) as? SpriteAssetAnimationTrackIdentifier
        {
            if tableColumn.identifier == .tracks {
                let view = SpriteAssetAnimationTrackNameView(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: item)
                view.delegate = self
                return view
            }
            else if tableColumn.identifier == .dopeSheet {
                return SpriteAssetAnimationDopeSheetCellView(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: item, animationControlDelegate: self)
            }
        }
        return nil
    }
    
    func trackNameView(_ view: SpriteAssetAnimationTrackNameView, requestingTrackRemoval track: SpriteAssetAnimationTrackIdentifier) {
        let alert = NSAlert()
        alert.addButton(withTitle: "Remove Track")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Remove Track"

        let elementName = assetDescription.getElement(uuid: track.elementUUID)!.name
        let trackDescription = "\(elementName) - \(track.trackType.description)"
        alert.informativeText = "Are you sure you want to remove this track?\n\n\(trackDescription)\n\nThis operation cannot be undone."

        alert.alertStyle = .critical

        if alert.runModal() != .alertFirstButtonReturn {
            return
        }

        assetDescription.animationStates[currentAnimationState!]!.animationTracks[track] = nil
        reloadCurrentState()
    }
    
    func reloadCurrentState() {
        tracksView.reloadData()
        dopeSheetView.reloadData()
    }
    
    @objc
    private func onScrollViewDidLiveScroll(_ notif: Notification) {
        if let scrollView = notif.object as? NSScrollView {
            let otherScrollView = scrollView === leftScrollView ? rightScrollView : leftScrollView
            let newOrigin = CGPoint(x: otherScrollView.documentVisibleRect.origin.x, y: scrollView.documentVisibleRect.origin.y)
            otherScrollView.contentView.scroll(to: newOrigin)
        }
    }
    
    @objc
    private func onTableViewSelectionDidChange(_ notif: Notification) {
        if let tableView = notif.object as? NSTableView {
            let isTracksView = tableView === tracksView
            let otherTableView = isTracksView ? dopeSheetView : tracksView
            let selectedRow = tableView.selectedRow
            if selectedRow >= 0 {
                otherTableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
                
                if isTracksView {
                    let item = tracksView.dataSource?.tableView?(tableView, objectValueFor: nil, row: selectedRow) as? SpriteAssetAnimationTrackIdentifier
                    animationChangeTrack(self, trackIdentifier: item)
                }
            }
            else if isTracksView {
                otherTableView.deselectAll(nil)
                animationChangeTrack(self, trackIdentifier: nil)
            }
        }
    }

}
