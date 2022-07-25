//
//  Contact.swift
//  SnapShare
//
//  Created by Faraz Malik on 07/07/2022.
//

import Foundation
import CoreData

@objc(Contact)
public class Contact: NSManagedObject {
}

extension Contact {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }
    
    @NSManaged public var uuid: String
    @NSManaged public var givenName: String
    @NSManaged public var familyName: String
    @NSManaged public var numberPrefix: String
    @NSManaged public var phoneNumber: String
    @NSManaged public var isSharingEnabled: Bool
    @NSManaged public var lastContacted: Date?
    @NSManaged public var isFavourite: Bool
    @NSManaged public var isPhoneContact: Bool
}

extension Contact {
    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
