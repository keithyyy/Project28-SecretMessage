//
//  ViewController.swift
//  Project28
//
//  Created by Keith Crooc on 2022-02-07.
//

// CHALLENGE
// 1. Add a Done button as a navigation bar item that causes the app to re-lock immediately rather than waiting for the user to quit. This should only be shown when the app is unlocked. ✅

// 2. Create a password system for your app so that the Touch ID/Face ID fallback is more useful. You'll need to use an alert controller with a text field like we did in project 5, and I suggest you save the password in the keychain ✅

// 3. Go back to project 10 (Names to Faces) and add biometric authentication so the user’s pictures are shown only when they have unlocked the app. You’ll need to give some thought to how you can hide the pictures – perhaps leave the array empty until they are authenticated

import UIKit
// call in our biometric authentication stuff
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet var secret: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        
        title = "Nothing to see here"
        
//        to watch for when our app is has been "backgrounded" AKA closed, user went to homescreen
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        
        
//        challenge 1 - adding a done button.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(lockSecret))
        
        
//        challenge 2 - saving password to keychain
        KeychainWrapper.standard.set("qwer", forKey: "SecretPassword")
    }

    @IBAction func authenticateTapped(_ sender: Any) {
//        when we tap the button, call in our authentication tools
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
//                        error
//                        let ac = UIAlertController(title: "Authentication Failed", message: "Could not verify, please try again", preferredStyle: .alert)
//                        ac.addAction(UIAlertAction(title: "OK", style: .default))
//                        self?.present(ac, animated: true)
                        
                        
//                        challenge 2
                        
                        let acPassword = UIAlertController(title: "Authentication Failed", message: "Could not verify, please enter password", preferredStyle: .alert)
                        acPassword.addTextField()
                        
                        let submitAction = UIAlertAction(title: "Submit", style: .default) {
                            [unowned acPassword] _ in
                            let submittedPassword = acPassword.textFields![0]
                            
                            self?.validatePassword(pass: submittedPassword.text!)
                            
                            
                        }
                        
                        acPassword.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        acPassword.addAction(submitAction)
                        
                        self?.present(acPassword, animated: true)
                        
                    }
                }
            }
        } else {
//            no biometry
            let ac = UIAlertController(title: "Biometry not available", message: "Device is not configured with TouchID or FaceID", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac, animated: true)
        }
        
        
        unlockSecretMessage()
    }
    
//    challenge 2
    func validatePassword(pass: String) {
        
        let password = KeychainWrapper.standard.string(forKey: "SecretPassword")
        
        if pass == password {
            unlockSecretMessage()
        } else {
            let ac = UIAlertController(title: "Authentication Failed", message: "Could not verify, please try again", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
//        so when we tap screen, our view gets adjusted for when the keyboard is in the way.
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, to: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Write your secrets!"
        
//        loading string from keychain is pretty simple.
//        but you must unwrap it first if there is anything there. (could use nil coalescing)
        
        if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secret.text = text
        }
        
//        nil coalescing version
//        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
        
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
//        resignFirstResponse = tells our view input focus should give up that focus AKA we're done editing and keyboard can go away
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
    @objc func lockSecret() {
//        guard secret.isHidden == false else { return }
        
        saveSecretMessage()
        
    }
    
}

