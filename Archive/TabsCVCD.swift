//
//  TabsCVCD.swift
//  Kiwix
//
//  Created by Chris on 12/21/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension TabsCVC: UICollectionViewDelegateFlowLayout {
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tab", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? TabCVCell else {return}
        guard let tab = fetchedResultController.objectAtIndexPath(indexPath) as? Tab else {return}
        cell.delegate = self
        if let imageData = tab.snapshot {
            cell.setImage(UIImage(data: imageData))
        }
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let tab = fetchedResultController.objectAtIndexPath(indexPath) as? Tab else {return}
        if tabVCs[tab] == nil {tabVCs[tab] = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TabVC") as? TabVC}
        guard let tabVC = tabVCs[tab] else {return}
        
        let tabNavVC = UINavigationController(rootViewController: tabVC)
        tabNavVC.toolbarHidden = false
        
        selectedIndexPath = indexPath
        tabVC.tab = tab
        tabNavVC.transitioningDelegate = self
        presentViewController(tabNavVC, animated: true, completion: nil)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout 
    
    private var sectionEdgeInset: UIEdgeInsets {
        return UIEdgeInsetsMake(20, 20, 20, 20)
    }
    
    private var numberOfTabsPerRow: Int {
        let numberOfTabs = 15
        let horizontalClass = self.traitCollection.horizontalSizeClass
        let maxTabsPerRow = horizontalClass == .Compact ? 2 : 3
        var tabsPerRow = 1
        while tabsPerRow < maxTabsPerRow {
            guard numberOfTabs > (tabsPerRow * tabsPerRow) else {break}
            tabsPerRow++
        }
        print(tabsPerRow)
        return tabsPerRow
    }
    
    private var itemSize: CGSize {
        let interItemSpacing: CGFloat = 20
        let collectionViewWidth = collectionView?.frame.width ?? UIScreen.mainScreen().bounds.width
        let itemWidth = (collectionViewWidth - CGFloat(numberOfTabsPerRow - 1) * interItemSpacing - sectionEdgeInset.left - sectionEdgeInset.right) / CGFloat(numberOfTabsPerRow)
        return CGSizeMake(floor(itemWidth), floor(itemWidth * view.frame.height / view.frame.width))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionEdgeInset
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return sectionEdgeInset.top
    }
}