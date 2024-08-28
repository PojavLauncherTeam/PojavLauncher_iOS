import UIKit

public extension UIApplication {
    func currentInternalWindow() -> UIWindow? {
        let role: UISceneSession.Role
        if #available(iOS 16.0, *) {
            role = .windowExternalDisplayNonInteractive
        } else {
            role = .windowExternalDisplay
        }
        let connectedScenes = self.connectedScenes
            .filter({
                $0.session.role != role})
            .compactMap({$0 as? UIWindowScene})
        return connectedScenes.first?
            .keyWindow
    }
}
