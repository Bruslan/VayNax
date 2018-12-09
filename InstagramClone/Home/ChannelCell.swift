//
//  ChannelCell.swift
//  InstagramClone
//
//  Created by Bruslan on 06.12.18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

class ChannelCell: UITableViewCell {

    static var cellId = "channelCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private let userProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
//        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
//        iv.layer.borderWidth = 0.5
        iv.isUserInteractionEnabled  = true
        return iv
    }()
    
    let channelsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
//        label.text = "Vay Channel"
        return label
    }()
    
    private let likeCounter2: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = .gray
        label.text = "800 Beiträge"
        return label
    }()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupView(){

        addSubview(userProfileImageView)
        userProfileImageView.layer.cornerRadius = 40 / 2
        userProfileImageView.anchor(left: leftAnchor ,paddingLeft: 40, width: 50, height: 50)
        userProfileImageView.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor).isActive = true
        userProfileImageView.image = UIImage(named: "kisspng-chechnya-chechen-republic-of-ichkeria-gray-wolf-ch-5b2a60e64743d6.7342923415295039742919")
        
        addSubview(channelsLabel)
        
        channelsLabel.anchor(top: userProfileImageView.topAnchor, left: userProfileImageView.rightAnchor, bottom: userProfileImageView.bottomAnchor, paddingLeft: 10)
//        addSubview(likeCounter2)
//        likeCounter2.anchor(top: likeCounter.bottomAnchor, left: userProfileImageView.rightAnchor, paddingLeft: 10)
    }
}
