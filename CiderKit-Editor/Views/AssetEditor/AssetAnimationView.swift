import AppKit
import CiderKit_Engine

extension NSUserInterfaceItemIdentifier {
    
    static let tracks = NSUserInterfaceItemIdentifier(rawValue: "tracks")
    static let dopeSheet = NSUserInterfaceItemIdentifier(rawValue: "dopeSheet")
    
}

final class AssetAnimationView: NSView, NSSplitViewDelegate, NSTableViewDelegate, AssetAnimationControlDelegate, AssetAnimationTrackNameViewDelegate {
    
    private let splitView: NSSplitView
    private let headerView: AssetAnimationTracksHeaderView
    
    private let leftScrollView: NSScrollView
    private let rightScrollView: NSScrollView

    private var tracksDataSource: NSTableViewDataSource? = nil
    private let tracksView: NSTableView
    private var dopeSheetView: NSTableView
    
    private(set) var isPlaying: Bool = false
    
    private(set) var currentAnimationFrame: UInt = 0
    
    private(set) var currentAnimationName: String? = nil {
        didSet {
            if currentAnimationName != oldValue {
                tracksDataSource = AssetAnimationTracksDataSource(assetDescription: assetDescription, animationName: currentAnimationName)
                tracksView.dataSource = tracksDataSource
                dopeSheetView.dataSource = tracksDataSource
                
                NotificationCenter.default.post(Notification(name: .animationCurrentAnimationDidChange, object: self))
            }
        }
    }
    
    private(set) var currentAnimationTrackIdentifier: AssetAnimationTrackIdentifier? = nil
    
    var currentAnimationTrack: AssetAnimationTrack? {
        guard let currentAnimationName, let currentAnimationTrackIdentifier else { return nil }
        return assetDescription.animations[currentAnimationName]?.animationTracks[currentAnimationTrackIdentifier]
    }
    
    var currentAnimationFrameCount: UInt {
        guard let currentAnimationName else { return 0 }
        
        let animation = assetDescription.animations[currentAnimationName]!
        var maxFrame: UInt = 0
        for (_, track) in animation.animationTracks {
            if let lastKey = track.lastKey {
                maxFrame = max(maxFrame, lastKey.frame + 1)
            }
        }
        return maxFrame
    }
    
    var assetDescription: AssetDescription {
        didSet {
            if assetDescription !== oldValue {
                currentAnimationName = assetDescription.animations.keys.sorted().first
                tracksDataSource = AssetAnimationTracksDataSource(assetDescription: assetDescription, animationName: currentAnimationName)
                headerView.assetDescription = assetDescription
                tracksView.dataSource = tracksDataSource
                dopeSheetView.dataSource = tracksDataSource
            }
        }
    }
    
    init(assetDescription: AssetDescription) {
        self.assetDescription = assetDescription
        
        splitView = NSSplitView()

        leftScrollView = NSScrollView()
        rightScrollView = NSScrollView()
        
        tracksView = NSTableView()
        dopeSheetView = NSTableView()
        
        currentAnimationName = assetDescription.animations.keys.sorted().first
        headerView = AssetAnimationTracksHeaderView(frame: tracksView.headerView!.frame, assetDescription: assetDescription, animationName: currentAnimationName)
        
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
        
        tracksDataSource = AssetAnimationTracksDataSource(assetDescription: assetDescription, animationName: currentAnimationName)

        tracksView.intercellSpacing = NSZeroSize
        tracksView.style = .plain
        tracksView.rowHeight = 24
        tracksView.delegate = self
        let tracksColumn = NSTableColumn(identifier: .tracks)
        tracksColumn.title = "Animation"
        tracksView.addTableColumn(tracksColumn)
        tracksView.allowsColumnResizing = false
        tracksView.allowsColumnReordering = false
        tracksView.allowsColumnSelection = false
        tracksView.allowsEmptySelection = true
        tracksView.allowsMultipleSelection = false
        tracksView.usesAlternatingRowBackgroundColors = true
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
        dopeSheetView.headerView = AssetAnimationDopeSheetHeaderView(frame: dopeSheetView.headerView!.frame, animationControlDelegate: self)
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
    
    func animationGoToFrame(_ sender: Any, frame: UInt) {
        currentAnimationFrame = frame
        NotificationCenter.default.post(Notification(name: .animationCurrentFrameDidChange, object: self))
    }
    
    func animationChangeTrack(_ sender: Any, trackIdentifier: AssetAnimationTrackIdentifier?) {
        currentAnimationTrackIdentifier = trackIdentifier
        NotificationCenter.default.post(Notification(name: .animationCurrentTrackDidChange, object: self))
    }
    
    func animationChangeAnimation(_ sender: Any, animationName: String?) {
        if isPlaying {
            animationTogglePlay(self)
        }
        
        currentAnimationName = animationName
        NotificationCenter.default.post(Notification(name: .animationCurrentAnimationDidChange, object: self))
        
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
        DispatchQueue.main.async {
            self.splitView.setFrameSize(self.frame.size)
        }
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 300
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return splitView.frame.width * CGFloat(2.0 / 3.0)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if
            let tableColumn = tableColumn,
            let item = tracksView.dataSource?.tableView?(tableView, objectValueFor: tableColumn, row: row) as? AssetAnimationTrackIdentifier
        {
            if tableColumn.identifier == .tracks {
                let view = AssetAnimationTrackNameView(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: item)
                view.delegate = self
                return view
            }
            else if tableColumn.identifier == .dopeSheet {
                return AssetAnimationDopeSheetCellView(tableView: tableView, row: row, assetDescription: assetDescription, trackIdentifier: item, animationControlDelegate: self)
            }
        }
        return nil
    }
    
    func trackNameView(_ view: AssetAnimationTrackNameView, requestingTrackRemoval track: AssetAnimationTrackIdentifier) {
        let alert = NSAlert()
        alert.addButton(withTitle: "Remove Track")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Remove Track"

        let elementName = assetDescription.getElement(uuid: track.elementUUID)!.name
        let trackDescription = "\(elementName) - \(track.trackType.displayName)"
        alert.informativeText = "Are you sure you want to remove this track?\n\n\(trackDescription)\n\nThis operation cannot be undone."

        alert.alertStyle = .critical

        if alert.runModal() != .alertFirstButtonReturn {
            return
        }

        assetDescription.animations[currentAnimationName!]!.animationTracks[track] = nil
        reloadCurrentAnimation()
    }
    
    func reloadCurrentAnimation() {
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
                    let item = tracksView.dataSource?.tableView?(tableView, objectValueFor: nil, row: selectedRow) as? AssetAnimationTrackIdentifier
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
