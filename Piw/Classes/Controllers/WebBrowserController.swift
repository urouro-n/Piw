//
//  WebBrowserController.swift
//  Pics
//
//  Created by Kenta on 2017/06/08.
//  Copyright © 2017 UROURO. All rights reserved.
//

import EasyTipView
import Kingfisher
import ImageViewer
import MBProgressHUD
import TinyConstraints
import Reachability
import RealmSwift
import RxSwift
import RxWebKit
import SwiftDate
import UIKit
import WebKit

class WebBrowserController: UIViewController {

    @IBOutlet fileprivate weak var toolbar: UIToolbar!
    @IBOutlet fileprivate weak var downloadButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var goBackButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var goForwardButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var pageUpButton: UIBarButtonItem!
    @IBOutlet fileprivate weak var pageDownButton: UIBarButtonItem!

    fileprivate lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        contentController.addUserScript(URLBlocker.blockerScript())
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.processPool = processPool

        let v = WKWebView(frame: CGRect.zero, configuration: configuration)
        v.navigationDelegate = self
        v.uiDelegate = self

        v.rx.url
            .subscribe(onNext: { [weak self] url in
                self?.titleView.urlTextField.text = url?.absoluteString
                self?.titleView.isSecure = (url?.scheme == "https")
            })
            .addDisposableTo(self.disposeBag)

        v.rx.canGoBack
            .subscribe(onNext: { [weak self] can in
                self?.goBackButton.isEnabled = can
            })
            .addDisposableTo(self.disposeBag)

        v.rx.canGoForward
            .subscribe(onNext: { [weak self] can in
                self?.goForwardButton.isEnabled = can
            })
            .addDisposableTo(self.disposeBag)

        v.rx.loading
            .subscribe(onNext: { [weak self] loading in
                UIApplication.shared.isNetworkActivityIndicatorVisible = loading
                self?.titleView.isReloading = loading

                if loading {
                    self?.progressView.alpha = 1.0
                } else {
                    if let progressView = self?.progressView {
                        if progressView.alpha == 1.0 {
                            UIView.animate(withDuration: 0.3) {
                                progressView.alpha = 0.0
                            }
                        }
                    }
                }
            })
            .addDisposableTo(self.disposeBag)

        v.rx.estimatedProgress
            .map { Float($0) }
            .subscribe(onNext: { [weak self] progress in
                self?.progressView.progress = progress
            })
            .addDisposableTo(self.disposeBag)

        return v
    }()

    fileprivate lazy var titleView: WebBrowserTitleView = {
        let v = WebBrowserTitleView.create(delegate: self)

        v.cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.titleView.isEditing = false
            })
            .addDisposableTo(self.disposeBag)

        v.reloadButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.webView.reload()
            })
            .addDisposableTo(self.disposeBag)

        v.stopButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.webView.stopLoading()
            })
            .addDisposableTo(self.disposeBag)

        return v
    }()

    fileprivate lazy var progressView: UIProgressView = {
        return UIProgressView(progressViewStyle: .bar)
    }()

    fileprivate lazy var actionButton: UIBarButtonItem = {
        let b = UIBarButtonItem(barButtonSystemItem: .action,
                                target: nil,
                                action: nil)

        b.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }

                guard let url = self.webView.url else {
                    log.warning("URL is nil.")
                    return
                }

                let newBookmarkActivity = BrowserNewBookmarkActivity()
                let activityController = UIActivityViewController(activityItems: [url],
                                                                  applicationActivities: [newBookmarkActivity])
                activityController.excludedActivityTypes = [
                    .addToReadingList
                ]
                self.present(activityController, animated: true, completion: nil)
            })
            .addDisposableTo(self.disposeBag)

        return b
    }()

    fileprivate lazy var closeButton: UIBarButtonItem = {
        let b = UIBarButtonItem(title: "閉じる", style: .plain, target: nil, action: nil)

        b.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .addDisposableTo(self.disposeBag)

        return b
    }()

    fileprivate let disposeBag = DisposeBag()

    var url: URL = URL(string: "https://google.com")!

    fileprivate var items: [DataItem] = []
    fileprivate var galleryController: GalleryViewController?

    class func navigationController(url: String? = nil) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Web", bundle: nil)
        // swiftlint:disable:next force_cast
        let nav = storyboard.instantiateInitialViewController() as! UINavigationController

        if let url = url {
            // swiftlint:disable:next force_cast
            let controller = nav.topViewController as! WebBrowserController
            controller.url = URL(string: url)!
        }

        return nav
    }

}

