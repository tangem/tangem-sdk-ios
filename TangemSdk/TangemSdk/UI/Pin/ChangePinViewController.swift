//
//  ChangePinViewController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

class ChangePinViewController: UIViewController, UITextFieldDelegate {
    var completionHandler: CompletionResult<(currentPin: String, newPin: String)>
    let state: PinViewControllerState
    let cardId: String?
    var validationTimer: Timer? = nil
    
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            switch state {
            case .pin1: lblTitle.text = Localization.string("pin_title_pin1")
            case .pin2: lblTitle.text = Localization.string("pin_title_pin2")
            case .pin3: lblTitle.text = Localization.string("pin_title_pin3")
            }
        }
    }
    
    @IBOutlet weak var btnSecureEntry: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblCard: UILabel!
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var currentText: UITextField! {
        didSet {
            currentText.delegate = self
            let prefix = "\(Localization.string("changepin_placeholder_current")) "
            switch state {
            case .pin1: currentText.placeholder = prefix + Localization.string("pin_placeholder_access")
            case .pin2: currentText.placeholder = prefix + Localization.string("pin_placeholder_pass")
            case .pin3: currentText.placeholder = prefix + Localization.string("pin_placeholder_pin3")
            }
        }
    }
    
    @IBOutlet weak var newText: UITextField! {
        didSet {
            newText.delegate = self
            let prefix = "\(Localization.string("changepin_placeholder_new")) "
            switch state {
            case .pin1: newText.placeholder = prefix + Localization.string("pin_placeholder_access")
            case .pin2: newText.placeholder = prefix + Localization.string("pin_placeholder_pass")
            case .pin3: newText.placeholder = prefix + Localization.string("pin_placeholder_pin3")
            }
        }
    }
    
    @IBOutlet weak var confirmText: UITextField! {
        didSet {
            confirmText.delegate = self
            let prefix = "\(Localization.string("changepin_placeholder_confirm")) "
            switch state {
            case .pin1: confirmText.placeholder = prefix + Localization.string("pin_placeholder_access")
            case .pin2: confirmText.placeholder = prefix + Localization.string("pin_placeholder_pass")
            case .pin3: confirmText.placeholder = prefix + Localization.string("pin_placeholder_pin3")
            }
        }
    }
    
    @IBOutlet weak var btnSave: UIButton! {
        didSet {
            btnSave.isEnabled = false
            btnSave.setTitle(Localization.string("common_save"), for: .normal)
        }
    }
    
    init?(coder: NSCoder, state: PinViewControllerState, cardId: String? = nil, completionHandler: @escaping CompletionResult<(currentPin: String, newPin: String)>) {
        self.completionHandler = completionHandler
        self.state = state
        self.cardId = cardId
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
        lblCard.text = cardId
        currentText.becomeFirstResponder()
    }
    
    @IBAction func btnActionTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(.failure(.userCancelled))
        }
    }
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            if let currentText = self.currentText.text,
                let newText = self.newText.text {
                self.completionHandler(.success((currentPin: currentText, newPin: newText)))
            } else {
                self.completionHandler(.failure(.unknownError))
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    @IBAction func btnSecureEntryTapped(_ sender: UIButton) {
        btnSecureEntry.isSelected.toggle()
        currentText.isSecureTextEntry.toggle()
        newText.isSecureTextEntry.toggle()
        confirmText.isSecureTextEntry.toggle()
    }
    
    @IBAction func textFieldChanged(_ sender: UITextField) {
        validationTimer?.invalidate()
        validationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            
            self.btnSave.isEnabled = self.validateInput()
        }
    }
    
    private func validateInput() -> Bool {
        guard let current = currentText.text, !current.isEmpty,
            let new = newText.text, !new.isEmpty,
            let confirm = confirmText.text, !confirm.isEmpty else {
                lblError.isHidden = true
                return false
        }
        
        if new != confirm {
            lblError.text = Localization.string("changepin_error_mismatch")
            lblError.isHidden = false
            return false
        }
        
        lblError.isHidden = true
        return true
    }
}
