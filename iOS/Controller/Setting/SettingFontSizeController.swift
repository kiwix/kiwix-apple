//
//  SettingFontSizeController.swift
//  Kiwix
//
//  Created by Chris Li on 2/2/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SettingFontSizeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dividerViewHeightConstraint: NSLayoutConstraint!
    
    private(set) var selected = Defaults[.webViewTextSizeAdjustFactor]
    let percentages = [0.75, 0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.10, 1.15, 1.20, 1.30, 1.40, 1.50, 1.75, 2.0]
    let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.maximumIntegerDigits = 3
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14.0 * CGFloat(selected))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        dividerViewHeightConstraint.constant = 1 / UIScreen.main.scale
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return percentages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = percentageFormatter.string(from: NSNumber(value: percentages[indexPath.row]))
        cell.accessoryType = percentages[indexPath.row] == selected ? .checkmark : .none
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var indexPaths = [indexPath]
        
        if let previousIndex = percentages.firstIndex(of: selected) {
            indexPaths.append(IndexPath(row: previousIndex, section: 0))
        }
        
        selected = percentages[indexPath.row]
        tableView.reloadRows(at: indexPaths, with: .automatic)
        label.font = UIFont.systemFont(ofSize: CGFloat(14.0 * percentages[indexPath.row]))
        
        Defaults[.webViewTextSizeAdjustFactor] = selected
    }
}
