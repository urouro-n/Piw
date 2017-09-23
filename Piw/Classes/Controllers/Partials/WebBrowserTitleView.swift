//
//  WebBrowserTitleView.swift
//  Pics
//
//  Created by Kenta on 2017/06/15.
//  Copyright © 2017年 UROURO. All rights reserved.
//

import IoniconsKit
import UIKit

protocol WebBrowserTitleViewDelegate: class {
    func webBrowserTitleViewDidBeginEditing(_ view: WebBrowserTitleView)
    func webBrowserTitleViewDidEndEditing(_ view: WebBrowserTitleView, enteredURL: String)
}

class WebBrowserTitleView: UIView {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet fileprivate weak var secureButton: UIButton!
    @IBOutlet private weak var cancelButtonWidthConstraint: NSLayoutConstraint!

    lazy var reloadButton: UIButton = {
        let side = self.urlTextField.frame.size.height - 4.0
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0,
                              y: 0.0,
                              width: self.urlTextField.frame.size.height,
                              height: self.urlTextField.frame.size.height)
        button.setImage(UIImage.ionicon(with: .iosRefreshEmpty,
                                        textColor: UIColor.app.darkGray,
                                        size: CGSize(width: side, height: side)),
                        for: .normal)
        return button
    }()

    lazy var stopButton: UIButton = {
        let side = self.urlTextField.frame.size.height - 4.0
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0,
                              y: 0.0,
                              width: self.urlTextField.frame.size.height,
                              height: self.urlTextField.frame.size.height)
        button.setImage(UIImage.ionicon(with: .iosCloseEmpty,
                                        textColor: UIColor.app.darkGray,
                                        size: CGSize(width: side,
                                                     height: side)),
                        for: .normal)
        return button
    }()

    var isReloading: Bool = false {
        didSet {
            if isReloading {
                urlTextField.rightView = stopButton
            } else {
                urlTextField.rightView = reloadButton
            }
        }
    }

    var isSecure: Bool = false {
        didSet {
            secureButton.setTitle(isSecure ? "S" : "I", for: .normal)
        }
    }

    var isEditing: Bool = false {
        didSet {
            if isEditing {
                if let delegate = self.delegate {
                    delegate.webBrowserTitleViewDidBeginEditing(self)
                }

                cancelButton.alpha = 0.0
                cancelButtonWidthConstraint.constant = 85.0
                setNeedsLayout()

                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    self?.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    self?.cancelButton.alpha = 1.0
                })

            } else {
                endEditing(true)

                if let delegate = delegate, let text = urlTextField.text {
                    delegate.webBrowserTitleViewDidEndEditing(self, enteredURL: text)
                }

                cancelButton.alpha = 0.0
                cancelButtonWidthConstraint.constant = 0.0
                setNeedsLayout()

                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    self?.layoutIfNeeded()
                }, completion: { [weak self] _ in
                    self?.cancelButton.alpha = 1.0
                })
            }
        }
    }

    weak var delegate: WebBrowserTitleViewDelegate?

    class func create(URL: String? = nil, delegate: WebBrowserTitleViewDelegate? = nil) -> WebBrowserTitleView {
        let view: WebBrowserTitleView = Bundle.main.loadNibNamed("WebBrowserTitleView",
                                                                 owner: self,
                                                                 options: nil)![0] as! WebBrowserTitleView
        // swiftlint:disable:previous force_cast

        view.urlTextField.text = URL
        view.urlTextField.delegate = view
        view.delegate = delegate

        return view
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let leftPadding = UIView(frame: CGRect(x: 0.0,
                                               y: 0.0,
                                               width: 8.0,
                                               height: urlTextField.frame.size.height))
        urlTextField.leftView = leftPadding
        urlTextField.leftViewMode = .always
        urlTextField.rightViewMode = .unlessEditing
        urlTextField.rightView = reloadButton
        urlTextField.layer.cornerRadius = 5.0

        isSecure = false
        isEditing = false
        isReloading = false
    }

}

extension WebBrowserTitleView: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        isEditing = true

        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument,
                                                              to: textField.endOfDocument)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else {
            return false
        }
        guard text.characters.count > 0 else {
            return false
        }

        isEditing = false

        return true
    }

}
