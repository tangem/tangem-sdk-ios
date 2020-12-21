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
    
    private var pinLocalized: String {
        switch state {
        case .pin1: return "pin1".localized
        case .pin2: return "pin2".localized
        case .pin3: return "pin3"
        }
    }
    
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            let format = "pin_change_code_format".localized
            lblTitle.text = String(format: format, pinLocalized)
        }
    }
    
    @IBOutlet weak var btnSecureEntry: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblCard: UILabel!
    @IBOutlet weak var lblError: UILabel!
//    @IBOutlet weak var currentText: UITextField! {
//        didSet {
//            currentText.delegate = self
//            let prefix = "\(Localization.string("pin_change_current_code_format")) "
//            switch state {
//            case .pin1: currentText.placeholder = prefix + Localization.string("pin_placeholder_access")
//            case .pin2: currentText.placeholder = prefix + Localization.string("pin_placeholder_pass")
//            case .pin3: currentText.placeholder = prefix + Localization.string("pin_placeholder_pin3")
//            }
//        }
//    }
    
    @IBOutlet weak var newText: UITextField! {
        didSet {
            newText.delegate = self
            let format = "pin_change_new_code_format".localized
            newText.placeholder = String(format: format, pinLocalized)
        }
    }
    
    @IBOutlet weak var confirmText: UITextField! {
        didSet {
            confirmText.delegate = self
            let format = "pin_set_code_confirm_format".localized
            confirmText.placeholder = String(format: format, pinLocalized)
        }
    }
    
    @IBOutlet weak var btnSave: UIButton! {
        didSet {
            btnSave.isEnabled = false
            btnSave.setTitle("common_save".localized, for: .normal)
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
        newText.becomeFirstResponder()
    }
    
    @IBAction func btnActionTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.completionHandler(.failure(.userCancelled))
        }
    }
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        self.dismiss(animated: true) {
            if /*let currentText = self.currentText.text,*/
                let newText = self.newText.text {
                self.completionHandler(.success((currentPin: "", newPin: newText)))
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
        //currentText.isSecureTextEntry.toggle()
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
        guard /*let current = currentText.text, !current.isEmpty,*/
            let new = newText.text, !new.isEmpty,
            let confirm = confirmText.text, !confirm.isEmpty else {
                lblError.isHidden = true
                return false
        }
        
        if new != confirm {
            lblError.text = "pin_confirm_error_format".localized
            lblError.isHidden = false
            return false
        }
        
        lblError.isHidden = true
        return true
    }
}