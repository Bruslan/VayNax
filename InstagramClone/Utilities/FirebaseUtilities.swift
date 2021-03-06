//
//  FirebaseUtilities.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/30/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import Foundation
import Firebase

extension Auth {
    func createUser(withEmail email: String, username: String, password: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, err) in
            if let err = err {
                print("Failed to create user:", err)
                completion(err)
                return
            }
            guard let uid = user?.user.uid else { return }
            if let image = image {
                Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                    self.uploadUser(withUID: uid, username: username, profileImageUrl: profileImageUrl) {
                        completion(nil)
                    }
                })
            } else {
                self.uploadUser(withUID: uid, username: username) {
                    completion(nil)
                }
            }
        })
    }
    
     func uploadUser(withUID uid: String, username: String, profileImageUrl: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues = ["username": username]
        if profileImageUrl != nil {
            dictionaryValues["profileImageUrl"] = profileImageUrl
        }
        
        let values = [uid: dictionaryValues]
        Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            completion()
        })
    }
}

extension Storage {
    
    func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.5) else { return } //changed from 0.3
        
        let storageRef = Storage.storage().reference().child("profile_images").child(NSUUID().uuidString)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                guard let profileImageUrl = downloadURL?.absoluteString else { return }
                completion(profileImageUrl)
            })
        })
    }
    func deleteProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
    
        
        let url = ""
        
        let storageRef =  Storage.storage().reference(forURL: url)
        
        storageRef.delete { error in
            if let error = error {
                print(error)
            } else {
                // File deleted successfully
            }
        }
    }
    
    fileprivate func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.5) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("post_images").child(filename)
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
}

extension Database {

    //MARK: Users
    
