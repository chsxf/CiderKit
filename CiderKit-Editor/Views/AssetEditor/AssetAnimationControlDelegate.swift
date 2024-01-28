import CiderKit_Engine

extension Notification.Name {
    
    static let animationCurrentFrameDidChange = Notification.Name(rawValue: "animationCurrentFrameDidChange")
    static let animationCurrentTrackDidChange = Notification.Name(rawValue: "animationCurrentTrackDidChange")
    static let animationCurrentStateDidChange = Notification.Name(rawValue: "animationCurrentStateDidChange")
    static let animationPlayingDidChange = Notification.Name(rawValue: "animationPlayingDidChange")
    
}

protocol AssetAnimationControlDelegate: AnyObject {

    var currentAnimationFrame: UInt { get }
    var currentAnimationStateName: String? { get }
    var currentAnimationTrackIdentifier: AssetAnimationTrackIdentifier? { get }
    var currentAnimationTrack: AssetAnimationTrack? { get }
    var isPlaying: Bool { get }
    var currentAnimationStateFrameCount: UInt { get }
    
    func animationGoToFrame(_ sender: Any, frame: UInt)
    func animationChangeTrack(_ sender: Any, trackIdentifier: AssetAnimationTrackIdentifier?)
    func animationChangeState(_ sender: Any, stateName: String?)
    
    func animationGoToPreviousKey(_ sender: Any)
    func animationTogglePlay(_ sender: Any)
    func animationGoToNextKey(_ sender: Any)
    
}
