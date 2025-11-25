import Foundation
import HotwireNative
import UIKit
import WebKit

final class Navigator: NSObject {
    private lazy var navigationController = UINavigationController()

    private lazy var session: Session = {
        let configuration = WKWebViewConfiguration()
        let session = Session(webViewConfiguration: configuration)
        session.delegate = self
        return session
    }()

    var rootViewController: UIViewController {
        navigationController
    }

    func route(_ url: URL) {
        let viewController = VisitableViewController(url: url)
        session.visit(viewController)
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension Navigator: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        route(proposal.url)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        print("didFailRequestForVisitable: \(error)")

        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }

    func sessionDidLoadWebView(_ session: Session) {
        session.webView.navigationDelegate = self
    }
}

extension Navigator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}
