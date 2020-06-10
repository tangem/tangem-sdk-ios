//
//  PinViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

enum PinViewControllerState {
    case pin1
    case pin2
}

class PinViewController: UIViewController, UITextFieldDelegate {
    
    var completionHandler: (String?) -> Void
    var state: PinViewControllerState
    
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            lblTitle.text = state == .pin1 ? "Enter Access Code" : "Enter Pass Code"
        }
    }
    @IBOutlet weak var btnContinueBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnSecureEntry: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var pinText: UITextField! {
        didSet {
            pinText.delegate = self
        }
    }
    @IBOutlet weak var btnContinue: UIButton! {
        didSet {
            btnContinue.isEnabled = false
        }
    }
    
    init?(coder: NSCoder, state: PinViewControllerState, completionHandler: @escaping (String?) -> Void) {
        self.completionHandler = completionHandler
        self.state = state
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pinText.becomeFirstResponder()
    }
    
    @IBAction func btnActionTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(nil)
        }
    }
    
    @IBAction func btnContinueTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(self.pinText.text)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    @IBAction func btnSecureEntryTapped(_ sender: UIButton) {
        btnSecureEntry.isSelected.toggle()
        pinText.isSecureTextEntry.toggle()
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        btnContinue.isEnabled = !(sender.text?.isEmpty ?? true)
    }
}
