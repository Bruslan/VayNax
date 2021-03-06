//
//  HomePostCell.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

protocol HomePostCellDelegate {
    func didTapComment(post: Post)
    func didTapUser(user: User)
    func didTapOptions(post: Post)
    func didLike(for cell: UICollectionViewCell)
    func didDislike(for cell: UICollectionViewCell)
    func didBookMark(for: UICollectionViewCell)
    func didSave(for cell: UICollectionViewCell)

    
    
}

class HomePostCell: UICollectionViewCell {
    
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
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        return button
    }()
    
    private lazy var dislikeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDislike), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: -1, y: -1);
        return button
    }()
    
    
    private lazy var savebutton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-speichern-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-sprechblase-mit-punkten-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    private let commentCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private let sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-speichern-50").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBookMark), for: .touchUpInside)
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
        label.textColor = .green
        
        return label
    }()
    
    private let dislikeCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .red
        return label
    }()
    
    static var cellId = "homePostCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        
        self.backgroundColor = .white
        addSubview(header)
        header.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor)
        header.delegate = self
        
        addSubview(captionLabel)
        captionLabel.anchor(top: header.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding, paddingBottom: 10, paddingRight: padding)
        
        addSubview(photoImageView)
        photoImageView.anchor(top: captionLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 10)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        setupActionButtons()

        addSubview(likeCounter)
        likeCounter.anchor(top: likeButton.bottomAnchor, left: likeButton.leftAnchor, right: likeButton.rightAnchor, paddingTop: padding )
        
      
        addSubview(commentCounter)
        commentCounter.anchor(top: commentButton.bottomAnchor, left: commentButton.leftAnchor, paddingTop: padding)
        
        addSubview(dislikeCounter)
        dislikeCounter.anchor(top: dislikeButton.bottomAnchor, left: dislikeButton.leftAnchor,  right: dislikeButton.rightAnchor, paddingTop: padding)

    }
    
    private func setupActionButtons() {
        let stackView = UIStackView(arrangedSubviews: [likeButton, dislikeButton, commentButton, savebutton])
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.spacing = 16
        addSubview(stackView)
        
        stackView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding, paddingRight: padding)
        
        addSubview(bookmarkButton)
        bookmarkButton.anchor(top: photoImageView.bottomAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding, paddingRight: padding)
        
    }
    
    private func configurePost() {
        guard let post = post else { return }
        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        header.user = post.user
        header.postTimeStamp.text = timeAgoDisplay
        
        photoImageView.loadImage(urlString: post.imageUrl)
        likeButton.setImage(post.likedByCurrentUser == true ? #imageLiteral(resourceName: "icons8-schaumfinger-filled-50").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
        dislikeButton.setImage(post.dislikedByCurrentUser == true ? #imageLiteral(resourceName: "icons8-schaumfinger-filled-50").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icons8-schaumfinger-50").withRenderingMode(.alwaysOriginal), for: .normal)
        bookmarkButton.setImage(post.bookMarkedByCurrentUser == true ? #imageLiteral(resourceName: "icons8-stecknadel-filled-50").withRenderingMode(.alwaysOriginal) : #imageLiteral(resourceName: "icons8-stecknadel-50").withRenderingMode(.alwaysOriginal), for: .normal)
        
        
        
        setLikes(to: post.likes)
        setCommentCount(to: post.commentCount)
        setDislikes(to: post.dislikes)
        setupAttributedCaption()
    }
    
    private func setupAttributedCaption() {
        guard let post = self.post else { return }
        
        let attributedText = NSMutableAttributedString(string: "\(post.caption)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
//        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
//        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4)]))
//
//        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
//        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.gray]))
        captionLabel.attributedText = attributedText
    }
    
    private func setLikes(to value: Int) {
        if value <= 0 {
            likeCounter.text = ""
        } else if value == 1 {
            likeCounter.text = "1"
        } else {
            likeCounter.text = "\(value)"
        }
    }
    
    private func setCommentCount(to value: Int) {
        if value <= 0 {
            commentCounter.text = ""
        } else if value == 1 {
            commentCounter.text = "1 Comment"
        } else {
            commentCounter.text = "\(value) Comments"
        }
    }
    
    
    private func setDislikes(to value: Int) {
        if value <= 0 {
            dislikeCounter.text = ""
        } else if value == 1 {
            dislikeCounter.text = "1"
        } else {
            dislikeCounter.text = "\(value)"
        }
    }
    
    let impact = UIImpactFeedbackGenerator()
    
    @objc private func handleLike() {
        impact.impactOccurred()
        delegate?.didLike(for: self)
        
    }
    @objc private func handleDislike() {
        impact.impactOccurred()
        delegate?.didDislike(for: self)
        
    }
    
    @objc private func handleSave(){
        print("save was pressed")
        impact.impactOccurred()
        delegate?.didSave(for: self)
    }
    
    @objc private func handleBookMark(){
        impact.impactOccurred()
        print("did BookMark")
        delegate?.didBookMark(for: self)
    }
    
    @objc private func handleComment() {
        impact.impactOccurred()
        guard let post = post else { return }
        delegate?.didTapComment(post: post)
    }
}

//MARK: - HomePostCellHeaderDelegate

extension HomePostCell: HomePostCellHeaderDelegate {
    
    func didTapUser() {
        guard let user = post?.user else { return }
        delegate?.didTapUser(user: user)
    }
    
    func didTapOptions() {
        guard let post = post else { return }
        delegate?.didTapOptions(post: post)
    }
}








