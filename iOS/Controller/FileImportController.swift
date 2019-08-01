//
//  FileImportController.swift
//  
//
//  Created by Chris Li on 7/28/19.
//

import UIKit

class FileImportController: UINavigationController {
    convenience init(fileURL: URL, canOpenInPlace: Bool = true) {
        self.init(rootViewController: ContentController(url: fileURL, canOpenInPlace: canOpenInPlace))
        modalPresentationStyle = .formSheet
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
}


fileprivate class ContentController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let url: URL
    private let fileSize: Int64
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let items: [[Item]]
    private let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                                 appropriateFor: nil, create: false)
    
    init(url: URL, canOpenInPlace: Bool = true) {
        _ = url.startAccessingSecurityScopedResource()
        
        self.url = url
        self.fileSize = Int64((try? url.resourceValues(forKeys: Set([.fileSizeKey])).fileSize) ?? 0)
        
        let actions: [Action] = canOpenInPlace ? [.copy, .move, .openInPlace] : [.copy, .move]
        self.items = [[Meta.fileName, Meta.fileSize], actions]

        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        url.stopAccessingSecurityScopedResource()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UIRightDetailTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UIActionTableViewCell.self, forCellReuseIdentifier: "ActionCell")
    }
    
    override func viewDidLoad() {
        title = NSLocalizedString("File Import", comment: "File Import Controller")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancelButtonTapped))
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        if let meta = item as? Meta {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UIRightDetailTableViewCell
            cell.textLabel?.text = meta.description
            switch meta {
            case .fileName:
                cell.detailTextLabel?.text = url.lastPathComponent
            case .fileSize:
                cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
            return cell
        } else if let item = item as? Action {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell") as! UIActionTableViewCell
            cell.textLabel?.text = item.description
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
            dismiss(animated: true)
        }
        guard indexPath.section == items.count - 1,
            let action = items[indexPath.section][indexPath.row] as? Action else {return}
        
        let destination = documentDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            switch action {
            case .copy:
                try FileManager.default.copyItem(at: url, to: destination)
            case .move:
                try FileManager.default.moveItem(at: url, to: destination)
                break
            case .openInPlace:
                LibraryOperationQueue.shared.addOperation(LibraryScanOperation(url: url))
            }
        } catch {
            print(error)
        }
    }
}


fileprivate protocol Item: CustomStringConvertible {}


fileprivate enum Meta: Item {
    case fileName, fileSize
    
    var description: String {
        switch self {
        case .fileName:
            return NSLocalizedString("File Name", comment: "")
        case .fileSize:
            return NSLocalizedString("File Size", comment: "")
        }
    }
}


fileprivate enum Action: Item {
    case move, copy, openInPlace
    
    var description: String {
        switch self {
        case .move:
            return NSLocalizedString("Move to Kiwix", comment: "")
        case .copy:
            return NSLocalizedString("Make a Duplicate", comment: "")
        case .openInPlace:
            return NSLocalizedString("Open in Place", comment: "")
        }
    }
}
