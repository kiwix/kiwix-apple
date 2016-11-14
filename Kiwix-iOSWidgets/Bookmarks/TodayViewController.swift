//
//  TodayViewController.swift
//  Article
//
//  Created by Chris Li on 7/19/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let hInset: CGFloat = 15.0
    fileprivate let vInset: CGFloat = 10.0
    fileprivate var itemSize = CGSize.zero
    fileprivate var itemsPerRow: CGFloat = 5
    fileprivate var rowCount: CGFloat = 1
    fileprivate var maxRowCount: CGFloat = 1
    
    fileprivate var hasUpdate = true
    fileprivate var bookmarks = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        calculateItemSize(collectionViewWidth: size.width)
        updateUI()
    }
    
    // MARK: - Update & Calculation
    
    func updateData() {
        guard let defaults = UserDefaults(suiteName: "group.kiwix") else {return}
        guard let bookmarks = defaults.object(forKey: "bookmarks") as? [NSDictionary] else {return}
        hasUpdate = self.bookmarks != bookmarks
        self.bookmarks = bookmarks
        maxRowCount = CGFloat(max(1, min(defaults.integer(forKey: "BookmarkWidgetMaxRowCount"), 3)))
    }
    
    func updateUI() {
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        NCWidgetController.widgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
    }
    
    func calculateItemSize(collectionViewWidth: CGFloat) {
        itemsPerRow = max(5, min(round(collectionViewWidth / 70), 10))
        let itemWidth = (collectionViewWidth - (itemsPerRow + 1) * hInset) / itemsPerRow
        let titles = bookmarks.flatMap({$0.object(forKey: "title") as? String})
        let labelHeights = titles.map({$0.heightWithConstrainedWidth(itemWidth, font: UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightMedium))})
        let labelMaxHeight = max(12.0, min((labelHeights.max() ?? 12.0), 24.0))
        let itemHeight = itemWidth + 2.0 + labelMaxHeight // itemHeight (1:1 ration) + label top spacing + label height
        itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        rowCount = min(ceil(CGFloat(bookmarks.count) / CGFloat(itemsPerRow)), maxRowCount)
        let collectionViewHeight = itemHeight * rowCount + hInset * rowCount
        preferredContentSize = CGSize(width: 0, height: max(1, collectionViewHeight))
    }
    
    // MARK: - NCWidgetProviding
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        updateData()
        calculateItemSize(collectionViewWidth: collectionView.frame.width)
        updateUI()
        completionHandler(hasUpdate ? .newData : .noData)
        hasUpdate = false
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(bookmarks.count, Int(itemsPerRow * rowCount))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookmarkWidgetCell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UICollectionViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BookmarkWidgetCell else {return}
        let bookmark = bookmarks[indexPath.item]
        guard let title = bookmark["title"] as? String,
            let thumbImageData = bookmark["thumbImageData"] as? Data else {return}
        
        cell.label.text = title
        cell.imageView.image = UIImage(data: thumbImageData)
        
        if #available(iOS 10, *) {
            cell.label.textColor = UIColor.darkGray
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bookmark = bookmarks[indexPath.item]
        guard let urlString = bookmark["url"] as? String,
            let url = URL(string: urlString) else {return}
        extensionContext?.open(url, completionHandler: { (completed) in
            collectionView.deselectItem(at: indexPath, animated: true)
        })
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return hInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return vInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(vInset, hInset, vInset, hInset)
    }
}

private extension String {
    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return boundingBox.height
    }
}