    func fetchUser(withUID uid: String, completion: @escaping (User) -> ()) {
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            let user = User(uid: uid, dictionary: userDictionary)
            completion(user)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchAllUsers(includeCurrentUser: Bool = true, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var users = [User]()
            
            dictionaries.forEach({ (key, value) in
                if !includeCurrentUser, key == Auth.auth().currentUser?.uid {
                    completion([])
                    return
                }
                guard let userDictionary = value as? [String: Any] else { return }
                let user = User(uid: key, dictionary: userDictionary)
                users.append(user)
            })
            
            users.sort(by: { (user1, user2) -> Bool in
                return user1.username.compare(user2.username) == .orderedAscending
            })
            completion(users)
            
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func isFollowingUser(withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
                completion(true)
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func followUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let values = [uid: 1]
        Database.database().reference().child("following").child(currentLoggedInUserId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            
            let values = [currentLoggedInUserId: 1]
            Database.database().reference().child("followers").child(uid).updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func unfollowUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            Database.database().reference().child("followers").child(uid).child(currentLoggedInUserId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
            })
        }
    }
    
    //MARK: Posts
    
    func createPost(anonym: Bool, channel: String, withImage image: UIImage, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
       
        
        var userPostRef = Database.database().reference().child("posts").child(channel).child("4MQvhMjLqHWg5oODvmA28KdCzCI3").childByAutoId()
  
        guard var postId = userPostRef.key else { return }
        
     
        Storage.storage().uploadPostImage(image: image, filename: postId) { (postImageUrl) in
            
            var values = [String: Any]()
            if anonym {

                 values = ["anonymeUID": "4MQvhMjLqHWg5oODvmA28KdCzCI3", "uid": uid, "channelName": channel, "imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
                
            }else{
                
               
                
               
                userPostRef = Database.database().reference().child("posts").child(channel).child(uid).childByAutoId()
                
                 postId = userPostRef.key!
                 values = ["anonymeUID": uid,"uid": uid, "channelName": channel, "imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
                
            }
            
           
            let newPostRef =  Database.database().reference().child("postsNoUID").child(channel).child(postId)
            

            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                newPostRef.updateChildValues(values) {(err, ref) in
                    
                    if let err = err {
                        print("failed to save post on no uid DB", err)
                        completion(err)
                        return
                    }
                    
                     completion(nil)
                }
               
            }
        }
    }
    
    func createPost(anonym: Bool, channel: String, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        print("post try ")
        
        var userPostRef =  Database.database().reference().child("posts").child(channel).child("4MQvhMjLqHWg5oODvmA28KdCzCI3").childByAutoId()
        guard var postId = userPostRef.key else { return }

        
        var values = [String: Any]()
        if anonym {
       

          values = ["anonymeUID": "4MQvhMjLqHWg5oODvmA28KdCzCI3", "uid": uid, "channelName": channel, "imageUrl": "", "caption": caption, "imageWidth": "", "imageHeight": "", "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
            print("lande im anonym")
        }else{
        userPostRef = Database.database().reference().child("posts").child(channel).child(uid).childByAutoId()
        postId = userPostRef.key!
        values = ["anonymeUID": uid, "uid": uid, "channelName": channel, "imageUrl": "", "caption": caption, "imageWidth": "", "imageHeight": "", "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
        }
        
     
       
        let newPostRef = Database.database().reference().child("postsNoUID").child(channel).child(postId)
        
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                newPostRef.updateChildValues(values) {(err, ref) in
                    
                    if let err = err {
                        print("failed to save post on no uid DB", err)
                        completion(err)
                        return
                    }
                    
                    completion(nil)
                }
            }
        
    }
    
    func fetchPost(withUID uid: String, postId: String, completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(uid).child(postId)
         print("try to observe")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            print("snapshot fetch post .-----------------------", snapshot)
            guard let postDictionary = snapshot.value as? [String: Any] else { return }
            
            Database.database().fetchUser(withUID: uid, completion: { (user) in
                var post = Post(user: user, dictionary: postDictionary)
                post.id = postId
                
                //check likes
                Database.database().reference().child("likes").child(postId).child(currentLoggedInUser).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? Int, value == 1 {
                        post.likedByCurrentUser = true
                    } else {
                        post.likedByCurrentUser = false
                    }
                    
                    Database.database().numberOfLikesForPost(withPostId: postId, completion: { (count) in
                        post.likes = count["likesCount"] as! Int
                        completion(post)
                    })
                }, withCancel: { (err) in
                   
                    cancel?(err)
                })
            })
        },
                              
                            
               withCancel: { (err) in
//                let dummyUser = User(uid: "String", dictionary: ["username":"Dummy"])
//                let dummyPost = Post(user: dummyUser, dictionary: ["caption":"Das ist ein Dummy post","id":"dummyPOst"])
//
//                completion(dummyPost)
                cancel?(err)
        })

    }
    
    
    func createPost(withImage image: UIImage, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        Storage.storage().uploadPostImage(image: image, filename: postId) { (postImageUrl) in
            let values = ["imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
            
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func createPost(caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        let values = ["imageUrl": "", "caption": caption, "imageWidth": "", "imageHeight": "", "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
        
        userPostRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
            completion(nil)
        }
        
    }
    
    func fetchPost(postId: String, channel: String, authorId: String, completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        
         guard let currentUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(channel).child(authorId).child(postId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if !snapshot.hasChildren() {

                let dummyUser = User(uid: "String", dictionary: ["username":"Kein Beitrag Hier"])
                let dummyPost = Post(user: dummyUser, dictionary: ["caption":"Der Beitrag wurde gelöscht","id":"dummyPOst"])
                Database.database().reference().child("bookMarks").child(currentUser).child(channel).child(postId).removeValue { (err, _) in
                    Database.database().reference().child("likes").child(postId).child(currentUser).child("bookMark").removeValue { (err, _) in
                        if let err = err {
                            print("Failed to unlike post:", err)
                            return
                        }
                            completion(dummyPost)
                    }}
                
                
            }
            
            guard let postDictionary = snapshot.value as? [String: Any] else { return }
            
            Database.database().fetchUser(withUID: authorId, completion: { (user) in
                var post = Post(user: user, dictionary: postDictionary)
                post.id = postId
                
                //check likes
                
                Database.database().reference().child("likes").child(postId).child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    
                    
                    
                    if (value?["like"] != nil) {
                        post.likedByCurrentUser = true
                    } else{
                        post.likedByCurrentUser = false
                    }
                    if (value?["bookMark"] != nil) {
                        post.bookMarkedByCurrentUser = true
                    }else{
                        post.bookMarkedByCurrentUser = false
                    }
                    
                    
                    Database.database().numberOfLikesForPost(withPostId: postId, completion: { (count) in
                        post.likes = count["likesCount"] as? Int ?? 0
                        post.dislikes = count["dislikeCount"] as? Int ?? 0
                        
                        
                        completion(post)
                    })
                }, withCancel: { (err) in
                    
                    cancel?(err)

                })
            })
        })
    }
    
    func fetchAllBookMarksForUser(completion: @escaping ([String : [Post]]) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("bookMarks").child(currentLoggedInUserId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([:])
                return
            }
            
            var bookMarks = [Post]()
           
            var chanAndPost = [String : [Post]]()
            
            dictionaries.forEach({ (channelName, value) in
                
             
                let nsDict = value as! NSDictionary
                let dict = nsDict as! [String : [String : Any]]
                
 
                dict.forEach({ (arg0) in
                    
                    
                    let (postId, value) = arg0
                    
                    let authorId = value["authorId"] as! String
         
                    Database.database().fetchPost(postId: postId, channel: channelName, authorId: authorId, completion: { (Post) in
                        bookMarks.append(Post)
                    
                        if bookMarks.count == dict.count{
                            chanAndPost[channelName] = bookMarks
                            bookMarks.removeAll()
                            
                            
                            if chanAndPost.count == dictionaries.count{
                                
                                completion(chanAndPost)
                            }
                        }
                    }, withCancel: { (err) in
          
                        print("error by fetching Post")
                    })
                    
                })
            })
        })
        
        
    }
    
    func fetchAllPosts(withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [Post]()
            
            dictionaries.forEach({ (postId, value) in
                
                let nsDict = value as! NSDictionary
                
                Database.database().fetchUser(withUID: uid, completion: { (user) in
                    var feed = Post(user: user, dictionary: nsDict as! [String : Any])
                    
                    Database.database().reference().child("likes").child(postId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Int, value == 1 {
                            feed.likedByCurrentUser = true
                        } else {
                            feed.likedByCurrentUser = false
                        }
                        
                        Database.database().numberOfLikesForPost(withPostId: postId, completion: { (count) in
                            feed.likes = count["likesCount"] as! Int
                            
                            posts.append(feed)
                            
                            if posts.count == dictionaries.count {
                                completion(posts)
                            }
                        })
                    }, withCancel: { (err) in
                        
                        cancel?(err)
                    })
                    
                })
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    
    
    func fetchAllPosts(channel: String, withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        
        let ref = Database.database().reference().child("posts").child(channel)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [Post]()
            var dicts = 0
            var countervalue = 0

            dictionaries.forEach({ (arg0) in
                
          
                let (authorId, value) = arg0
                
                let valueDict = value as! NSDictionary

                valueDict.forEach({ (postId, value) in

                
                   
                let nsDict = value as! NSDictionary
                
                Database.database().fetchUser(withUID: authorId, completion: { (user) in
                var feed = Post(user: user, dictionary: nsDict as! [String : Any])
                    
                    Database.database().numberOfCommentsForPost(withPostId: postId as! String, completion: { (count) in
                        feed.commentCount = count
                
                    Database.database().reference().child("likes").child(postId as! String).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        
                        
            
                        if (value?["like"] != nil) {
                            feed.likedByCurrentUser = true
                        } else{
                            feed.likedByCurrentUser = false
                        }
                        if (value?["bookMark"] != nil) {
                            feed.bookMarkedByCurrentUser = true
                        }else{
                            feed.bookMarkedByCurrentUser = false
                        }
                        
//                            feed.likedByCurrentUser = true
//                        } else {
//                            feed.likedByCurrentUser = false
//                        }
                        
                        Database.database().numberOfLikesForPost(withPostId: postId as! String, completion: { (count) in
                            feed.likes = count["likesCount"] as! Int

                            posts.append(feed)
                            countervalue += 1
                        
                            print(countervalue, valueDict.count)
                            
                            if (countervalue == valueDict.count){
                                countervalue = 0
                                dicts += 1
                                
                                print(dictionaries.count, dicts)
                                
                                if dictionaries.count == dicts {
                                  
                                    completion(posts)
                                }
                            }
                        })
                       
                    }, withCancel: { (err) in
                        
                        cancel?(err)
                        
                    })
                            })
                    

                })
            })
            
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }}
    
    
    
    func fetchAllPostsNoUid(lastPost: Post?, channel: String, withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        print("fetch all Posts aufgerufen")
        var tempPosts = [Post]()
        let ref = Database.database().reference().child("postsNoUID").child(channel)
        var queryRef:DatabaseQuery
        if lastPost != nil {
            let lastTimestamp = lastPost!.creationDate.timeIntervalSince1970
            queryRef = ref.queryOrdered(byChild: "creationDate").queryEnding(atValue: lastTimestamp).queryLimited(toLast: 6)
        } else {
            queryRef = ref.queryOrdered(byChild: "creationDate").queryLimited(toLast: 6)
        }
        
        queryRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [Post]()
            var passed = 0
            
            print(dictionaries)
            dictionaries.forEach({ (arg0) in
             
                let (postId, value) = arg0
                let nsDict = value as! NSDictionary
                let valKey = value as! [String : Any]
      
                if postId != lastPost?.id {
                    Database.database().fetchUser(withUID: valKey["anonymeUID"] as! String, completion: { (user) in
                        var feed = Post(user: user, dictionary: nsDict as! [String : Any])
                        
                        Database.database().numberOfCommentsForPost(withPostId: postId as! String, completion: { (count) in
                            feed.commentCount = count
                            
                        Database.database().reference().child("likes").child(postId ).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                            let value = snapshot.value as? NSDictionary
                            
                            
                            
                            if (value?["like"] != nil) {
                                feed.likedByCurrentUser = true
                            } else{
                                feed.likedByCurrentUser = false
                            }
                            if (value?["bookMark"] != nil) {
                                feed.bookMarkedByCurrentUser = true
                            }else{
                                feed.bookMarkedByCurrentUser = false
                            }
                            
                            if (value?["dislike"] != nil) {
                                feed.dislikedByCurrentUser = true
                            }else{
                                feed.dislikedByCurrentUser = false
                            }
                            Database.database().numberOfLikesForPost(withPostId: postId , completion: { (dict) in
                               
                                feed.likes = dict["likesCount"] as? Int ?? 0
                                feed.dislikes = dict["dislikeCount"] as? Int ?? 0
                                
                                posts.append(feed)
                                
                                tempPosts.insert(feed, at: 0)
                               
                                print(passed, posts.count, dictionaries.count)
                                if posts.count + passed == dictionaries.count {
                                    completion(tempPosts)
                                }
                            })
                            
                        }, withCancel: { (err) in
                            
                            cancel?(err)
                            
                        })
                        })
                    })
                }else{
                    if dictionaries.count == 1{
                        completion(tempPosts)
                    }else{
                        passed += 1
                    }
                    
                }

            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }}
    
    
    func fetchAllChannels(completion: @escaping ([String]) -> (), withCancel cancel: ((Error) -> ())?) {

        var Channels = [String]()
        
        Database.database().reference().child("channels").observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            dictionaries.forEach({ (arg0) in
                
                let (channelName, _) = arg0
                    Channels.append(channelName)
                if Channels.count == dictionaries.count {
                    completion(Channels)
                }
            })
        }, withCancel: { (err) in
            
            cancel?(err)
        })}
    
    
    func deletePost(channelName: String, withUID uid: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(channelName).child(uid).child(postId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            Database.database().reference().child("comments").child(postId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to delete comments on post:", err)
                    completion?(err)
                    return
                }
                
                Database.database().reference().child("likes").child(postId).removeValue(completionBlock: { (err, _) in
                    if let err = err {
                        print("Failed to delete likes on post:", err)
                        completion?(err)
                        return
                    }
                    
                    Storage.storage().reference().child("post_images").child(postId).delete(completion: { (err) in
                        if let err = err {
                            print("Failed to delete post image from storage:", err)
                            completion?(err)
                            return
                        }
                    })
                
                    Database.database().reference().child("postsNoUID").child(channelName).child(postId).removeValue { (err, _) in
                        if let err = err {
                            print("Failed to delete post:", err)
                            completion?(err)
                            return
                        }
                                
                                completion?(nil)
                            
                       
                    }
                })
            })
        }
    }
    
    func addCommentToPost(withId postId: String, text: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["text": text, "creationDate": Date().timeIntervalSince1970, "uid": uid] as [String: Any]
        
        let commentsRef = Database.database().reference().child("comments").child(postId).childByAutoId()
        commentsRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to add comment:", err)
                completion(err)
                return
            }
            completion(nil)
        }}
    
    func fetchCommentsForPost(withId postId: String, completion: @escaping ([Comment]) -> (), withCancel cancel: ((Error) -> ())?) {
        let commentsReference = Database.database().reference().child("comments").child(postId)
        
        commentsReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var comments = [Comment]()
            
            dictionaries.forEach({ (key, value) in
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                
                Database.database().fetchUser(withUID: uid) { (user) in
                    let comment = Comment(user: user, dictionary: commentDictionary)
                    comments.append(comment)
                    
                    if comments.count == dictionaries.count {
                        comments.sort(by: { (comment1, comment2) -> Bool in
                            return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                        })
                        completion(comments)
                    }
                }
            })
            
        }) { (err) in
            print("Failed to fetch comments:", err)
            cancel?(err)
        }
    }
    
    //MARK: Utilities
    
    func numberOfPostsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("posts").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfFollowersForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("followers").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfFollowingForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfLikesForPost(withPostId postId: String, completion: @escaping ([String: Any] ) -> ()) {
        Database.database().reference().child("likes").child(postId).child("counts").observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries)
            } else {
                completion(["likesCount": 0] )
            }
        }
    }
    
    func numberOfCommentsForPost(withPostId postId: String, completion: @escaping (Int ) -> ()) {
        Database.database().reference().child("comments").child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                
                print("---------sdasdasdad-------------",dictionaries)
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
}
