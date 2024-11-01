import CiderKit_Engine

extension Notification.Name {
    
    static let animationCurrentFrameDidChange = Self.init(rawValue: "animationCurrentFrameDidChange")
    static let animationCurrentTrackDidChange = Self.init(rawValue: "animationCurrentTrackDidChange")
    static let animationCurrentAnimationDidChange = Self.init(rawValue: "animationCurrentAnimationDidChange")
    static let animationPlayingDidChange = Self.init(rawValue: "animationPlayingDidChange")

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
