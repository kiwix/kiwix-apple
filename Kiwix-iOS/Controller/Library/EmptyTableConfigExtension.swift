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
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Library is Empty", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
}

extension DownloadTasksController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Download Tasks", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return scrollView.contentInset.top - 64
    }
}

extension LocalBooksController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Local Books on Device", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return scrollView.contentInset.top - 64
    }
}

extension BookDetailController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("Choose A Book", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return scrollView.contentInset.top - 64
    }
}

extension LanguageFilterController {
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let string = NSLocalizedString("No Lang Available", comment: "")
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(18), NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return scrollView.contentInset.top - 64
    }
}
