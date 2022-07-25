//
//  ContactManager.swift
//  SnapShare
//
//  Created by Faraz Malik on 13/07/2022.
//

import Foundation


class ContactManager {
    
    public static func update(contact: Contact, withNewContact newContact: Contact) {
        contact.givenName = newContact.givenName
        contact.phoneNumber = newContact.phoneNumber
        contact.numberPrefix = newContact.numberPrefix
        contact.isSharingEnabled = newContact.isSharingEnabled
        contact.lastContacted = newContact.lastContacted
        contact.isFavourite = newContact.isFavourite
        contact.isPhoneContact = newContact.isPhoneContact
    }
}
