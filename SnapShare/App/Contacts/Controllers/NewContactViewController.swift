//
//  NewContactViewController.swift
//  SnapShare
//
//  Created by Faraz Malik on 18/07/2022.
//

import UIKit

class NewContactViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var familyNameTextField: UITextField!
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    @IBOutlet weak var addContactButton: UIButton!
    
    var firstNameIsValid = false
    var familyNameIsValid = false
    var phoneNumberIsValid = false
    
    var delegate: NewContactDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        addContactButton.isEnabled = false
    }
    
    @IBAction func addContact() {
        guard let delegate = delegate else {
            return
        }
        
        guard let givenName = firstNameTextField.text else {
            return
        }
        guard let familyName = familyNameTextField.text else {
            return
        }
        guard let phoneNumber = phoneNumberTextField.text else {
            return
        }
        
        delegate.newContactWasAdded(withGivenName: givenName, familyName: familyName, phoneNumber: phoneNumber)
        
        dismiss(animated: true)
    }
    
    @IBAction func cancelContact() {
        dismiss(animated: true)
    }
    
    @IBAction func firstNameEditingChanged() {
        firstNameIsValid = nameFieldWasValid(firstNameTextField)
        tryEnablingContactButton()
    }
    
    @IBAction func familyNameEditingChanged() {
        familyNameIsValid = nameFieldWasValid(familyNameTextField)
        tryEnablingContactButton()
    }
    
    @IBAction func phoneNumberEditingChanged() {
        phoneNumberIsValid = getIsPhoneNumberValid()
        tryEnablingContactButton()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let _ = textFieldShouldReturn(textField)
    }
        
    func tryEnablingContactButton() {
        if phoneNumberIsValid && firstNameIsValid && familyNameIsValid {
            addContactButton.isEnabled = true
        } else {
            addContactButton.isEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func nameFieldWasValid(_ textField: UITextField) -> Bool {
        guard let _ = textField.text else {
            return false
        }  
        
        return true
    }
    
    func getIsPhoneNumberValid() -> Bool {
        guard let phoneNumber = phoneNumberTextField.text else {
            return false
        }
        
        return isValidNumber(phoneNumber)
    }
    
    // MARK: Helper
    
    private func isValidNumber(_ phoneNumber: String) -> Bool {
        let expression = try! NSRegularExpression(pattern: #"(0|(\+?44))? ?7\d{3} ?\d{6}"#)
        
        let range = NSRange(location: 0, length: phoneNumber.count)
        
        return expression.firstMatch(in: phoneNumber, range: range) != nil
    }
}

protocol NewContactDelegate {
    func newContactWasAdded(withGivenName givenName: String, familyName: String, phoneNumber: String)
}
