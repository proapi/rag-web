import UIKit
import WebKit
import Turbo

protocol WebViewControllerDelegate: AnyObject {
    func webViewController(_ controller: WebViewController, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

class WebViewController: UIViewController {
    weak var delegate: WebViewControllerDelegate?

    private let url: URL

    private lazy var visitableView: VisitableView = {
        let view = VisitableView()
        return view
    }()

    // MARK: - Initialization

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(visitableView)
        visitableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            visitableView.topAnchor.constraint(equalTo: view.topAnchor),
            visitableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visitableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visitableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Configure web view
        configureWebView()
    }

    private func configureWebView() {
        visitableView.webView.navigationDelegate = self

        // Set custom user agent
        visitableView.webView.customUserAgent = Configuration.userAgent

        // Allow inline media playback
        visitableView.webView.configuration.allowsInlineMediaPlayback = true
    }
}

// MARK: - Visitable

extension WebViewController: Visitable {
    func visitableDidRender() {
        title = visitableView.webView.title
    }

    func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }

    func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
    }

    func visitableViewForVisitable() -> VisitableView {
        return visitableView
    }

    func visitableURL() -> URL {
        return url
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.webViewController(self, didReceiveAuthenticationChallenge: challenge, completionHandler: completionHandler)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Handle external links (optional - open in Safari)
        if let url = navigationAction.request.url,
           !url.absoluteString.starts(with: Configuration.baseURL.absoluteString) {
            // External link - could open in Safari
            // UIApplication.shared.open(url)
            // decisionHandler(.cancel)
            // return
        }

        decisionHandler(.allow)
    }
}
