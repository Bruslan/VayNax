//
//  ChannelsController.swift
//  InstagramClone
//
//  Created by Bruslan on 06.12.18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class ChannelsController: UITableViewController {
    
    var Channels = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
//        self.title = "VayChannels"
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.cellId)
        fetchAllChannels()
    }

    func fetchAllChannels(){
         self.tableView?.refreshControl?.beginRefreshing()
        Database.database().fetchAllChannels(completion: { (channelsArray) in
      
            
            self.Channels = channelsArray
            
            self.tableView?.reloadData()
            self.tableView?.refreshControl?.endRefreshing()
            
        }) { (Error) in
            self.tableView?.refreshControl?.endRefreshing()
            print("error beim channel Fetch ", Error)
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return Channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: ChannelCell.cellId, for: indexPath) as! ChannelCell
 
        
        cell.channelsLabel.text = Channels[indexPath.item]
        
        return cell

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return  100
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let feedsController = HomeController(collectionViewLayout: UICollectionViewFlowLayout())
//        feedsController.currentChannel = channelList[indexPath.item]
        //        impact.impactOccurred()
        feedsController.ChannelName = Channels[indexPath.item]
        navigationController?.pushViewController(feedsController, animated: true)
    }
}
