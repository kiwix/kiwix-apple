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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.contentOffset = CGPoint.zero
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: - CollectionView Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Preference.RecentSearch.terms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UICollectionViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? LocalLangCell else {return}
        cell.label.text = Preference.RecentSearch.terms[indexPath.item]
    }
    
    // MARK: - CollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let mainVC = parent?.parent?.parent as? MainController,
            let searchController = parent?.parent as? SearchController,
            let cell = collectionView.cellForItem(at: indexPath) as? LocalLangCell,
            let text = cell.label.text else {return}
//        mainVC.searchBar.searchTerm = text
        searchController.startSearch(text, delayed: false)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - CollectionView Delegate FlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = 30
        let text = Preference.RecentSearch.terms[indexPath.item]
        let font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightRegular)
        let size = text.boundingRect(with: CGSize(width: 200, height: height),
                                             options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                             attributes: [NSFontAttributeName: font], context: nil)
        return CGSize(width: size.width + 30, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        
        var width: CGFloat = 0
        for item in 0..<numberOfItems {
            let size = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: item, section: section))
            width += size.width
        }
        width += 10.0 * CGFloat(numberOfItems - 1)
        
        let hInset = max((collectionView.frame.width - width) / 2, 10)
        return UIEdgeInsetsMake(0, hInset, 0, hInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}
