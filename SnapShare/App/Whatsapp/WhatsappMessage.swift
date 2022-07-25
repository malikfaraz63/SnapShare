//
//  WhatsappMessage.swift
//  SnapShare
//
//  Created by Faraz Malik on 06/07/2022.
//

import Foundation

struct WhatsappMessage: Codable {
    let messagingProduct: String
    let recipientType: String
    let to: String
    let type: String
    let image: WhatsappImage
}
