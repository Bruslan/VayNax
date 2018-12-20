//
//  HomePostCell.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

class HomePostCellNoImage: UICollectionViewCell {
    
    var delegate: HomePostCellDelegate?
    
    var post: Post? {
        didSet {
            configurePost()
        }
    }
    
    let header = HomePostCellHeader()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let padding: CGFloat = 12
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-sprechblase-mit-punkten-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    private let sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    private lazy var bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-stecknadel-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookMark), for: .touchUpInside)
        return button
    }()
    
    private let likeCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    static var cellId = "homePostCellId2"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(header)
        addSubview(captionLabel)
        addSubview(likeCounter)
        
        self.backgroundColor = .white
        header.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor)
        header.delegate = self


        setupActionButtons()
        
        
        likeCounter.anchor(top: likeButton.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding)
        
       
        captionLabel.anchor(top: header.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding - 6, paddingLeft: padding, paddingRight: padding)
        
    }
    
    private func setupActionButtons() {
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton])
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.spacing = 16
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = .gray
        
        addSubview(seperatorView)
        seperatorView.alpha = 0.5
        
        seperatorView.anchor(top:captionLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 8, paddingBottom: 8, height: 0.5)
        addSubview(stackView)
        stackView.anchor(top: seperatorView.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding)
        
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: seperatorView.bottomAnchor, right: rightAnchor, paddingTop: padding, paddingRight: padding)
    }
    
    private func configurePost() {
        guard let post = post else { return }
        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        header.user = post.user
        header.postTimeStamp.text = timeAgoDisplay
        
        likeButton.setImage(post.likedByCurrentUser == true ? #imageLiteral(resourceName: "icons8-schaumfinger-filled-50").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
          bookmarkButton.setImage(post.bookMarkedByCurrentUser == true ? #imageLiteral(resourceName: "icons8-stecknadel-filled-50").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icons8-stecknadel-50").withRenderingMode(.alwaysOriginal), for: .normal)
        setLikes(to: post.likes)
        setupAttributedCaption()
    }
    
    private func setupAttributedCaption() {
        guard let post = self.post else { return }
        
        let attributedText = NSMutableAttributedString(string: "\(post.caption)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        captionLabel.attributedText = attributedText
    }
    
    private func setLikes(to value: Int) {
        if value <= 0 {
            likeCounter.text = ""
        } else if value == 1 {
            likeCounter.text = "1 halal"
        } else {
            likeCounter.text = "\(value) halals"
        }
    }
    let impact = UIImpactFeedbackGenerator()
    
    
    @objc private func handleBookMark(){
        print("did BookMark")
        impact.impactOccurred()
        delegate?.didBookMark(for: self)
    }
    
    @objc private func handleLike() {
        impact.impactOccurred()
        delegate?.didLike(for: self)
    }
    
    @objc private func handleComment() {
        impact.impactOccurred()
        guard let post = post else { return }
        delegate?.didTapComment(post: post)
    }
}

//MARK: - HomePostCellHeaderDelegate

extension HomePostCellNoImage: HomePostCellHeaderDelegate {
    
    func didTapUser() {
        guard let user = post?.user else { return }
        delegate?.didTapUser(user: user)
    }
    
    func didTapOptions() {
        guard let post = post else { return }
        delegate?.didTapOptions(post: post)
    }
}









