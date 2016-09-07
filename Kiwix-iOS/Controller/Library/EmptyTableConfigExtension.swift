//
//  EmptyTableConfigExtension.swift
//  Kiwix
//
//  Created by Chris Li on 8/23/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

extension CloudBooksController {
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "CloudColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("There are some books in the cloud", comment: "Cloud Book Controller")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let string = isRefreshing ? NSLocalizedString("Refreshing...", comment: "Cloud Book Controller") : NSLocalizedString("Refresh", comment: "Cloud Book Controller")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17), NSForegroundColorAttributeName: isRefreshing ? UIColor.grayColor() : AppColors.theme]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        guard !isRefreshing else {return}
        refresh(invokedByUser: true)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -navigationController!.navigationBar.frame.height
    }
    
}

extension DownloadTasksController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Download Tasks", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
}

extension LocalBooksController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Local Books on Device", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
}

extension BookDetailController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Choose A Book", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
}

extension LanguageFilterController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Lang Available", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
//    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
//        return scrollView.contentInset.top - 64
//    }
}
