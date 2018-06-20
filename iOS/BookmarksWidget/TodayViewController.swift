//
//  TodayViewController.swift
//  Bookmarks
//
//  Created by Chris Li on 2/8/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    private var bookmarks = [(title: String, url: String, thumbImageData: Data)]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bookmarks = getBookmarks()
        collectionView.reloadData()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        let bookmarks = getBookmarks()
        if bookmarks.map({ $0.url }) == self.bookmarks.map({ $0.url }) {
            completionHandler(.noData)
        } else {
            self.bookmarks = bookmarks
            collectionView.reloadData()
            completionHandler(.newData)
        }
        completionHandler(NCUpdateResult.newData)
    }
    
    func getBookmarks() -> [(title: String, url: String, thumbImageData: Data)] {
        return UserDefaults(suiteName: "group.kiwix")?.array(forKey: "bookmarks")?
            .compactMap({ $0 as? [String: Any] }).compactMap({ (bookmark) -> (title: String, url: String, thumbImageData: Data)? in
                guard let title = bookmark["title"] as? String,
                    let url = bookmark["url"] as? String,
                    let thumbImageData = bookmark["thumbImageData"] as? Data else {return nil}
                return (title, url, thumbImageData)
            }) ?? []
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(bookmarks.count, 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! TodayWidgetCollectionCell
        cell.imageView.image = UIImage(data: bookmarks[indexPath.item].thumbImageData)
        cell.label.text = bookmarks[indexPath.item].title
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width - 10 * 5) / 4, height: collectionView.frame.height - 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let url = URL(string: bookmarks[indexPath.item].url) else {return}
        extensionContext?.open(url)
    }
}

class TodayWidgetCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        label.numberOfLines = 2
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        
        if #available(iOS 10, *) {
            label.textColor = .darkGray
        }
    }
}
