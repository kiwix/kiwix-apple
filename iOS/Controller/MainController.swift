//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController, UISearchBarDelegate, TabLoadingActivity, ToolBarControlEvents {
    let searchController = UISearchController(searchResultsController: SearchResultController())
    
    let tabContainerController = TabContainerController()
    let toolBarController = ToolBarController()
    let tableOfContentController = TableOfContentController()
    
    private let separatorView = UIView()
    private let dimView = DimView()
    
    private var isShowingTableOfContent = false
    private var configureToShowTableOfContent = {}
    private var configureToHideTableOfContent = {}
    private var setTableOfContentItems = { (items: [String]) in }
    
    private lazy var libraryController = LibraryController()
    
    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        toolBarController.delegate = self
        dimView.gestureRecognizer.addTarget(self, action: #selector(dimViewTapped))
        configureSearchController()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            configureForHorizontalCompact()
        case .regular:
            configureForHorizontalRegular()
        case .unspecified:
            break
        }
    }
    
    private func configureForHorizontalCompact() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        let controllers = [tabContainerController, tableOfContentController, toolBarController]
        controllers.forEach({ addChildViewController($0) })
        [tabContainerController.view!, toolBarController.view!, dimView, tableOfContentController.view!].forEach({
            $0.removeFromSuperview()
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        })

        let toolBarShowConstraint: NSLayoutConstraint = {
            if #available(iOS 11.0, *) {
                return view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolBarController.view.bottomAnchor, constant: 10)
            } else {
                return view.bottomAnchor.constraint(equalTo: toolBarController.view.bottomAnchor, constant: 10)
            }
        }()
        let toolBarHideConstraint = toolBarController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: toolBarController.visualView.shadow.blur)
        let tableOfContentShowConstraint = tableOfContentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let tableOfContentHideConstraint = tableOfContentController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: tableOfContentController.visualView.shadow.blur)
        let tableOfContentHeightConstraint = tableOfContentController.view.heightAnchor.constraint(equalToConstant: 300)
        tableOfContentHeightConstraint.priority = .defaultHigh

        var constraints = [tabContainerController.view.topAnchor.constraint(equalTo: view.topAnchor),
                           tabContainerController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                           tabContainerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                           tabContainerController.view.rightAnchor.constraint(equalTo: view.rightAnchor)]
        constraints.append(toolBarController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints += [dimView.topAnchor.constraint(equalTo: view.topAnchor),
                        dimView.leftAnchor.constraint(equalTo: view.leftAnchor),
                        dimView.rightAnchor.constraint(equalTo: view.rightAnchor),
                        dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)]
        constraints += [tableOfContentController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                        tableOfContentController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                        tableOfContentController.view.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
                        tableOfContentHeightConstraint]
        constraints.forEach({ $0.isActive = true })

        controllers.forEach({ $0.didMove(toParentViewController: self) })

        configureToShowTableOfContent = {
            tableOfContentHideConstraint.isActive = false
            tableOfContentShowConstraint.isActive = true
            toolBarShowConstraint.isActive = false
            toolBarHideConstraint.isActive = true
        }

        configureToHideTableOfContent = {
            tableOfContentShowConstraint.isActive = false
            tableOfContentHideConstraint.isActive = true
            toolBarHideConstraint.isActive = false
            toolBarShowConstraint.isActive = true
        }

