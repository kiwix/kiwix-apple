//
//  TodayViewController.swift
//  Article
//
//  Created by Chris Li on 7/19/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var rowHeight: CGFloat = 110.0
    private let hInset: CGFloat = 15.0
    private let vInset: CGFloat = 10.0
    private var itemHeight: CGFloat = 0.0
    private var itemWidth: CGFloat = 0.0
    
    private var bookmarks = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        updateData()
        updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        updateUI()
    }
    
    // MARK: - NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        updateData()
        updateUI()
        completionHandler(NCUpdateResult.NewData)
    }
    
    func updateData() {
        let defaults = NSUserDefaults(suiteName: "group.kiwix")
        guard let bookmarks = defaults?.objectForKey("bookmarks") as? [NSDictionary] else {return}
        self.bookmarks = bookmarks
    }
    
    func updateUI() {
        itemWidth = (collectionView.frame.width - 6 * hInset) / 5
        
        let titles = bookmarks.flatMap({$0.objectForKey("title") as? String})
        let labelHeights = titles.map({$0.heightWithConstrainedWidth(itemWidth, font: UIFont.systemFontOfSize(10.0, weight: UIFontWeightMedium))})
        let labelMaxHeight = max(12.0, min((labelHeights.maxElement() ?? 12.0), 24.0))
        itemHeight = itemWidth + 2.0 + labelMaxHeight // itemHeight (1:1 ration) + label top spacing + label height
        
        preferredContentSize = CGSizeMake(collectionView.frame.width,  itemHeight + 2 * vInset)
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BookmarkWidgetCell", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? BookmarkWidgetCell else {return}
        let bookmark = bookmarks[indexPath.item]
        guard let title = bookmark["title"] as? String,
            let thumbImageData = bookmark["thumbImageData"] as? NSData else {return}
        
        cell.label.text = title
        cell.imageView.image = UIImage(data: thumbImageData)
        
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let bookmark = bookmarks[indexPath.item]
        guard let urlString = bookmark["url"] as? String,
            let url = NSURL(string: urlString) else {return}
        extensionContext?.openURL(url, completionHandler: { (completed) in
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        })
        
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(itemWidth, itemHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(vInset, hInset, vInset, hInset)
    }
}

private extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return boundingBox.height
    }
}