// MARK: - View Lifecycles
extension WebBrowserController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.insertSubview(webView, belowSubview: toolbar)
        webView.leading(to: view)
        webView.trailing(to: view)
        webView.top(to: view, topLayoutGuide.bottomAnchor)
        webView.bottomToTop(of: toolbar)

        if let nav = navigationController {
            progressView.frame = CGRect(x: 0.0,
                                        y: nav.navigationBar.frame.size.height - 2.0,
                                        width: nav.navigationBar.frame.size.width,
                                        height: 2.0)
            nav.navigationBar.addSubview(progressView)
        }

        navigationItem.titleView = titleView

        configureNavigationBar(whenInitialize: true)
        setUpButtons()
        setUpActions()

        let request = URLRequest(url: url)
        webView.load(request)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !UserDefaultsHandler.ShowedLoadImagesTooltip.get() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let `self` = self else { return }

                var preferences = EasyTipView.globalPreferences
                preferences.animating.showInitialTransform = CGAffineTransform(translationX: 0.0, y: -16.0)
                preferences.positioning.maxWidth = 250.0
                EasyTipView.show(animated: true,
                                 forItem: self.downloadButton,
                                 withinSuperview: self.view,
                                 text: "このページの画像を読み込み",
                                 preferences: preferences,
                                 delegate: self)
            }
        }
    }

    var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                   FileManager.SearchPathDomainMask.userDomainMask,
                                                   true)[0]
    }

}

// MARK: - WKNavigationDelegate
extension WebBrowserController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.absoluteString.contains("//itunes.apple.com/") {
            UIApplication.shared.open(url,
                                      options: [UIApplicationOpenURLOptionUniversalLinksOnly: false],
                                      completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        if !url.absoluteString.hasPrefix("http://") &&
            !url.absoluteString.hasPrefix("https://") &&
            !url.absoluteString.hasPrefix("about:") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url,
                                          options: [UIApplicationOpenURLOptionUniversalLinksOnly: false],
                                          completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }

        switch navigationAction.navigationType {
        case .linkActivated:
            // target=blank
            if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }
        case .backForward, .formResubmitted, .formSubmitted, .other, .reload:
            break
        }

        decisionHandler(.allow)
    }

}

// MARK: - WKUIDelegate
extension WebBrowserController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .default, handler: { _ in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler(true)
        }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "キャンセル", style: .default, handler: { _ in
            completionHandler(nil)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let textField = alert.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler(nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - WebBrowserTitleViewDelegate
extension WebBrowserController: WebBrowserTitleViewDelegate {

    func webBrowserTitleViewDidBeginEditing(_ view: WebBrowserTitleView) {
        configureNavigationBar()
    }

    func webBrowserTitleViewDidEndEditing(_ view: WebBrowserTitleView, enteredURL: String) {
        configureNavigationBar()

        let urlString: String
        if !enteredURL.hasPrefix("http://") && !enteredURL.hasPrefix("https://") {
            urlString = "http://" + enteredURL
        } else {
            urlString = enteredURL
        }

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            titleView.urlTextField.text = webView.url?.absoluteString
        }
    }

}

// MARK: - PreviewDataSource
extension WebBrowserController: PreviewDataSource {

    func itemCount() -> Int {
        return items.count
    }

    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return items[index].galleryItem
    }

    func previewItem(at index: Int) -> DataItem {
        return items[index]
    }

}

extension WebBrowserController: EasyTipViewDelegate {

    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        UserDefaultsHandler.ShowedLoadImagesTooltip.set(true)
    }

}

