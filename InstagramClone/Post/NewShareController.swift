//
//  SharePhotoController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/27/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class NewSharePhotoController:  UICollectionViewController, UINavigationControllerDelegate {
    
    
    
    
    var currentChannel: String?{
        didSet {
            
        }
    }
    
    var anonymBool: Bool = false
    
    private var selectedPostImage: UIImage?
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.layer.masksToBounds = true
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        return button
    }()
    
    
    let radioButton: UISwitch = {
        let switchB = UISwitch()
        
        
        
        return switchB
    }()
    
    
    
    let anonymLabel: UILabel = {
        let label = UILabel()
        label.text = "Anonym"
        
        return label
    }()
    
    private let textView: PlaceholderTextView = {
        let tv = PlaceholderTextView()
        tv.placeholderLabel.text = "Add Text..."
        tv.placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.autocorrectionType = .no
        return tv
    }()
    
    let switchOnOff = UISwitch(frame:CGRect(x: 150, y: 150, width: 0, height: 0))
    
    private let loaderIndicator: UIActivityIndicatorView = {
        
        
        let loaderIndicator = UIActivityIndicatorView()
        loaderIndicator.hidesWhenStopped = true
        
        return loaderIndicator
        
    }()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //       f loaderIndicator.startAnimating()
        
        collectionView?.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        
        switchOnOff.addTarget(self, action: #selector(switchStateDidChange(_:)), for: .valueChanged)
        switchOnOff.setOn(false, animated: false)
        self.view.addSubview(switchOnOff)
        
        
        layoutViews()
        
        
        
        
    }
    
    @objc func switchStateDidChange(_ sender:UISwitch){
        if (sender.isOn == true){
            print("UISwitch state is now ON")
            anonymBool = true
        }
        else{
            print("UISwitch state is now Off")
            anonymBool = false
        }
    }
    
    private func layoutViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 200)
        
        containerView.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, width: 84, height: 84)
        
        containerView.addSubview(textView)
        textView.anchor(top: containerView.topAnchor, left: plusPhotoButton.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingLeft: 4)
        
        containerView.addSubview(loaderIndicator)
        loaderIndicator.anchor(top: textView.bottomAnchor,left: containerView.leftAnchor, right: containerView.rightAnchor)
        
        //        containerView.addSubview(radioButton)
        //        radioButton.anchor(top: textView.bottomAnchor, right: view.rightAnchor, paddingTop: 5, paddingRight: 5 )
        
        switchOnOff.anchor(top: textView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 5, paddingRight: 5)
        containerView.addSubview(anonymLabel)
        anonymLabel.anchor(top: textView.bottomAnchor, bottom: switchOnOff.bottomAnchor, right: switchOnOff.leftAnchor, paddingRight: 5)
    }
    
    
    @objc private func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleShare() {
        
        let postImage = selectedPostImage
        guard let caption = textView.text else { return }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        textView.isUserInteractionEnabled = false
        
            print("create Post")
        
        if postImage != nil {
           
            Database.database().createPost(anonym: anonymBool, channel: currentChannel!,  withImage: postImage!, caption: caption) { (err) in
                if err != nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.textView.isUserInteractionEnabled = true
                    return
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
            
        else{
            Database.database().createPost(anonym: anonymBool, channel: currentChannel!, caption: caption) { (err) in
                if err != nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.textView.isUserInteractionEnabled = true
                    return
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                self.dismiss(animated: true, completion: nil)
            }
            
        }

        
        
        
        
        
        
        
        
        
    }
    
}


extension NewSharePhotoController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            selectedPostImage = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
            selectedPostImage = originalImage
        }
        plusPhotoButton.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        plusPhotoButton.layer.borderWidth = 0.5
        dismiss(animated: true, completion: nil)
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}


