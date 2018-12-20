//
//  HomeCellViewController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomePostCellViewController: UICollectionViewController, HomePostCellDelegate {

    

    

    var ChannelName: String? {
        didSet {
            
            navigationItem.title = ChannelName
        }
    }
  
    var posts = [Post]()
    
    func showEmptyStateViewIfNeeded() {}
    
    //MARK: - HomePostCellDelegate
    
    func didTapComment(post: Post) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapOptions(post: Post) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if currentLoggedInUserId == post.user.uid {
            if let deleteAction = deleteAction(forPost: post) {
                alertController.addAction(deleteAction)
            }
        } else {
            if let unfollowAction = unfollowAction(forPost: post) {
                alertController.addAction(unfollowAction)
            }
            if let reportAction = reportAction(forPost: post) {
                alertController.addAction(reportAction)
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    private func deleteAction(forPost post: Post) -> UIAlertAction? {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return nil }
        
        let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                
                Database.database().deletePost(channelName: post.channelName, withUID: currentLoggedInUserId, postId: post.id) { (_) in
                    if let postIndex = self.posts.index(where: {$0.id == post.id}) {
                        self.posts.remove(at: postIndex)
                        self.collectionView?.reloadData()
                        self.showEmptyStateViewIfNeeded()
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func unfollowAction(forPost post: Post) -> UIAlertAction? {
        let action = UIAlertAction(title: "Unfollow", style: .destructive) { (_) in
            
            let uid = post.user.uid
            Database.database().unfollowUser(withUID: uid, completion: { (_) in
                let filteredPosts = self.posts.filter({$0.user.uid != uid})
                self.posts = filteredPosts
                self.collectionView?.reloadData()
                self.showEmptyStateViewIfNeeded()
            })
        }
        return action
    }
    
    
    private func reportAction(forPost post: Post) -> UIAlertAction? {
        let action = UIAlertAction(title: "Report", style: .destructive) { (_) in
            
            let uid = post.user.uid
            Database.database().reference().child("reports").child(uid).updateChildValues([post.id : true])
        }
        return action
    }
    
    func didBookMark(for cell: UICollectionViewCell) {
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var post = posts[indexPath.item]
        
        if post.bookMarkedByCurrentUser {
            Database.database().reference().child("bookMarks").child(uid).child(post.channelName).child(post.id).removeValue { (err, _) in
                Database.database().reference().child("likes").child(post.id).child(uid).child("bookMark").removeValue { (err, _) in
                if let err = err {
                    print("Failed to unlike post:", err)
                    return
                }
                post.bookMarkedByCurrentUser = false
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
                }}
        } else {
            let valueLike = ["bookMark" : 1]
            let values = ["authorId" : post.user.uid]
            Database.database().reference().child("bookMarks").child(uid).child(post.channelName).child(post.id).updateChildValues(values) { (err, _) in
                 Database.database().reference().child("likes").child(post.id).child(uid).updateChildValues(valueLike) { (err, _) in
                if let err = err {
                    print("Failed to like post:", err)
                    return
                }
                post.bookMarkedByCurrentUser = true
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
                }}
        }
    }
    
    func didSave(for cell: UICollectionViewCell) {
        print("did Save was called")
        
        let targetHomeCell = cell as! HomePostCell
        let targetImage = targetHomeCell.photoImageView.image

        UIImageWriteToSavedPhotosAlbum(targetImage!, savedAlert(), nil, nil)
    }
    
    func savedAlert(){
        
        print("save Alert was called")
        let alertController = UIAlertController(title: "Foto", message: "wurde gespeichert!", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
            
            // Code in this block will trigger when OK button tapped.
            print("Saved");
            
        }
        
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true, completion:nil)
    }
    
    func didLike(for cell: UICollectionViewCell) {
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var post = posts[indexPath.item]
        
        if post.likedByCurrentUser {
            Database.database().reference().child("likes").child(post.id).child(uid).child("like").removeValue { (err, _) in
                if let err = err {
                    print("Failed to unlike post:", err)
                    return
                }
                post.likedByCurrentUser = false
                post.likes = post.likes - 1
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        } else {
            let values = ["like" : 1]
            Database.database().reference().child("likes").child(post.id).child(uid).updateChildValues(values) { (err, _) in
                if let err = err {
                    print("Failed to like post:", err)
                    return
                }
                post.likedByCurrentUser = true
                post.likes = post.likes + 1
                self.posts[indexPath.item] = post
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        }
    }
    

}
