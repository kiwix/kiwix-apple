//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 11/7/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class MainController: UIViewController, UISearchControllerDelegate {
    private (set) var isShowingPanel = false
    @IBOutlet weak var dimView: DimView!
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearchButtonTapped))
    
    @IBAction func togglePanel(_ sender: UIButton) {
        isShowingPanel ? hidePanel() : showPanel(mode: .tableOfContent)
    }

    // MARK: - Controllers
    
    let searchController = UISearchController(searchResultsController: SearchResultController())
    private var toolBarController: ToolBarController!
//    private (set) var container: TabContainerController!
    private var panel: PanelController!
    private lazy var library = LibraryController()
    
    // MARK: - Constraints
    
    @IBOutlet weak var panelCompactShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelCompactHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularShowConstraint: NSLayoutConstraint!
    @IBOutlet weak var panelRegularHideConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewWidthConstraints: NSLayoutConstraint!
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let identifier = segue.identifier else {return}
        switch identifier {
        case "TabContainerController":
            break
//            container = segue.destination as! TabContainerController
        case "ToolBarController":
            toolBarController = segue.destination as! ToolBarController
        case "PanelController":
            panel = segue.destination as! PanelController
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { self.configureToolbar() }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        separatorViewWidthConstraints.constant = 1 / UIScreen.main.scale
        switch traitCollection.horizontalSizeClass {
        case .compact:
            NSLayoutConstraint.deactivate([panelRegularShowConstraint, panelRegularHideConstraint])
            panelCompactShowConstraint.isActive = isShowingPanel
            panelCompactHideConstraint.isActive = !isShowingPanel
        case .regular:
            NSLayoutConstraint.deactivate([panelCompactShowConstraint, panelCompactHideConstraint])
            panelRegularShowConstraint.isActive = isShowingPanel
            panelRegularHideConstraint.isActive = !isShowingPanel
        case .unspecified:
            break
        }
        super.updateViewConstraints()
    }
    
    // MARK: -
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }
    
    @objc func cancelSearchButtonTapped() {
        searchController.isActive = false
    }
    
    @IBAction func dimViewTapped(_ sender: UITapGestureRecognizer) {
        hidePanel()
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(cancelButton, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact else {return}
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    // MARK: - Panel
    
    func showPanel(mode: PanelMode) {
        panel.set(mode: mode)
//        switch mode {
//        case .tableOfContent:
//            toolBar.tableOfContent.isSelected = true
//            toolBar.bookmark.isSelected = false
//        case .bookmark:
//            toolBar.tableOfContent.isSelected = false
//            toolBar.bookmark.isSelected = true
//        case .history:
//            toolBar.tableOfContent.isSelected = false
//            toolBar.bookmark.isSelected = false
//        }
        
        guard !isShowingPanel else {return}
        isShowingPanel = true
        dimView.isHidden = false
        dimView.isDimmed = false
        
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = true
        })
    }
    
    func hidePanel() {
        panel.set(mode: nil)
//        toolBar.tableOfContent.isSelected = false
//        toolBar.bookmark.isSelected = false
        
        guard isShowingPanel else {return}
        isShowingPanel = false
        view.layoutIfNeeded()
        view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = false
        }, completion: { _ in
            self.dimView.isHidden = true
        })
    }
    
    // MARK: - Toolbar
    
    private var navigationBackButton = BarButton(image: #imageLiteral(resourceName: "Left"), inset: 12, target: self, action: #selector(buttonTapped(button:)))
    private var navigationForwardButton = BarButton(image: #imageLiteral(resourceName: "Right"), inset: 12, target: self, action: #selector(buttonTapped(button:)))
    private var tableOfContentButton = BarButton(image: #imageLiteral(resourceName: "TableOfContent"), inset: 8, target: self, action: #selector(buttonTapped(button:)))
    private var bookmarkButton = BarButton(image: #imageLiteral(resourceName: "Star"), highlightedImage: #imageLiteral(resourceName: "StarFilled"), inset: 8, target: self, action: #selector(buttonTapped(button:)))
    private var libraryButton = BarButton(image: #imageLiteral(resourceName: "Library"), inset: 6, target: self, action: #selector(buttonTapped(button:)))
    private var settingButton = BarButton(image: #imageLiteral(resourceName: "Setting"), inset: 8, target: self, action: #selector(buttonTapped(button:)))
    
    private func configureToolbar() {
        toolbarItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        if traitCollection.horizontalSizeClass == .regular {
            navigationController?.isToolbarHidden = true
            navigationItem.leftBarButtonItems = [navigationBackButton, navigationForwardButton, tableOfContentButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
        } else if traitCollection.horizontalSizeClass == .compact {
            navigationController?.isToolbarHidden = false
            toolbarItems = [navigationBackButton, navigationForwardButton, tableOfContentButton, bookmarkButton, libraryButton, settingButton].enumerated()
                .reduce([], { $0 + ($1.offset > 0 ? [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), $1.element] : [$1.element]) })
            if searchController.isActive {
                navigationItem.setRightBarButton(cancelButton, animated: false)
            }
        }
    }
    
    @objc func buttonTapped(button: UIBarButtonItem) {
        switch button {
        case navigationBackButton:
            break
        default:
            break
        }
    }

    func tableOfContentButtonTapped() {
        if panel.mode == .tableOfContent {
            hidePanel()
        } else {
            showPanel(mode: .tableOfContent)
//            container.current?.getTableOfContent(completion: { (headings) in
//                self.panel.tableOfContent?.headings = headings
//            })
        }
    }
    
    func bookmarkButtonTapped() {
        panel.mode != .bookmark ? showPanel(mode: .bookmark) : hidePanel()
    }
    

    // MARK: - TabContainerControllerDelegate
    
//    func homeWillBecomeCurrent() {
//        toolBar.back.isEnabled = false
//        toolBar.forward.isEnabled = false
//        toolBar.home.isSelected = true
//    }
    
//    func tabWillBecomeCurrent(controller: UIViewController & WebViewController) {
//        toolBar.back.isEnabled = controller.canGoBack
//        toolBar.forward.isEnabled = controller.canGoForward
//        toolBar.home.isSelected = false
//    }
    
//    func tabDidFinishLoading(controller: UIViewController & WebViewController) {
//        toolBar.back.isEnabled = controller.canGoBack
//        toolBar.forward.isEnabled = controller.canGoForward
//    }
    
//    func libraryButtonTapped() {
//        present(library, animated: true, completion: nil)
//    }
//
//    func settingsButtonTapped() {
//    }
}

class BarButton: UIBarButtonItem {
    convenience init(image: UIImage, highlightedImage: UIImage?=nil, inset: CGFloat, target: Any?, action: Selector?) {
        let button = UIButton()
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(highlightedImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        button.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        self.init(customView: button)
        
        if #available(iOS 11.0, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1.0).isActive = true
        } else {
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        }
        
        self.target = target as AnyObject
        self.action = action
    }
}
