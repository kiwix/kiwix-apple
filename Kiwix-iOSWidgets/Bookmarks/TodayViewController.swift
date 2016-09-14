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
    
    private let hInset: CGFloat = 15.0
    private let vInset: CGFloat = 10.0
    private var itemSize = CGSizeZero
    private var itemsPerRow: CGFloat = 5
    private var rowCount: CGFloat = 1
    private var maxRowCount: CGFloat = 1
    
    private var hasUpdate = true
    private var bookmarks = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        calculateItemSize(collectionViewWidth: size.width)
        updateUI()
    }
    
    // MARK: - Update & Calculation
    
    func updateData() {
        guard let defaults = NSUserDefaults(suiteName: "group.kiwix") else {return}
        guard let bookmarks = defaults.objectForKey("bookmarks") as? [NSDictionary] else {return}
        hasUpdate = self.bookmarks != bookmarks
        self.bookmarks = bookmarks
        maxRowCount = CGFloat(max(1, min(defaults.integerForKey("BookmarkWidgetMaxRowCount"), 3)))
    }
    
    func updateUI() {
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        NCWidgetController.widgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
    }
    
    func calculateItemSize(collectionViewWidth collectionViewWidth: CGFloat) {
        itemsPerRow = max(5, min(round(collectionViewWidth / 70), 10))
        let itemWidth = (collectionViewWidth - (itemsPerRow + 1) * hInset) / itemsPerRow
        let titles = bookmarks.flatMap({$0.objectForKey("title") as? String})
        let labelHeights = titles.map({$0.heightWithConstrainedWidth(itemWidth, font: UIFont.systemFontOfSize(10.0, weight: UIFontWeightMedium))})
        let labelMaxHeight = max(12.0, min((labelHeights.maxElement() ?? 12.0), 24.0))
        let itemHeight = itemWidth + 2.0 + labelMaxHeight // itemHeight (1:1 ration) + label top spacing + label height
        itemSize = CGSizeMake(itemWidth, itemHeight)
        
        rowCount = min(ceil(CGFloat(bookmarks.count) / CGFloat(itemsPerRow)), maxRowCount)
        let collectionViewHeight = itemHeight * rowCount + hInset * (rowCount - 1)
        preferredContentSize = CGSizeMake(0, max(1, collectionViewHeight))
    }
    
    // MARK: - NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
        completionHandler(hasUpdate ? .NewData : .NoData)
        hasUpdate = false
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(bookmarks.count, Int(itemsPerRow * rowCount))
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
        if #available(iOS 10.0, *) {
            cell.label.textColor = UIColor.darkTextColor()
        }
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
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return hInset
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return vInset
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
