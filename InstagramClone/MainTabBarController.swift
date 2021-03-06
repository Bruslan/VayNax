import UIKit
import Firebase

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .black
        tabBar.isTranslucent = false
        delegate = self
        
        if Auth.auth().currentUser == nil {
            presentLoginController()
        } else {
            setupViewControllers()
        }
    }
    
    func setupViewControllers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        let searchNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: UserSearchController(collectionViewLayout: UICollectionViewFlowLayout()))
//        let plusNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        let channelsController = ChannelsController()
        let channelController = self.templateNavController(unselectedImage: UIImage(named: "grid")!, selectedImage: UIImage(named: "grid")!, rootViewController: channelsController)
        
        
        let bookMarkController = BookMarkViewController(collectionViewLayout: UICollectionViewFlowLayout())
        let likeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "icons8-stecknadel-50"), selectedImage: #imageLiteral(resourceName: "icons8-stecknadel-filled-50").withRenderingMode(.alwaysTemplate), rootViewController: bookMarkController)

        let userProfileController = UserProfileController(collectionViewLayout: StretchyHeaderLayout())
        let userProfileNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_selected"), rootViewController: userProfileController)
        
        Database.database().fetchUser(withUID: uid) { (user) in
            userProfileController.user = user
        }
        
        viewControllers = [channelController, searchNavController, likeNavController, userProfileNavController]
    }
    
    private func presentLoginController() {
        DispatchQueue.main.async { // wait until MainTabBarController is inside UI
            let loginController = LoginController()
            let navController = UINavigationController(rootViewController: loginController)
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    private func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let viewController = rootViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.isTranslucent = false
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        navController.tabBarItem.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        return navController
    }
}

//MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
//    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        let index = viewControllers?.index(of: viewController)
//        if index == 2 {
//            let layout = UICollectionViewFlowLayout()
//            let photoSelectorController = PhotoSelectorController(collectionViewLayout: layout)
//            let nacController = UINavigationController(rootViewController: photoSelectorController)
//            present(nacController, animated: true, completion: nil)
//            return false
//        }
//        return true
//    }
}

