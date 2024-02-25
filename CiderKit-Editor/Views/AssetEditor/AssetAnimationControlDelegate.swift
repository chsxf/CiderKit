import CiderKit_Engine

extension Notification.Name {
    
    static let animationCurrentFrameDidChange = Notification.Name(rawValue: "animationCurrentFrameDidChange")
    static let animationCurrentTrackDidChange = Notification.Name(rawValue: "animationCurrentTrackDidChange")
    static let animationCurrentAnimationDidChange = Notification.Name(rawValue: "animationCurrentAnimationDidChange")
    static let animationPlayingDidChange = Notification.Name(rawValue: "animationPlayingDidChange")
    
}

protocol AssetAnimationControlDelegate: AnyObject {

    var currentAnimationFrame: UInt { get }
    var currentAnimationName: String? { get }
    var currentAnimationTrackIdentifier: AssetAnimationTrackIdentifier? { get }
    var currentAnimationTrack: AssetAnimationTrack? { get }
    var isPlaying: Bool { get }
    var currentAnimationFrameCount: UInt { get }
    
    func animationGoToFrame(_ sender: Any, frame: UInt)
    func animationChangeTrack(_ sender: Any, trackIdentifier: AssetAnimationTrackIdentifier?)
    func animationChangeAnimation(_ sender: Any, animationName: String?)
    
    func animationGoToPreviousKey(_ sender: Any)
    func animationTogglePlay(_ sender: Any)
    func animationGoToNextKey(_ sender: Any)
    
}
