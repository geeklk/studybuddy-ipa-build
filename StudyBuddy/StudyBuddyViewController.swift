
import UIKit
import WebKit

final class StudyBuddyViewController: UIViewController,
                                     WKNavigationDelegate,
                                     WKUIDelegate {

    private let appURL = URL(string: "https://mindpulse.ai.studio/")!

    private var webView: WKWebView!

    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let loadingStack = UIStackView()
    private let retryButton = UIButton(type: .system)
    private let errorView = UIView()
    private let refreshControl = UIRefreshControl()

    override var prefersStatusBarHidden: Bool {
        false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .red

        configureWebView()
        configureLoadingView()
        configureErrorView()

        loadStudyBuddy()
    }

    // MARK: - WebView

    private func configureWebView() {

        let contentController = WKUserContentController()

        let viewportScript = """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');

            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                (document.head || document.documentElement).appendChild(meta);
            }

            var content = meta.getAttribute('content') ||
                'width=device-width, initial-scale=1.0';

            content = content.replace(/viewport-fit\\s*=\\s*[^,]+/g, '');
            content += ', viewport-fit=cover';

            meta.setAttribute('content', content);
        })();
        """

        let viewportInjection = WKUserScript(
            source: viewportScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        contentController.addUserScript(viewportInjection)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self

        webView.allowsBackForwardNavigationGestures = true
        webView.pageZoom = 1.0

        // Prevent automatic safe-area spacing.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero

        // Pull to refresh.
        webView.scrollView.refreshControl = refreshControl
        refreshControl.addTarget(
            self,
            action: #selector(refreshPage),
            for: .valueChanged
        )

        view.addSubview(webView)

        // IMPORTANT: Fill the complete screen.
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Loading View

    private func configureLoadingView() {

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Loading Study Buddy…"
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabel

        loadingStack.addArrangedSubview(spinner)
        loadingStack.addArrangedSubview(statusLabel)

        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 12

        view.addSubview(loadingStack)

        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Error View

    private func configureErrorView() {

        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = .systemBackground
        errorView.isHidden = true

        let title = UILabel()
        title.text = "Couldn't load Study Buddy"
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textAlignment = .center

        let message = UILabel()
        message.text = "Check your internet connection and try again."
        message.font = .systemFont(ofSize: 15)
        message.textColor = .secondaryLabel
        message.textAlignment = .center
        message.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font =
            .systemFont(ofSize: 16, weight: .semibold)

        retryButton.addTarget(
            self,
            action: #selector(loadStudyBuddy),
            for: .touchUpInside
        )

        let stack = UIStackView(
            arrangedSubviews: [title, message, retryButton]
        )

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16

        errorView.addSubview(stack)
        view.addSubview(errorView)

        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.leadingAnchor.constraint(
                greaterThanOrEqualTo: errorView.leadingAnchor,
                constant: 28
            ),

            stack.trailingAnchor.constraint(
                lessThanOrEqualTo: errorView.trailingAnchor,
                constant: -28
            ),

            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor)
        ])
    }

    // MARK: - Loading

    @objc private func loadStudyBuddy() {

        errorView.isHidden = true
        loadingStack.isHidden = false

        spinner.startAnimating()

        let request = URLRequest(
            url: appURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 45
        )

        webView.load(request)
    }

    @objc private func refreshPage() {
        webView.reload()
    }

    private func finishLoading() {

        spinner.stopAnimating()
        loadingStack.isHidden = true
        refreshControl.endRefreshing()
    }

    // MARK: - Navigation

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.scheme == "https" || url.scheme == "http" {

            if url.host == appURL.host ||
                url.host?.hasSuffix(".ai.studio") == true {

                decisionHandler(.allow)

            } else if navigationAction.navigationType == .linkActivated {

                UIApplication.shared.open(url)
                decisionHandler(.cancel)

            } else {

                decisionHandler(.allow)
            }

        } else if ["mailto", "tel", "sms"].contains(url.scheme ?? "") {

            UIApplication.shared.open(url)
            decisionHandler(.cancel)

        } else {

            decisionHandler(.allow)
        }
    }

    // MARK: - Popup Windows

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {

        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url else {
            return nil
        }

        if url.host == appURL.host ||
            url.host?.hasSuffix(".ai.studio") == true {

            webView.load(URLRequest(url: url))

        } else {

            UIApplication.shared.open(url)
        }

        return nil
    }

    // MARK: - Camera and Microphone Permissions

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {

        decisionHandler(
            origin.host == appURL.host ? .grant : .deny
        )
    }

    // MARK: - Navigation Status

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {

        errorView.isHidden = true
        spinner.startAnimating()
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {

        finishLoading()
        errorView.isHidden = true
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {

        finishLoading()

        if (error as NSError).code != NSURLErrorCancelled {
            errorView.isHidden = false
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {

        finishLoading()

        if (error as NSError).code != NSURLErrorCancelled {
            errorView.isHidden = false
        }
    }
}
