//
//  ContactsDataManager.swift
//  SnapShare
//
//  Created by Faraz Malik on 12/07/2022.
//

import Foundation
import UIKit
import Contacts


enum ContactsDataError: Error {
    case contactsNotFound
    case contactsNotStored
    case contactNotStored
    case contactNotUpdated
    case contactNotDeleted
    case phoneContactsNotDeleted
}

// manager CRUD of contact data, including updating statuses of contacts from sharingEnabled, other edited details or the import of contacts.

class ContactsDataManager {
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    // MARK: Create
    
    public func store(fromPhoneContacts contacts: [CNContact]) throws {        
        for contact in contacts {
            try store(fromPhoneContact: contact)
        }
    }
    
    public func store(fromPhoneContact contact: CNContact) throws {
        let phoneNumbers = contact.phoneNumbers
        var validPhoneNumber: String?
        for entity in phoneNumbers {
            let phoneNumber = entity.value.stringValue
            if isValidNumber(phoneNumber) {
                validPhoneNumber = getValidPhoneNumber(from: phoneNumber)
            }
        }
        
        if let validPhoneNumber = validPhoneNumber {
            let element = Contact(context: context)

            element.uuid = UUID().uuidString
            element.givenName = contact.givenName
            element.familyName = contact.familyName
            element.phoneNumber = validPhoneNumber
            element.numberPrefix = "44"
            element.isSharingEnabled = false
            element.lastContacted = nil
            element.isFavourite = false
            element.isPhoneContact = true
            
            do {
                try context.save()
            } catch {
                throw ContactsDataError.contactNotStored
            }
        }
    }
    
    public func storeNewContact(withGivenName givenName: String, familyName: String, phoneNumber: String) throws {
        let element = Contact(context: context)
        
        element.uuid = UUID().uuidString
        element.givenName = givenName
        element.familyName = familyName
        element.numberPrefix = "44"
        element.phoneNumber = getValidPhoneNumber(from: phoneNumber)
        element.isPhoneContact = false
        element.isSharingEnabled = false
        element.lastContacted = nil
        element.isFavourite = false
        
        do {
            try context.save()
        } catch {
            throw ContactsDataError.contactNotStored
        }
    }
        
    // MARK: Retrieve
    
    public func retrieveAllContacts() throws -> [Contact] {
        let contacts = try context.fetch(Contact.fetchRequest())
        
        if contacts.count == 0 {
            throw ContactsDataError.contactsNotFound
        }
        
        return contacts
    }
    
    public func hasPhoneContactsStored() -> Bool {
        do {
            let contacts = try retrieveAllContacts()
            
            for contact in contacts {
                if contact.isPhoneContact {
                    return true
                }
            }
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        
        return false
    }
    
    public func retrieveSharingEnabledContacts() throws -> [Contact] {
        let contacts = try retrieveAllContacts()
        
        let sharingEnabledContacts = contacts.filter { contact in
            return contact.isSharingEnabled
        }
        
        return sharingEnabledContacts
    }
    
    // MARK: Update
    
    public func update(withNewContact newContact: Contact) throws {
        let contacts = try context.fetch(Contact.fetchRequest())
        
        if contacts.count == 0 {
            throw ContactsDataError.contactsNotFound
        }
        
        for contact in contacts {
            if contact == newContact {
                ContactManager.update(contact: contact, withNewContact: newContact)
            }
        }
        
        do {
            try context.save()
        } catch {
            throw ContactsDataError.contactNotUpdated
        }
    }
    
    // MARK: Delete
    
    public func delete(contact: Contact) throws {
        context.delete(contact)
        
        do {
            try context.save()
        } catch {
            throw ContactsDataError.contactNotDeleted
        }
    }
    
    public func deletePhoneContacts() throws {
        let contacts = try context.fetch(Contact.fetchRequest())
        
        let phoneContacts = contacts.filter { element in
            return element.isPhoneContact
        }
        
        phoneContacts.forEach { contact in
            context.delete(contact)
        }
                
        do {
            try context.save()
        } catch {
            throw ContactsDataError.phoneContactsNotDeleted
        }
    }
    
    // MARK: Helper
    
    private func isValidNumber(_ phoneNumber: String) -> Bool {
        let expression = try! NSRegularExpression(pattern: #"(0|(\+?44))? ?7\d{3} ?\d{6}"#)
        
        let range = NSRange(location: 0, length: phoneNumber.count)
        
        return expression.firstMatch(in: phoneNumber, range: range) != nil
    }
    
    private func getValidPhoneNumber(from phoneNumber: String) -> String {
        var sevenWasFound = false
        var normalisedNumber = ""
        
        for character in phoneNumber {
            if sevenWasFound {
                if character != " " {
                    normalisedNumber.append(character)
                }
            } else {
                if character == "7" {
                    normalisedNumber.append(character)
                    sevenWasFound = true
                }
            }
        }
        
        return normalisedNumber
    }
}
