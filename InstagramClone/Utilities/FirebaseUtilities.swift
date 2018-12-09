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
    
    private func uploadUser(withUID uid: String, username: String, profileImageUrl: String? = nil, completion: @escaping (() -> ())) {
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
    
    fileprivate func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.1) else { return } //changed from 0.3
        
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
    
    fileprivate func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.1) else { return } //changed from 0.5
        
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
    
    func createPost(channel: String, withImage image: UIImage, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(channel).child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        Storage.storage().uploadPostImage(image: image, filename: postId) { (postImageUrl) in
            let values = ["channelName": channel, "imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
            
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
    
    func createPost(channel: String, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(channel).child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        let values = ["channelName": channel, "imageUrl": "", "caption": caption, "imageWidth": "", "imageHeight": "", "creationDate": Date().timeIntervalSince1970, "id": postId] as [String : Any]
            
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                completion(nil)
            }
        
    }
    
    func fetchPost(withUID uid: String, postId: String, completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(uid).child(postId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
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
                        post.likes = count
                        completion(post)
                    })
                }, withCancel: { (err) in
                   
                    cancel?(err)
                })
            })
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
            
            guard let postDictionary = snapshot.value as? [String: Any] else { return }
            
            Database.database().fetchUser(withUID: authorId, completion: { (user) in
                var post = Post(user: user, dictionary: postDictionary)
                post.id = postId
                
                //check likes
                Database.database().reference().child("likes").child(postId).child(currentUser).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? Int, value == 1 {
                        post.likedByCurrentUser = true
                    } else {
                        post.likedByCurrentUser = false
                    }
                    
                    Database.database().numberOfLikesForPost(withPostId: postId, completion: { (count) in
                        post.likes = count
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
                            feed.likes = count
                            
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
                    
                    Database.database().reference().child("likes").child(postId as! String).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Int, value == 1 {
                            feed.likedByCurrentUser = true
                        } else {
                            feed.likedByCurrentUser = false
                        }
                        
                        Database.database().numberOfLikesForPost(withPostId: postId as! String, completion: { (count) in
                            feed.likes = count
                           
                            posts.append(feed)
                            countervalue += 1
                            if (countervalue == valueDict.count){
                                countervalue = 0
                                dicts += 1
                                
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
    
    
    func deletePost(withUID uid: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(uid).child(postId).removeValue { (err, _) in
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
                
                    completion?(nil)
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
    
    func numberOfLikesForPost(withPostId postId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("likes").child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
}
