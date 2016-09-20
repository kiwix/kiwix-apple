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
        let string = NSLocalizedString("There are some books in the cloud", comment: "Library, cloud tab")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let string = isRefreshing ? NSLocalizedString("Refreshing...", comment: "Library, cloud tab") : NSLocalizedString("Refresh", comment: "Library, cloud tab")
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
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "DownloadColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Download Tasks", comment: "Library, download tab")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
}

extension LocalBooksController {
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "FolderColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Local Books on Device", comment: "Library, local tab")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Add Book by download in app or iTunes File Sharing. New books will show up here automatically.", comment: "Library, local tab")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -tabBarController!.navigationController!.navigationBar.frame.maxY
    }
}

extension BookDetailController {
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "BookColor")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Tap on A Book to See Detail", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -navigationController!.navigationBar.frame.maxY
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
