//
//  ContactManager.swift
//  SnapShare
//
//  Created by Faraz Malik on 09/07/2022.
//

import Foundation
import Contacts

class CNContactsManager {
    
    // MARK: Typealiases
    
    // typealias ContactsFetchCompletionHandler = ([CNContact]?, Error?) -> Void
    
    func storeAllContacts() async throws {
        let store = CNContactStore()
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
        
        let dataManager = ContactsDataManager()
        
        try store.enumerateContacts(with: fetchRequest) { contact, result in
            print(contact.givenName)
            do {
                try dataManager.store(fromPhoneContact: contact)
            } catch {
                print("some shit went wrong")
            }
        }
    }
}
