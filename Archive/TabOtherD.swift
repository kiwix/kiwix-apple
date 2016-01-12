

//
//  TabOtherD.swift
//  Kiwix
//
//  Created by Chris on 12/22/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension TabsCVC: TabCellDelegate {
    
    func didTapOnCloseImageForCell(cell: TabCVCell) {
        guard let indexPath = collectionView?.indexPathForCell(cell) else {return}
        guard let tab = fetchedResultController.objectAtIndexPath(indexPath) as? Tab else {return}
        managedObjectContext.deleteObject(tab)
        
    }
}