//
//  FlickrViewController.swift
//  flickFlickr
//
//  Created by Pooj on 4/9/18.
//  Copyright © 2018 Pooja. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

var cache:NSCache<AnyObject, AnyObject>! = NSCache()

class FlickrViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
   
    @IBOutlet weak var collectionView: UICollectionView!
    let width = UIScreen.main.bounds.width
    
    @IBOutlet weak var gridSwitch: UISwitch!
    
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    
    var flickrImages = [FlickrImageModel]()
    var page:Int = 1, flickrTotalPages : Int? = 0 , perpage: Int? = 0, totalPhotos : Int? = 0
    let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    
    @IBOutlet weak var loadMoreButton: UIButton!
    
    // ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if(isInternetAvailable()) { // Validate network connectivity
            loadFlickrData()
            loadFlickrPages()
            renderUI(width: Int(width/4), height: Int(width/2))
        } else{
            let alert = UIAlertController(title: "Error!", message: "Please check the network connectivity. Flickr data could not be loaded ", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
   
    // Render each cell using cellForItemAt
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrImages.count
    }
    
    // Render each cell using cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "FlickrImageCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FlickrCollectionViewCell
        
        //cell.flickrImage.image = UIImage(named: "placeholder")
        let key = flickrImages[indexPath.row].id
        
        // Check if the object for key (id) exists in the cache
        if (cache.object(forKey: key as AnyObject) != nil){
            print("Cached image used, no need to download it")
            cell.flickrImage.image = cache.object(forKey: key as AnyObject) as? UIImage
        }else{
             cell.imageModel = flickrImages[indexPath.row]
        }
        
        if(self.totalPhotos != 0) {
            if(self.page == self.flickrTotalPages)
            {
                print("You reached at bottom \(self.page) \(String(describing: self.flickrTotalPages))")
            } else {
                print("You reached to \(self.page) out of \(String(describing: self.flickrTotalPages)) retrieving \(indexPath.row)")
                
                print(flickrImages.count )
                print(self.totalPhotos as Any )
                print(indexPath.row  )
                
                if(self.flickrImages.count == self.totalPhotos) {
                    loadMoreButton.isHidden = false
                }
              
                else if(indexPath.row == self.flickrImages.count - 4) {
                     loadMoreButton.isHidden = false
                }
                 
            }
        } else {
            print("NO data is fetched")
        }
        
        return cell
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
        
        let nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.black
        nav?.tintColor = UIColor.white
        
    }
    
    // Fetch All Photos
    func loadFlickrData(){
        
        FlickrImageModel.recentFlickrPhotos(page: page, callback: { (flickerImages: [FlickrImageModel]?) -> Void in
            
            for img in flickerImages! {
                self.flickrImages.append(img)
            }
            print(self.flickrImages.count as Any)
            
            DispatchQueue.main.async{
                self.collectionView.reloadData()
            }
        })
    }
    
    // Fetch Photos Metadata
    func loadFlickrPages(){
        FlickrPhotosMetadata.findPhotosMetadata(callback: { (flickerMetadata: FlickrPhotosMetadata?) -> Void in
            self.flickrTotalPages = flickerMetadata?.pages
            self.perpage = flickerMetadata?.perpage
            self.totalPhotos = flickerMetadata?.total
            
        })
    }

    // Load More Action
    @objc func lodMoreAction(sender: UIButton!) {
        activityIndicator.startAnimating()
        page = page + 1
        loadMoreButton.isHidden = true
        loadFlickrData()
        activityIndicator.stopAnimating()
    }
   
    // Render Initial UI
    func renderUI(width: Int, height: Int){
        self.loadMoreButton.addTarget(self, action: #selector(self.lodMoreAction), for: .touchUpInside)
        
        self.collectionView?.backgroundColor = UIColor(white: 0.2, alpha: 1)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        view.addSubview(activityIndicator)
        
        self.layout.sectionInset = UIEdgeInsets(top: 0, left: 0.5, bottom: 0, right: 0.5)
        self.layout.itemSize = CGSize(width: width , height: height)
        self.layout.minimumInteritemSpacing = 0
        self.layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = self.layout
        
    }
    
    // Validate Network Connectivity
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    // Action for Rearrange
    @IBAction func reArrangeCollectionView(_ sender: Any) {
        if(gridSwitch.isOn) {
            renderUI(width: Int(width), height: (Int(width/2)))
        } else {
            renderUI(width: Int(width/4), height: (Int(width/2)))
        }
        self.collectionView.reloadData()
    }
    
    
}