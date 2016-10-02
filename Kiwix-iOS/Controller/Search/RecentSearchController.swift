//
//  RecentSearchController.swift
//  Kiwix
//
//  Created by Chris Li on 6/19/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData

class RecentSearchController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.contentOffset = CGPointZero
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: - CollectionView Data Source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Preference.RecentSearch.terms.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? LocalLangCell else {return}
        cell.label.text = Preference.RecentSearch.terms[indexPath.item]
    }
    
    // MARK: - CollectionView Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let mainVC = parentViewController?.parentViewController?.parentViewController as? MainController,
            let searchController = parentViewController?.parentViewController as? SearchController,
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as? LocalLangCell,
            let text = cell.label.text else {return}
        mainVC.searchBar.searchTerm = text
        searchController.startSearch(text, delayed: false)
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - CollectionView Delegate FlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let height: CGFloat = 30
        let text = Preference.RecentSearch.terms[indexPath.item]
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        let size = text.boundingRectWithSize(CGSizeMake(200, height),
                                             options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                             attributes: [NSFontAttributeName: font], context: nil)
        return CGSizeMake(size.width + 30, height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let numberOfItems = collectionView.numberOfItemsInSection(section)
        
        var width: CGFloat = 0
        for item in 0..<numberOfItems {
            let size = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: NSIndexPath(forItem: item, inSection: section))
            width += size.width
        }
        width += 10.0 * CGFloat(numberOfItems - 1)
        
        let hInset = max((collectionView.frame.width - width) / 2, 10)
        return UIEdgeInsetsMake(0, hInset, 0, hInset)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
}
