//
//  AboutVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class AboutVC: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "About"
        
        let url = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("about", ofType: "html")!)
        let attrString: NSAttributedString? = {
            if #available(iOS 9.0, *) {
                do {
                    let attrStr = try NSAttributedString(URL: url, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    return attrStr
                } catch {
                    return nil
                }
            } else {
                do {
                    let attrStr = try NSAttributedString(fileURL: url, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    return attrStr
                } catch {
                    return nil
                }
            }
        }()
        
        textView.attributedText = attrString
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            textView.contentInset = UIEdgeInsetsMake(20, -2, 0, -2)
            textView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 0, 2)
        }
        
    }
}
