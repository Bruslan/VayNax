//
//  BookMarkViewController.swift
//  InstagramClone
//
//  Created by Bruslan on 09.12.18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "Cell"

class BookMarkViewController: HomePostCellViewController, UICollectionViewDelegateFlowLayout {
    
    
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
        
        fetchAllBookMarks()
    }
    
    @objc private func handleRefresh() {

        posts.removeAll()
        fetchAllBookMarks()
    }
    
    
    private func fetchAllBookMarks(){
        
        print("start fetching BookMarks")
         self.collectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchAllBookMarksForUser(completion: { (favPosts) in

            print("Bookmarks fetched")
            favPosts.forEach({ (arg0) in

                let (_, postsArray) = arg0
                
                postsArray.forEach({ (feed) in
                    self.posts.append(feed)
                })
                

            })
            
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()

            
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
            print("error by fetcing BookMarks")
        }
    }
    
    private func configureNavigationBar() {
        

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black

    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

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
