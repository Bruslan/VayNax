//
//  Post.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import Foundation

struct Post {
    
    var id: String
    
    let user: User
    let imageUrl: String
    let caption: String
    let creationDate: Date
    let channelName :String
    let uid: String
    let realUID: String
    
    
    var likes: Int = 0
    var dislikes: Int = 0
    var likedByCurrentUser = false
    var bookMarkedByCurrentUser = false
    var dislikedByCurrentUser = false
    var commentCount: Int = 0
   
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        self.channelName = dictionary["channelName"] as? String ?? ""
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        self.uid = dictionary["uid"] as? String ?? ""
        self.realUID = dictionary["anonymeUID"] as? String ?? ""
    }
}
