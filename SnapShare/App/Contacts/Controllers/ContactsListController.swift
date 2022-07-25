//
//  ContactsListController.swift
//  SnapShare
//
//  Created by Faraz Malik on 07/07/2022.
//

import UIKit
import Contacts

class ContactsListController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ContactCellDelegate, SettingsDelegate, ContactDetailDelegate, NewContactDelegate {
    
    @IBOutlet weak var contactsTable: UITableView!
    @IBOutlet weak var contactsSearchField: UITextField!
    
    var sectionedContacts: [[Contact]]?
    var sections: [ContactItem]?
    var contacts: [Contact]?
    
    var searchContacts: [Contact]?
    var isSearchingForContacts = false
    
    let dataManager = ContactsDataManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        contactsTable.clipsToBounds = true
        contactsTable.layer.cornerRadius = 10
        
        contactsTable.dataSource = self
        contactsTable.delegate = self
        
        contactsSearchField.delegate = self
        
        viewDidAppear(false)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let retrievedContacts = retrieveContacts() else { return }
        contacts = retrievedContacts
        
        let listManager = ContactsListManager(withContacts: retrievedContacts)
        
        sectionedContacts = listManager.getSectionedContacts()
        sections = listManager.getSections()

        contactsTable.reloadData()
    }
    
    // MARK: Contacts Setup
    func retrieveContacts() -> [Contact]? {
        do {
            return try dataManager.retrieveAllContacts()
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        return nil
    }
    
    // MARK: Text field delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isSearchingForContacts = true
        contactsFieldChanged(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isSearchingForContacts = false
        
        contactsTable.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if contactsSearchField.isEditing {
            let _ = textFieldShouldReturn(contactsSearchField)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        isSearchingForContacts = false
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func contactsFieldChanged(_ sender: UITextField) {
        guard let contacts = contacts else {
            return
        }
                
        let listManager = ContactsListManager(withContacts: contacts)
        searchContacts = contacts

        if let query = sender.text {
            searchContacts = listManager.getContacts(forQuery: query)
        }
        
        contactsTable.reloadData()
    }
    
    // MARK: View Delegates
    
    func contactsWereChanged() {
        viewDidAppear(false)
    }
    
    func contactDidChange(contact: Contact) {
        do {
            try dataManager.update(withNewContact: contact)
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        viewDidAppear(false)
    }
    
    func contactWasDeleted(contact: Contact) {
        do {
            try dataManager.delete(contact: contact)
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        viewDidAppear(false)
    }
    
    func newContactWasAdded(withGivenName givenName: String, familyName: String, phoneNumber: String) {
        do {
            try dataManager.storeNewContact(withGivenName: givenName, familyName: familyName, phoneNumber: phoneNumber)
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        viewDidAppear(false)
    }
    
    // MARK: Cell Delegate
    
    func contactSelectionDidChange(to contactSelectionState: Bool, forContact contact: Contact) {
        contact.isSharingEnabled = contactSelectionState
        do {
            try dataManager.update(withNewContact: contact)
        } catch let error {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
        
        contactsTable.reloadData()
    }
    
    // MARK: Table Delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contactCell = tableView.dequeueReusableCell(withIdentifier: "ContactCell") as? ContactCell else { fatalError() }
        guard let sectionedContacts = sectionedContacts else {
            return contactCell
        }
        
        let contact: Contact
        
        if isSearchingForContacts {
            guard let searchContacts = searchContacts else {
                return contactCell
            }
            
            contact = searchContacts[indexPath.row]
        } else {
            contact = sectionedContacts[indexPath.section][indexPath.row]
        }
        
        contactCell.nameLabel.text = contact.givenName + " " + contact.familyName
        contactCell.contactSelectionSwitch.isOn = contact.isSharingEnabled
        
        contactCell.contact = contact
        contactCell.delegate = self
        
        return contactCell
    }
    
    // MARK: Table Data Source
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchingForContacts {
            guard let searchContacts = searchContacts else {
                return 0
            }

            return searchContacts.count
        }
        
        guard let sectionedContacts = sectionedContacts else {
            return 0
        }
        
        return sectionedContacts[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchingForContacts {
            return "RESULTS"
        }
        
        guard let sections = sections else {
            return nil
        }

        return sections[section].rawValue
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchingForContacts {
            return 1
        }
        
        guard let sectionedContacts = sectionedContacts else {
            return 0
        }

        return sectionedContacts.count
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showContact" {
            guard let contactDetailController = segue.destination as? ContactDetailController else { return }
            guard let path = contactsTable.indexPathForSelectedRow else { return }
            guard let sectionedContacts = sectionedContacts else { return }
            
            let contact = sectionedContacts[path.section][path.row]
            
            contactDetailController.contact = contact
            contactDetailController.delegate = self
        } else if segue.identifier == "showSettings" {
            guard let contactDetailController = segue.destination as? SettingsController else { return }
            
            contactDetailController.delegate = self
        } else if segue.identifier == "addContact" {
            guard let newContactController = segue.destination as? NewContactViewController else { return }
            
            newContactController.delegate = self
        }
    }

}
