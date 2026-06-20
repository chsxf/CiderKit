#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct UIHelpers {

    @MainActor
    public static func fatalErrorAlert(titled title: String, message: String, buttonLabel: String = "Ok") {
        #if os(macOS)
        let alert = NSAlert()
        alert.informativeText = title
        alert.messageText = message
        alert.addButton(withTitle: buttonLabel)
        let _ = alert.runModal()
        #else
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonLabel, style: .default))
        self.findViewController()?.present(alert, animated: true, completion: nil)
        #endif
    }

}
