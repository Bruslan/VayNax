//
//  HomeController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomeController: HomePostCellViewController {
    

    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.register(HomePostCellNoImage.self, forCellWithReuseIdentifier: HomePostCellNoImage.cellId)
        collectionView?.backgroundView = HomeEmptyStateView()
        collectionView?.backgroundView?.alpha = 0
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        collectionView?.backgroundColor = UIColor.lightGray
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        fetchAllPosts()
    }
    
    private func configureNavigationBar() {
        
    navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "plus_unselected").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCreate))
//        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo").withRenderingMode(.alwaysOriginal))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
//        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "inbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
//        navigationItem.title = "VayNaxGram"
    }
    
    
    @objc func handleCreate(){
        let layout = UICollectionViewFlowLayout()
        let createController = NewSharePhotoController(collectionViewLayout: layout)
        createController.currentChannel = ChannelName
        let nacController = UINavigationController(rootViewController: createController)
        present(nacController, animated: true, completion: nil)
        
    }
    
    
    private func fetchAllPosts() {
        showEmptyStateViewIfNeeded()
        fetchPostsForCurrentUser()
//        fetchFollowingUserPosts()
//        fetchDummyPost()
    }
    
    
    private func fetchDummyPost(){
        
        let dummyUser = User(uid: "String", dictionary: ["username":"Dummy"])
        var dummyPost = Post(user: dummyUser, dictionary: ["caption":"Das ist ein Dummy post","id":"dummyPOst"])
        dummyPost.likedByCurrentUser = true
        posts.append(dummyPost)
    }
    
    private func fetchPostsForCurrentUser() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().fetchAllPosts(channel: ChannelName!, withUID: currentLoggedInUserId, completion: { (posts) in
            self.posts.append(contentsOf: posts)
            
            self.posts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
          
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    

    
    private func fetchFollowingUserPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            
            userIdsDictionary.forEach({ (uid, value) in
                
                Database.database().fetchAllPosts(channel: self.ChannelName!, withUID: uid, completion: { (posts) in
                    
                    self.posts.append(contentsOf: posts)
                    
                    self.posts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                    })
                    
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    
                }, withCancel: { (err) in
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    override func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfFollowingForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfPostsForUser(withUID: currentLoggedInUserId, completion: { (postCount) in
                
                if followingCount == 0 && postCount == 0 {
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                    
                } else {
                    self.collectionView?.backgroundView?.alpha = 0
                }
            })
        }
    }
    
    @objc private func handleRefresh() {
        posts.removeAll()
        fetchAllPosts()
    }
    
    @objc private func handleCamera() {
        let cameraController = CameraController()
        present(cameraController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        if indexPath.item < posts.count {
            if (posts[indexPath.item].imageUrl != "")
            {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
                cell.post = posts[indexPath.item]
                cell.delegate = self
                return cell
            }else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCellNoImage.cellId, for: indexPath) as! HomePostCellNoImage
                cell.post = posts[indexPath.item]
                cell.delegate = self
                return cell
            }

        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        return cell
        
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
//        dummyCell.post = posts[indexPath.item]
//        dummyCell.layoutIfNeeded()
//
//        var height: CGFloat = dummyCell.header.bounds.height
//        height += view.frame.width
//        height += 24 + 2 * dummyCell.padding //bookmark button + padding
//        height += dummyCell.captionLabel.intrinsicContentSize.height + 8
//        return CGSize(width: view.frame.width, height: height)
        
        
        
        let statusText = posts[indexPath.item].caption
        let rect = NSString(string: statusText).boundingRect(with: CGSize(width: view.frame.width, height: 1000), options: NSStringDrawingOptions.usesFontLeading.union(NSStringDrawingOptions.usesLineFragmentOrigin), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular)], context: nil)
        
        var knownHeight: CGFloat = 0
        if (posts[indexPath.item].imageUrl) != ""{
            knownHeight = 520
        }else{
            knownHeight = 150
        }
    
        return CGSize(width: view.frame.width, height: rect.height + knownHeight)
    }
}