//        setTableOfContentItems = { (items: [String]) in
//            tableOfContentHeightConstraint.constant = items.count > 0 ? 44 * CGFloat(items.count) : 300
//        }

        isShowingTableOfContent ? configureToShowTableOfContent() : configureToHideTableOfContent()
        dimView.isHidden = !isShowingTableOfContent
        dimView.isDimmed = isShowingTableOfContent
    }
    
    private func configureForHorizontalRegular() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        let controllers = [tableOfContentController, tabContainerController, toolBarController]
        controllers.forEach({ addChildViewController($0) })
        [tableOfContentController.view!, separatorView, tabContainerController.view!, toolBarController.view!].forEach({
            $0.removeFromSuperview()
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        })

        let tableOfContentShowConstraint = view.leadingAnchor.constraint(equalTo: tableOfContentController.view.leadingAnchor)
        let tableOfContentHideConstraint = view.leadingAnchor.constraint(equalTo: tabContainerController.view.leadingAnchor)
        var constraints = [
            tableOfContentController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tableOfContentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separatorView.topAnchor.constraint(equalTo: view.topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabContainerController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabContainerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        constraints += [tableOfContentController.view.trailingAnchor.constraint(equalTo: separatorView.leadingAnchor),
                        separatorView.trailingAnchor.constraint(equalTo: tabContainerController.view.leadingAnchor),
                        tabContainerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)]
        constraints += [tableOfContentController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
                        separatorView.widthAnchor.constraint(equalToConstant: 2/UIScreen.main.scale)]
        constraints += [tabContainerController.view.centerXAnchor.constraint(equalTo: toolBarController.view.centerXAnchor),
                        tabContainerController.view.bottomAnchor.constraint(equalTo: toolBarController.view.bottomAnchor, constant: 10)]
        constraints.forEach({ $0.isActive = true })

        controllers.forEach({ $0.didMove(toParentViewController: self) })

        configureToShowTableOfContent = {
            tableOfContentHideConstraint.isActive = false
            tableOfContentShowConstraint.isActive = true
        }

        configureToHideTableOfContent = {
            tableOfContentShowConstraint.isActive = false
            tableOfContentHideConstraint.isActive = true
        }

        isShowingTableOfContent ? configureToShowTableOfContent() : configureToHideTableOfContent()
        separatorView.backgroundColor = .lightGray
    }
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        self.definesPresentationContext = true
    }

    
    private func loadMainPageForCustomApps() {
        if Bundle.main.infoDictionary?["CFBundleName"] as? String != "Kiwix" {
            tabContainerController.currentTabController?.loadMainPage()
        }
    }
    
    @objc func cancelSearch() {
//        searchBar.resignFirstResponder()
    }
    
    @objc func dimViewTapped() {
        toggleTableOfContent()
    }
    
    func loadingFinished() {
        updateToolBarButtons()
    }
    
    func toggleTableOfContent() {
        isShowingTableOfContent = !self.isShowingTableOfContent
        if isShowingTableOfContent {
            dimView.isHidden = false
            dimView.isDimmed = false
        }
        view.layoutIfNeeded()
        isShowingTableOfContent ? configureToShowTableOfContent() : configureToHideTableOfContent()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            guard self.traitCollection.horizontalSizeClass == .compact else {return}
            self.dimView.isDimmed = self.isShowingTableOfContent
        }, completion: { _ in
            if !self.isShowingTableOfContent {
                self.dimView.isHidden = true
            }
        })
    }
    
    // MARK: - ToolBar
    
    func backButtonTapped() {
        tabContainerController.currentTabController?.goBack()
    }
    
    func forwardButtonTapped() {
        tabContainerController.currentTabController?.goForward()
    }
    
    func tableOfContentButtonTapped() {
        toggleTableOfContent()
    }
    
    func homeButtonTapped() {
        tabContainerController.currentTabController?.loadMainPage()
    }
    
    func libraryButtonTapped() {
        present(libraryController, animated: true, completion: nil)
    }
    
    private func updateToolBarButtons() {
        guard let tab = tabContainerController.currentTabController else {return}
        toolBarController.back.tintColor = tab.canGoBack ? nil : .gray
        toolBarController.forward.tintColor = tab.canGoForward ? nil : .gray
    }
    
    // MARK: - SearchBar
    
}

class BaseController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
}

fileprivate class DimView: UIView {
    var isDimmed: Bool = false {
        didSet {
            backgroundColor = isDimmed ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
    
    let gestureRecognizer = UITapGestureRecognizer()
    
    init() {
        super.init(frame: .zero)
        addGestureRecognizer(gestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGestureRecognizer(gestureRecognizer)
    }
}


