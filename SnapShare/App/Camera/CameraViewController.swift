//
//  ViewController.swift
//  SnapShare
//
//  Created by Faraz Malik on 03/07/2022.
//

import UIKit
import AVKit

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var session: AVCaptureSession?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    let dataManager = ContactsDataManager()
    
    var sharingEnabledContacts: [Contact]?
    
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var shutterCircle: UIView!
    @IBOutlet weak var shutterCircleWidth: NSLayoutConstraint!
    @IBOutlet weak var shutterCircleHeight: NSLayoutConstraint!
    @IBOutlet weak var shutterCircleBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sharingToggle: UISwitch!
    
    @IBOutlet weak var previewView: UIView!
    
    let accessToken = "EAAvhnQnjxZBYBAC891vl4ajdzZBHU4rIRWZAyoUVYgs2HjeLd0yh8WjZC1nA95fjqWmtpjozQX29dfgR2Sz867qmbIaSilPba5Y7AZBiOXdiTNSSASVLhv6nWrfUir9NmFPv17z5zvczv60KpNjOfCFDAK0tQ5Qu0K2ouyni7rO14NHr4ZAwcfxN2fYMq3eoX0FjKdGI9OBAZDZD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("another modification to remote")
        
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
        
        shutterCircle.layer.cornerRadius = 34
        shutterCircle.clipsToBounds = true
        
        shutterButton.layer.cornerRadius = shutterButton.frame.size.width / 2
        shutterButton.clipsToBounds = true
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.white.cgColor
        shutterButton.setTitle("", for: .normal)
        shutterButton.setTitle("", for: .selected)
        
        view.bringSubviewToFront(shutterButton)
        
        sharingToggle.isOn = false
        
        checkCameraPermissions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            sharingEnabledContacts = try dataManager.retrieveSharingEnabledContacts()
        } catch {
            print(error.localizedDescription)
            // FIXME: Handle error
        }
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            self.setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera() {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                session.startRunning()
                self.session = session
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func didTakePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        
        shutterCircleWidth.constant = 68
        shutterCircleHeight.constant = 68
        shutterCircleBottomConstraint.constant = 56
        shutterCircle.layer.cornerRadius = 34
        
        self.previewView.alpha = 0
        
        UIView.animate(withDuration: 0.05, animations: {
            self.view.layoutIfNeeded()
        }) {_ in
            UIView.animate(withDuration: 0.05) {
                self.previewView.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func didTouchDown() {
        shutterCircleWidth.constant = 60
        shutterCircleHeight.constant = 60
        shutterCircleBottomConstraint.constant = 60
        shutterCircle.layer.cornerRadius = 30
        
        UIView.animate(withDuration: 0.05) {
            self.view.layoutIfNeeded()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if !sharingToggle.isOn {
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        guard let image = UIImage(data: data) else { return }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }
                
        let imageClient = WhatsappImageAPIClient()
        guard let sharingEnabledContacts = self.sharingEnabledContacts else {
            return
        }
        
        imageClient.postWhatsappImage(withAccessToken: accessToken, imageData: imageData) { image, error in
            if let image = image {
                for contact in sharingEnabledContacts {
                    self.sendImage(toContact: contact, image: image)
                }
            } else if let error = error {
                self.handleWhatsappImageError(with: error)
            }
        }
        
        for contact in sharingEnabledContacts {
            do {
                try dataManager.update(withNewContact: contact)
            } catch let error {
                print(error.localizedDescription)
                // FIXME: Handle error
                print("\(contact.givenName) failed to save")
            }
        }
    }
    
    func sendImage(toContact contact: Contact, image: WhatsappImage) {
        let phoneNumber = contact.numberPrefix + contact.phoneNumber
        let message = WhatsappMessage(messagingProduct: "whatsapp", recipientType: "individual", to: phoneNumber, type: "image", image: image)
        let messageClient = WhatsappMessageAPIClient()
        
        messageClient.sendWhatsappMessage(withAccessToken: accessToken, message: message) { info, error in
            if let info = info {
                print(info)
                contact.lastContacted = Date()
            } else if let error = error {
                self.handleWhatsappMessageError(with: error)
            }
        }
    }
    
    // MARK: Error handling
    
    func handleWhatsappMessageError(with error: Error) {
        print("message error")
        switch error {
        case WhatsappMessageError.invalidURL:
            print("URL was invalid")
        case WhatsappMessageError.responseUnsuccessful(let statusCode):
            print("Unsuccessful with HTTP code \(statusCode)")
        case WhatsappMessageError.jsonParsingFailure:
            print("JSON parse failure")
        case WhatsappMessageError.jsonEncodingFailure:
            print("JSON encoding failure")
        case WhatsappMessageError.requestFailed:
            print("Request failed")
        default:
            print(error.localizedDescription)
        }
    }
    
    func handleWhatsappImageError(with error: Error) {
        print("image error")
        switch error {
        case WhatsappImageError.invalidURL:
            print("URL was invalid")
        case WhatsappImageError.responseUnsuccessful(let statusCode):
            print("Unsuccessful with HTTP code \(statusCode)")
        case WhatsappImageError.jsonParsingFailure:
            print("JSON parse failure")
        case WhatsappImageError.requestFailed:
            print("Request failed")
        default:
            print(error.localizedDescription)
        }
    }
}

