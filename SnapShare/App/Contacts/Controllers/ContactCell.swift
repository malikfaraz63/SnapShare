//
//  ContactCell.swift
//  SnapShare
//
//  Created by Faraz Malik on 07/07/2022.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet weak var contactSelectionSwitch: UISwitch!
    @IBOutlet weak var nameLabel: UILabel!
    var delegate: ContactCellDelegate?
    var contact: Contact?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func contactSelectionDidChange(_ sender: UISwitch) {
        guard let delegate = delegate else {
            return
        }
        guard let contact = contact else {
            return
        }
        
        delegate.contactSelectionDidChange(to: sender.isOn, forContact: contact)
    }
}

protocol ContactCellDelegate {
    func contactSelectionDidChange(to contactSelectionState: Bool, forContact contact: Contact)
}
