//
//  NavigationListController.swift
//  Kiwix
//
//  Created by Chris Li on 11/21/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class NavigationListController: UITableViewController {
    
    var type: NavigationListType = .back
    weak var delegate: NavigationListControllerDelegate?
    private var urls = [URL]()
    private var currentIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(dismiss(sender:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func dismiss(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation List
    
    func startLoading(requestURL: URL) {
        if let index = currentIndex {
            if index == urls.count - 1 {
                urls.append(requestURL)
                currentIndex = index + 1
            } else {
                if requestURL == urls[index] {
                    
                } else if requestURL == urls[index + 1] {
                    currentIndex = index + 1
                } else {
                    urls.removeLast(urls.count - index - 1)
                    urls.append(requestURL)
                    currentIndex = index + 1
                }
            }
        } else {
            urls.append(requestURL)
            currentIndex = 0
        }
    }
    
    func urlMapping(indexPath: IndexPath) -> Int? {
        guard let currentIndex = currentIndex else {return nil}
        switch type {
        case .back:
            return currentIndex - indexPath.row - 1
        case .forward:
            return currentIndex + indexPath.row + 1
        }
    }
    
    var canGoBack: Bool {
        guard let index = currentIndex else {return false}
        return index >= 1
    }
    
    var canGoForward: Bool {
        guard let index = currentIndex else {return false}
        return index <= urls.count - 2
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let currentIndex = currentIndex else {return 0}
        switch type {
        case .back:
            return currentIndex
        case .forward:
            return urls.count - currentIndex - 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let index = urlMapping(indexPath: indexPath) {
            let url = urls[index]
            cell.textLabel?.text = url.lastPathComponent
        }

        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
        if let index = urlMapping(indexPath: indexPath) {
            let url = urls[index]
            currentIndex = index
            delegate?.load(url: url)
        }
        
    }
}

protocol NavigationListControllerDelegate: class {
    func load(url: URL)
}

enum NavigationListType {
    case back, forward
}
