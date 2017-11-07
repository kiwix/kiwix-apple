//
//  ViewController.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class MainController: UIViewController, UISearchControllerDelegate, TabLoadingActivity, ToolBarControlEvents {
    // MARK: - Child Controllers
    let searchController = UISearchController(searchResultsController: SearchResultController())
    let tabContainerController = TabContainerController()
    let toolBarController = ToolBarController()
    let tableOfContentController = TableOfContentController()
    private lazy var libraryController = LibraryController()
    
    // MARK: - Views
    private let separatorView = UIView()
    private let dimView = DimView()
    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSearch))
    
    // MARK: - Constraints
    private let constraints = Constraints()
    private var isShowingTableOfContent = false
    private var configureToShowTableOfContent = {}
    private var configureToHideTableOfContent = {}
    private var setTableOfContentItems = { (items: [String]) in }

    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        dimView.gestureRecognizer.addTarget(self, action: #selector(dimViewTapped))
        configureSearchController()
        configureToolBarController()
        configureViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        constraints.traitCollectionChange()
    }
    
    private func configureSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.delegate = self
        searchController.searchResultsUpdater = searchController.searchResultsController as? SearchResultController
        navigationItem.titleView = searchController.searchBar
        self.definesPresentationContext = true
    }
    
    private func configureToolBarController() {
        toolBarController.delegate = self
        addChildViewController(toolBarController)
        toolBarController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBarController.view)
        
        NSLayoutConstraint.activate([toolBarController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)])
        let toolBarShowConstraint: NSLayoutConstraint = {
            if #available(iOS 11.0, *) {
                return view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolBarController.view.bottomAnchor, constant: 10)
            } else {
                return view.bottomAnchor.constraint(equalTo: toolBarController.view.bottomAnchor, constant: 10)
            }
        }()
        let toolBarHideConstraint = toolBarController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: toolBarController.visualView.shadow.blur)
        constraints.toolBar.show = {
            toolBarHideConstraint.isActive = false
            toolBarShowConstraint.isActive = true
        }
        constraints.toolBar.hide = {
            toolBarShowConstraint.isActive = false
            toolBarHideConstraint.isActive = true
        }
        
        constraints.toolBar.show()
        toolBarController.didMove(toParentViewController: self)
    }
    
    private func configureViews() {
        separatorView.backgroundColor = .lightGray
        let controllers = [tabContainerController, tableOfContentController]
        controllers.forEach({ addChildViewController($0) })
        [tabContainerController.view!, tableOfContentController.view!, separatorView, dimView].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        })
        view.bringSubview(toFront: toolBarController.view)
        configureConstraints()
        controllers.forEach({ $0.didMove(toParentViewController: self) })
    }
    
    private func configureConstraints() {
        let shared = [
            tabContainerController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tabContainerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
        let compact: [NSLayoutConstraint] = {
            let tableOfContentHeightConstraint = tableOfContentController.view.heightAnchor.constraint(equalToConstant: 300)
            tableOfContentHeightConstraint.priority = .defaultHigh
            return [
                tabContainerController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                tabContainerController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                dimView.topAnchor.constraint(equalTo: view.topAnchor),
                dimView.leftAnchor.constraint(equalTo: view.leftAnchor),
                dimView.rightAnchor.constraint(equalTo: view.rightAnchor),
                dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tableOfContentController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                tableOfContentController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                tableOfContentController.view.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7),
                tableOfContentHeightConstraint]
        }()
        let regular: [NSLayoutConstraint] = {
            var constraints = [
                tableOfContentController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
                tableOfContentController.view.trailingAnchor.constraint(equalTo: separatorView.leadingAnchor),
                separatorView.widthAnchor.constraint(equalToConstant: 2/UIScreen.main.scale),
                separatorView.trailingAnchor.constraint(equalTo: tabContainerController.view.leadingAnchor),
                tabContainerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableOfContentController.view.topAnchor.constraint(equalTo: view.topAnchor),
                tableOfContentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),]
            if #available(iOS 11.0, *) {
                constraints += [
                    separatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    separatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)]
            } else {
                constraints += [
                    separatorView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                    separatorView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor)]
            }
            return constraints
        }()
        let tableOfContentCompactShowConstraint = tableOfContentController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let tableOfContentCompactHideConstraint = tableOfContentController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: tableOfContentController.visualView.shadow.blur)
        let tableOfContentRegularShowConstraint = view.leadingAnchor.constraint(equalTo: tableOfContentController.view.leadingAnchor)
        let tableOfContentRegularHideConstraint = view.leadingAnchor.constraint(equalTo: tabContainerController.view.leadingAnchor)
        
        NSLayoutConstraint.activate(shared)
        constraints.traitCollectionChange = {
            switch self.traitCollection.horizontalSizeClass {
            case .compact:
                var activate = compact
                var deactivate = regular
                deactivate += [tableOfContentRegularShowConstraint, tableOfContentRegularHideConstraint]
                if self.isShowingTableOfContent {
                    activate.append(tableOfContentCompactShowConstraint)
                    deactivate.append(tableOfContentCompactHideConstraint)
                } else {
                    activate.append(tableOfContentCompactHideConstraint)
                    deactivate.append(tableOfContentCompactShowConstraint)
                }
                NSLayoutConstraint.deactivate(deactivate)
                NSLayoutConstraint.activate(activate)
            case .regular:
                var activate = regular
                var deactivate = compact
                deactivate += [tableOfContentCompactShowConstraint, tableOfContentCompactHideConstraint]
                if self.isShowingTableOfContent {
                    activate.append(tableOfContentRegularShowConstraint)
                    deactivate.append(tableOfContentRegularHideConstraint)
                } else {
                    activate.append(tableOfContentRegularHideConstraint)
                    deactivate.append(tableOfContentRegularShowConstraint)
                }
                NSLayoutConstraint.deactivate(deactivate)
                NSLayoutConstraint.activate(activate)
            case .unspecified:
                break
            }
        }
        
        constraints.tableOfContent.show = {
            switch self.traitCollection.horizontalSizeClass {
            case .compact:
                tableOfContentCompactHideConstraint.isActive = false
                tableOfContentCompactShowConstraint.isActive = true
            case .regular:
                tableOfContentRegularHideConstraint.isActive = false
                tableOfContentRegularShowConstraint.isActive = true
            case .unspecified:
                break
            }
        }
        
        constraints.tableOfContent.hide = {
            switch self.traitCollection.horizontalSizeClass {
            case .compact:
                tableOfContentCompactShowConstraint.isActive = false
                tableOfContentCompactHideConstraint.isActive = true
            case .regular:
                tableOfContentRegularShowConstraint.isActive = false
                tableOfContentRegularHideConstraint.isActive = true
            case .unspecified:
                break
            }
        }
    }
    
    private func loadMainPageForCustomApps() {
        if Bundle.main.infoDictionary?["CFBundleName"] as? String != "Kiwix" {
            tabContainerController.currentTabController?.loadMainPage()
        }
    }
    
    @objc func cancelSearch() {
        searchController.isActive = false
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
            if traitCollection.horizontalSizeClass == .compact {
                view.bringSubview(toFront: dimView)
                view.bringSubview(toFront: tableOfContentController.view)
            }
        }
        view.layoutIfNeeded()
        isShowingTableOfContent ? constraints.tableOfContent.show() : constraints.tableOfContent.hide()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.isDimmed = self.isShowingTableOfContent
        }, completion: { _ in
            if !self.isShowingTableOfContent {
                self.dimView.isHidden = true
                if self.traitCollection.horizontalSizeClass == .compact {
                    self.view.bringSubview(toFront: self.toolBarController.view)
                }
            }
        })
    }
    
    // MARK: - UISearchControllerDelegate
    
    func willPresentSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad else {return}
        navigationItem.setRightBarButton(cancelButton, animated: true)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        guard UIDevice.current.userInterfaceIdiom == .pad else {return}
        navigationItem.setRightBarButton(nil, animated: false)
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
    
    // MARK: -
    
    private class Constraints {
        let toolBar = ShowHide()
        let tableOfContent = ShowHide()
        var traitCollectionChange = {}
        
        class ShowHide {
            var show = {}
            var hide = {}
        }
    }
    
    private class DimView: UIView {
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
}
