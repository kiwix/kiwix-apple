//
//  FontSizeController.swift
//  Kiwix
//
//  Created by Chris Li on 1/20/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class FontSizeController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var visiualView: UIVisualEffectView!
    @IBOutlet weak var tableView: UITableView!
    
    private(set) var selected = Preference.webViewZoomScale
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
        title = Localized.Setting.fontSize
        label.font = UIFont.systemFont(ofSize: 14.0 * CGFloat(selected))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if Preference.webViewZoomScale != selected {Controllers.main.webView.reload()}
        Preference.webViewZoomScale = selected
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topInset = (navigationController?.navigationBar.frame.height ?? 0) + visiualView.frame.height
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
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
        
        if let previousIndex = percentages.index(of: selected) {
            indexPaths.append(IndexPath(row: previousIndex, section: 0))
        }
        
        selected = percentages[indexPath.row]
        tableView.reloadRows(at: indexPaths, with: .automatic)
        label.font = UIFont.systemFont(ofSize: CGFloat(14.0 * percentages[indexPath.row]))
    }
    

}
