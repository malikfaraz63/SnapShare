//
//  SettingsController.swift
//  SnapShare
//
//  Created by Faraz Malik on 14/07/2022.
//

import UIKit

class SettingsController: UITableViewController {
    
    var delegate: SettingsDelegate?
    let dataManager = ContactsDataManager()
    
    @IBOutlet weak var phoneContactsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tryEnablingDeleteButton()
    }
    
    func tryEnablingDeleteButton() {
        if dataManager.hasPhoneContactsStored() {
            phoneContactsButton.isEnabled = true
        } else {
            phoneContactsButton.isEnabled = false
        }
    }

    @IBAction func addPhoneContacts() {
        if !dataManager.hasPhoneContactsStored() {
            Task.init {
                do {
                    try await CNContactsManager().storeAllContacts()
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        
        if let delegate = delegate {
            delegate.contactsWereChanged()
        }
        
        tryEnablingDeleteButton()
        
        dismiss(animated: true)
    }
    
    @IBAction func removePhoneContacts() {
        do {
            try dataManager.deletePhoneContacts()
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
    }
}

protocol SettingsDelegate {
    func contactsWereChanged()
}
