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
    private let hSpacing: CGFloat = 15.0
    private var titles = [String]()
    private var thumbDatas = [NSData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        preferredContentSize = CGSizeMake(0,  rowHeight)
        updateData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    func updateData() {
        let defaults = NSUserDefaults(suiteName: "group.kiwix")
        guard let bookmarks = defaults?.objectForKey("bookmarks") as? [String: NSArray],
            let titles = bookmarks["titles"] as? [String],
            let thumbDatas = bookmarks["thumbDatas"] as? [NSData] else {return}
        self.titles = titles
        self.thumbDatas = thumbDatas
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BookmarkWidgetCell", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? BookmarkWidgetCell else {return}
        cell.label.text = titles[indexPath.item]
        cell.imageView.image = UIImage(data: thumbDatas[indexPath.item])
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let sectionInset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAtIndex: indexPath.section)
        let itemWidth = (collectionView.frame.width - 6 * hSpacing) / 5.0
        return CGSizeMake(itemWidth, rowHeight - sectionInset.top - sectionInset.bottom)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, hSpacing, 10, hSpacing)
    }
}
