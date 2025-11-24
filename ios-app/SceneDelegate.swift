import UIKit
import Turbo

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var navigationController: UINavigationController!

    // The main session for managing Turbo visits
    private lazy var session: Session = {
        let session = Session()
        session.delegate = self
        return session
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the main window
        window = UIWindow(windowScene: windowScene)

        // Create navigation controller
        navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true

        // Set as root view controller
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        // Start with the dashboard
        visit(url: Configuration.baseURL)
    }

    // MARK: - Navigation

    private func visit(url: URL, action: VisitAction = .advance) {
        let viewController = WebViewController(url: url)
        viewController.delegate = self

        if action == .advance {
            navigationController.pushViewController(viewController, animated: true)
        } else if action == .replace {
            navigationController.viewControllers = [ viewController ]
        }

        session.visit(viewController)
    }
}

// MARK: - SessionDelegate

extension SceneDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        visit(url: proposal.url, action: proposal.options.action)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        print("❌ Visit failed: \(error.localizedDescription)")

        let alert = UIAlertController(
            title: "Connection Error",
            message: "Could not connect to the server. Make sure Rails is running on \(Configuration.baseURL.absoluteString)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }

    func sessionWebViewProcessDidTerminate(_ session: Session) {
        session.reload()
    }
}

// MARK: - WebViewControllerDelegate

extension SceneDelegate: WebViewControllerDelegate {
    func webViewController(_ controller: WebViewController, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // For localhost development, accept all certificates
        // In production, implement proper certificate validation
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
