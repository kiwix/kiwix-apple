//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class SettingNavigationController: UINavigationController {
    convenience init() {
        self.init(rootViewController: SettingController())
        modalPresentationStyle = .formSheet
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
}

class SettingController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    private let items: [[SettingMenuItem]] = {
        var items: [[SettingMenuItem]] = []
        
        var section = [SettingMenuItem]()
        if MFMailComposeViewController.canSendMail() {
            section.append(.feedback(title: NSLocalizedString("Email us your suggestions", comment: "Setting Item Title")))
        }
        section.append(.rateApp(title: NSLocalizedString("Give Kiwix a rate", comment: "Setting Item Title")))
        items.append(section)
        
        items.append([.about(title: NSLocalizedString("About", comment: "Setting Item Title"))])
        return items
    }()
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Setting title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.indexPathsForSelectedRows?.forEach({ tableView.deselectRow(at: $0, animated: false) })
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.section][indexPath.row]
        
        switch item {
        case .feedback(let title), .rateApp(let title), .about(let title):
            cell.textLabel?.text = title
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .feedback:
            presentFeedbackEmailComposer()
        case .rateApp(let title):
            presentRateAppAlert(title: title)
        case .about(let title):
            guard let path = Bundle.main.path(forResource: "About", ofType: "html") else {return}
            let url = URL(fileURLWithPath: path)
            let controller = SettingWebController(fileURL: url)
            controller.title = title
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: -
    
    private func presentRateAppAlert(title: String) {
        let alert = UIAlertController(title: title,
                                      message: NSLocalizedString("We will redirect you to App Store. Thank you for using Kiwix!", comment: "Rate App"),
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Rate App"), style: .default) { action in
            let url = URL(string: "itms-apps://itunes.apple.com/us/app/itunes-u/id997079563?action=write-review")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Rate App"), style: .default))
        
        present(alert, animated: true)
    }
}

extension SettingController: MFMailComposeViewControllerDelegate {
    private func presentFeedbackEmailComposer() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let controller = MFMailComposeViewController()
        controller.setToRecipients(["chris@kiwix.org"])
        controller.setSubject(NSLocalizedString(String(format: "Feedback of Kiwix for iOS v%@", version), comment: "Feedback Email"))
        controller.mailComposeDelegate = self
        present(controller, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        switch result {
        case .sent:
            let alert = UIAlertController(title: NSLocalizedString("Email Sent", comment: "Feedback Email"),
                                          message: NSLocalizedString("We will read your message as soon as possible.", comment: "Feedback Email"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Feedback Email"), style: .default))
            present(alert, animated: true)
        case .failed:
            guard let error = error else {break}
            let alert = UIAlertController(title: NSLocalizedString("Email Not Sent", comment: "Feedback Email"),
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Feedback Email"), style: .default))
            present(alert, animated: true)
        default:
            break
        }
    }
}

enum SettingMenuItem {
    case feedback(title: String), rateApp(title: String)
    case about(title: String)
}
