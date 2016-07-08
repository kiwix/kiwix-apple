//
//  GetStartedController.swift
//  Kiwix
//
//  Created by Chris Li on 7/5/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class GetStartedController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSizeMake(400, 400)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func dismissButtonTapped(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
