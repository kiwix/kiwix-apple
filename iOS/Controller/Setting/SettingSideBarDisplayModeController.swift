//
//  SettingSideBarDisplayModeController.swift
//  iOS
//
//  Created by Chris Li on 5/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

class SettingSideBarDisplayModeController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: {
        if #available(iOS 13.0, *) {
            return .grouped
        } else {
            return .grouped
        }
    }())
    private let modes: [SideBarDisplayMode] = [.automatic, .overlay, .sideBySide]
    private var contentSizeObserver : NSKeyValueObservation?
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 1))
        contentSizeObserver = tableView.observe(\.contentSize) { [unowned self] tableView, _ in
            self.preferredContentSize = CGSize(width: 320, height: tableView.contentSize.height)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contentSizeObserver = nil
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = modes[indexPath.row].description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "When button is pressed, show the side bar in:"
        return label
    }
}
