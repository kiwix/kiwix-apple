//
//  EmptyTableConfigExtension.swift
//  Kiwix
//
//  Created by Chris Li on 8/23/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

extension CloudBooksController {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "CloudColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("There are some books in the cloud", comment: "Library, cloud tab")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let string = isRefreshing ? NSLocalizedString("Refreshing...", comment: "Library, cloud tab") : NSLocalizedString("Refresh", comment: "Library, cloud tab")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName: isRefreshing ? UIColor.gray : AppColors.theme]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        guard !isRefreshing else {return}
        refresh(invokedByUser: true)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -navigationController!.navigationBar.frame.height
    }
}

extension DownloadTasksController {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "DownloadColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Download Tasks", comment: "Library, download tab")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -tabBarController!.navigationController!.navigationBar.frame.maxY
    }
}

extension LocalBooksController {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "FolderColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Local Books on Device", comment: "Library, local tab")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Add Book by download in app or iTunes File Sharing. New books will show up here automatically.", comment: "Library, local tab")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray, NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -tabBarController!.navigationController!.navigationBar.frame.maxY
    }
}

extension BookDetailController {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "BookColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Tap on A Book to See Detail", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -navigationController!.navigationBar.frame.maxY
    }
}

extension LanguageFilterController {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Lang Available", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: string, attributes: attributes)
    }
}
