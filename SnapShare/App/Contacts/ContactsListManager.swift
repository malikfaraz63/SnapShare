//
//  ContactsListManager.swift
//  SnapShare
//
//  Created by Faraz Malik on 13/07/2022.
//

import Foundation

enum ContactItem: String {
    case favourites
    case recents
//    case groups
    case all
}

class ContactsListManager {
    private var allContacts: [Contact]
    private var favouriteContacts: [Contact]
    private var recentContacts: [Contact]
    private var sectionedContacts: [[Contact]]
    private var sections: [ContactItem]
    
    init(withContacts contacts: [Contact]) {
        self.allContacts = contacts
        self.favouriteContacts = []
        self.recentContacts = []
        self.sectionedContacts = [[]]
        self.sections = []
        
        self.favouriteContacts = getFavouriteContacts()
        self.recentContacts = getRecentContacts()
        
        computeSectionedContacts()
    }
    
    private func computeSectionedContacts() {
        sectionedContacts = []
        sections = []
        
        if favouriteContacts.count > 0 {
            sectionedContacts.append(favouriteContacts)
            sections.append(ContactItem.favourites)
        }
        if recentContacts.count > 0 {
            sectionedContacts.append(recentContacts)
            sections.append(ContactItem.recents)
        }
        sectionedContacts.append(allContacts)
        sections.append(ContactItem.all)
    }
    
    public func getSectionedContacts() -> [[Contact]] {
        return sectionedContacts
    }
    
    public func getSections() -> [ContactItem] {
        return sections
    }
    
    public func getContacts(forQuery searchQuery: String) -> [Contact] {
        if searchQuery == "" {
            return allContacts
        }
        
        let filteredContacts = allContacts.filter { contact in
            let name = (contact.givenName + " " + contact.familyName).lowercased()
            
            if name.contains(searchQuery.lowercased()) {
                return true
            } else {
                return false
            }
        }
        
        return filteredContacts
    }
    
    private func getFavouriteContacts() -> [Contact] {
        let favouriteContacts = allContacts.filter { contact in
            return contact.isFavourite
        }
        
        return favouriteContacts
    }
    
    private func getRecentContacts() -> [Contact] {
        let now = Date()
        
        let recentContacts = allContacts.filter { contact in
            if let lastContacted = contact.lastContacted, now.timeIntervalSince(lastContacted) < 604800 {
                return true
            }
            return false
        }
        
        return recentContacts
    }
    
    public func update(withNewContact newContact: Contact) {
        for contact in allContacts {
            if contact == newContact {
                ContactManager.update(contact: contact, withNewContact: newContact)
            }
        }
        
        recentContacts = getRecentContacts()
        favouriteContacts = getFavouriteContacts()
        
        computeSectionedContacts()
    }
}