// MARK: - Private
fileprivate extension WebBrowserController {

    func configureNavigationBar(whenInitialize: Bool = false) {
        if titleView.isEditing {
            navigationItem.setLeftBarButtonItems(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
        } else {
            navigationItem.setLeftBarButtonItems([closeButton],
                                                 animated: (whenInitialize) ? false : true)
            navigationItem.setRightBarButtonItems([actionButton],
                                                  animated: (whenInitialize) ? false : true)
        }
    }

    func setUpButtons() {
        let buttonSize: CGSize = CGSize(width: 30.0, height: 30.0)
        goBackButton.image = UIImage.ionicon(with: .iosArrowLeft,
                                             textColor: UIColor.black,
                                             size: buttonSize)
        goForwardButton.image = UIImage.ionicon(with: .iosArrowRight,
                                                textColor: UIColor.black,
                                                size: buttonSize)
        pageUpButton.image = UIImage.ionicon(with: .iosArrowThinUp,
                                             textColor: UIColor.black,
                                             size: buttonSize)
        pageDownButton.image = UIImage.ionicon(with: .iosArrowThinDown,
                                               textColor: UIColor.black,
                                               size: buttonSize)
        downloadButton.image = UIImage.ionicon(with: .images,
                                               textColor: UIColor.black,
                                               size: buttonSize)
    }

    func setUpActions() {
        downloadButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let r = Reachability()!
                if !UserDefaultsHandler.EnableMobileNetwork.get() &&
                    r.currentReachabilityStatus == .reachableViaWWAN {
                    self?.app.alertDisablingMobileNetwork()
                    return
                }

                self?.preview()
            })
            .addDisposableTo(disposeBag)

        goBackButton.rx.tap
            .subscribe(onNext: { [weak self] in
                if let `self` = self {
                    if self.webView.canGoBack {
                        self.webView.goBack()
                    }
                }
            })
            .addDisposableTo(self.disposeBag)

        goForwardButton.rx.tap
            .subscribe(onNext: { [weak self] in
                if let `self` = self {
                    if self.webView.canGoForward {
                        self.webView.goForward()
                    }
                }
            })
            .addDisposableTo(self.disposeBag)

        pageUpButton.rx.tap
            .subscribe(onNext: { [weak self] in
                // Scroll to top
                let script = "window.scrollTo(0,0);"
                self?.webView.evaluateJavaScript(script)
            })
            .addDisposableTo(disposeBag)

        pageDownButton.rx.tap
            .subscribe(onNext: { [weak self] in
                // Scroll to bottom
                // swiftlint:disable:next line_length
                let script = "var next = document.querySelector('[rel=\"next\"]'); (next && window.scrollY < next.offsetTop-20.0) ? window.scrollTo(0,next.offsetTop-20.0) : window.scrollTo(0,document.body.scrollHeight);"
                self?.webView.evaluateJavaScript(script)
            })
            .addDisposableTo(disposeBag)
    }

    func preview() {
        MBProgressHUD.showAdded(to: self.view, animated: true)

        self.webView.app.parseImageURLs(completion: { [weak self] URLs in
            guard let `self` = self else { return }
            MBProgressHUD.hide(for: self.view, animated: true)

            guard let URLs = URLs else {
                log.debug("Nothing URLs.")
                return
            }

            log.debug("URLs=\(URLs)")

            self.items.removeAll()
            for urlString in URLs {
                guard let url = URL(string: urlString) else {
                    continue
                }

                var fixedURL: URL = url
                if url.scheme == nil && url.host == nil {
                    if let webScheme = self.webView.url?.scheme,
                        let webHost = self.webView.url?.host,
                        let baseURL = URL(string: webScheme + "://" + webHost),
                        let tempURL = URL(string: url.absoluteString, relativeTo: baseURL) {
                        fixedURL = tempURL
                    }
                }

                let item = GalleryItem.image(fetchImageBlock: { completion in
                    ImageDownloader
                        .default
                        .downloadImage(with: fixedURL,
                                       options: [.cacheOriginalImage],
                                       progressBlock: nil) { image, _, _, _ in
                                        completion(image)
                    }
                })
                self.items.append(DataItem(imageURL: fixedURL, rawURL: url, galleryItem: item))
            }

            if self.items.count == 0 {
                let alert = UIAlertController(title: "画像がありませんでした", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            let preview = PreviewViewController.create(items: self.items, dataSource: self)
            if let webUrl = self.webView.url {
                preview.url = webUrl
            }
            self.presentImageGallery(preview)
        })
    }

}
