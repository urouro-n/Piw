//
//  FeedbackViewController.swift
//  Pics
//
//  Created by Kenta on 6/22/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import RxSwift
import UIKit

class FeedbackViewController: UIViewController {

    @IBOutlet fileprivate weak var textView: UITextView!

    fileprivate lazy var sendButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "送信",
                               style: .plain,
                               target: nil,
                               action: nil)
    }()

    let disposeBag = DisposeBag()

}

// MARK: - View Lifecycles
extension FeedbackViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "フィードバック"

        textView.rx.text
            .map { $0!.characters.count > 0 }
            .bind(to: sendButton.rx.isEnabled)
            .addDisposableTo(disposeBag)

        sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let text = self?.textView.text else { return }

                self?.send(text)
            })
        .addDisposableTo(disposeBag)

        navigationItem.rightBarButtonItem = sendButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
    }

}

// MARK: - Private
fileprivate extension FeedbackViewController {

    func send(_ text: String) {
        let systemVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let info = "SystemVersion: \(systemVersion), Version: \(appVersion), Build: \(bundleVersion)"
        let sendText = text + "\n\n" + info

        // Send to Slack
        var params = "payload={"
        params += "\"username\":\"Piw Feedback\", "
        params += "\"icon_emoji\": \":speech_balloon:\", "
        params += "\"text\":\"" + sendText + "\"}"
        let body = params.data(using: .utf8, allowLossyConversion: false)

        let url = URL(string: AppConfig.Slack.feedbackURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body

        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
            log.debug("error=\(String(describing: error))")

            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            if let data = data {
                let d = String(data: data, encoding: .utf8)
                log.debug("data=\(String(describing: d))")
            }

            DispatchQueue.main.async(execute: { [weak self] in
                if error != nil {
                    self?.app.showFeedback(title: "失敗しました", success: false)
                } else {
                    self?.app.showFeedback()
                    self?.textView.text = ""
                }
            })
        }
        task.resume()
    }

}
