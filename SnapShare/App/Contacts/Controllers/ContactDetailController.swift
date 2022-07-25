//
//  ContactDetailController.swift
//  SnapShare
//
//  Created by Faraz Malik on 07/07/2022.
//

import UIKit
import Contacts

class ContactDetailController: UIViewController {

    var contact: Contact?
    
    var delegate: ContactDetailDelegate?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var isFavouriteView: UIImageView!
    @IBOutlet weak var isSharingEnabledView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupContact()
    }
    
    func setupContact() {
        guard let contact = contact else {
            return
        }

        nameLabel.text = contact.givenName + " " + contact.familyName
        phoneNumberLabel.text = "+" + contact.numberPrefix + " " + contact.phoneNumber
        
        updateCheck(for: isFavouriteView, condition: contact.isFavourite)
        updateCheck(for: isSharingEnabledView, condition: contact.isSharingEnabled)
    }
    
    @IBAction func favouriteWasToggled() {
        guard let contact = contact else {
            return
        }

        contact.isFavourite = !contact.isFavourite
        
        updateCheck(for: isFavouriteView, condition: contact.isFavourite)
    }
    
    @IBAction func sharingEnabledWasToggled() {
        guard let contact = contact else {
            return
        }

        contact.isSharingEnabled = !contact.isSharingEnabled
        
        updateCheck(for: isSharingEnabledView, condition: contact.isSharingEnabled)
    }


    func updateCheck(for checkView: UIImageView, condition: Bool) {
        guard let contact = contact else {
            return
        }
        
        if condition {
            checkView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkView.image = UIImage(systemName: "checkmark.circle")
        }
        
        if let delegate = delegate {
            delegate.contactDidChange(contact: contact)
        }
    }
    
    @IBAction func deleteContact() {
        guard let contact = contact else {
            return
        }
        
        if let delegate = delegate {
            delegate.contactWasDeleted(contact: contact)
        }
        
        dismiss(animated: true)
    }
}

protocol ContactDetailDelegate {
    func contactDidChange(contact: Contact)
    func contactWasDeleted(contact: Contact)
}
