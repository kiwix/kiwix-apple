//
//  FontSizeTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class FontSizeTBVC: UITableViewController {

    @IBOutlet var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.fontSize
        slider.value = Float(Preference.webViewZoomScale)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.webViewZoomScale = Double(lroundf(slider.value))
    }
    
    @IBAction func sliderTouchUpInside(sender: UISlider) {
        let step = (sender.maximumValue - sender.minimumValue) / 6
        let roundedValue = Float(lroundf((sender.value - sender.minimumValue) / step)) * step + sender.minimumValue
        sender.setValue(roundedValue, animated: true)
    }
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return LocalizedStrings.fontSizeMessage
    }

}

extension LocalizedStrings {
    class var fontSizeMessage: String {return NSLocalizedString("Drag the slider above to adjust the font size of the article. The size of the percentage numbers shows the acutal font size of article body on screen.", comment: "Setting: Font Size")}
}
