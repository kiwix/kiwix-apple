//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import ProcedureKit

class LibraryController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let onboardingController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LibraryOnboardingController")
        setChild(controller: UINavigationController(rootViewController: onboardingController))
    }
    
    private func setChild(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)])
        controller.didMove(toParentViewController: self)
    }
}

class LibraryOnboardingController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .groupTableViewBackground
        title = NSLocalizedString("Library", comment: "Library title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        titleLabel.text = NSLocalizedString("Download Library Catalogue", comment: "")
        subtitleLabel.text = NSLocalizedString("After that, browse and download a book. Zim files added through iTunes File Sharing will automatically show up.", comment: "")
        subtitleLabel.numberOfLines = 0
        downloadButton.setTitle(NSLocalizedString("Download", comment: ""), for: .normal)
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonTapped(_ sender: UIButton) {
        
    }
}



class LibraryOldController: UIViewController {
    weak var onboardingController: LibraryOldOnboardingController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        if Preference.libraryLastRefreshTime == nil {
            let onbaording = LibraryOldOnboardingController()
            setChild(controller: UINavigationController(rootViewController: onbaording))
            onbaording.button.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
            onboardingController = onbaording
        } else {
            let split = LibrarySplitController()
            setChild(controller: split)
        }
    }
    
    private func setChild(controller: UIViewController) {
        view.subviews.forEach({ $0.removeFromSuperview() })
        childViewControllers.forEach({ $0.removeFromParentViewController() })
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        view.addConstraints([
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)])
        controller.didMove(toParentViewController: self)
    }
    
    @objc func refreshButtonTapped() {
        let procedure = LibraryRefreshProcedure()
        procedure.add(observer: WillExecuteObserver(willExecute: { (_, event) in
            OperationQueue.main.addOperation({
                self.onboardingController?.activityIndicator.startAnimating()
                self.onboardingController?.button.isEnabled = false
            })
        }))
        procedure.add(observer: DidFinishObserver(didFinish: { (procedure, errors) in
            OperationQueue.main.addOperation({
                if errors.count > 0 {
                    self.onboardingController?.button.isEnabled = true
                } else {
                    self.onboardingController?.activityIndicator.stopAnimating()
                    self.configure()
                }
            })
        }))
        Queue.shared.add(libraryRefresh: procedure)
    }
}

class LibraryOldOnboardingController: PresentationBaseController {
    let topStackView = UIStackView()
    let stackView = UIStackView()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let button = RoundedButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        configure()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass else {return}
        topStackView.axis = traitCollection.verticalSizeClass == .compact ? .horizontal : .vertical
    }
    
    private func configure() {
        view.backgroundColor = .groupTableViewBackground
        
        let imageView: UIImageView = {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "Library").withRenderingMode(.alwaysTemplate))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = UIColor.gray
            imageView.addConstraints([
                imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
                imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)])
            return imageView
        }()
        
        let label: UILabel = {
            let label = UILabel()
            label.text = NSLocalizedString("Refresh library to see all books available for download or import zim files using iTunes File Sharing.", comment: "Empty Library Help")
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.textColor = UIColor.gray
            label.numberOfLines = 0
            return label
        }()
        
        button.setTitle(NSLocalizedString("Refresh Library", comment: "Empty Library Action"), for: .normal)
        button.setTitle(NSLocalizedString("Refreshing...", comment: "Empty Library Action"), for: .disabled)
        
        topStackView.addArrangedSubview(imageView)
        topStackView.addArrangedSubview(StackViewBoundingView(subView: label))
        
        topStackView.axis = traitCollection.verticalSizeClass == .compact ? .horizontal : .vertical
        topStackView.spacing = 10
        topStackView.distribution = .equalSpacing
        topStackView.alignment = .center
        
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        var constraints = [
            stackView.leftAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.leftAnchor),
            stackView.rightAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.rightAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.readableContentGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.readableContentGuide.centerYAnchor)
        ]
        let widthConstraint = stackView.widthAnchor.constraint(equalToConstant: 500)
        widthConstraint.priority = .defaultHigh
        constraints.append(widthConstraint)
        let heightConstraint = stackView.heightAnchor.constraint(equalTo: view.readableContentGuide.heightAnchor, multiplier: 0.4, constant: 80)
        heightConstraint.priority = .defaultHigh
        constraints.append(heightConstraint)
        view.addConstraints(constraints)
        
        stackView.addArrangedSubview(topStackView)
        stackView.addArrangedSubview(StackViewBoundingView(subView: activityIndicator))
        stackView.addArrangedSubview(button)
    }
}

class LibrarySplitController: UISplitViewController, UISplitViewControllerDelegate {
    init() {
        super.init(nibName: nil, bundle: nil)
        let master = LibraryMasterController()
        let detail = LibraryCategoryController(category: master.categories.first, title: master.categoryNames.first)
        viewControllers = [
            UINavigationController(rootViewController: master),
            UINavigationController(rootViewController: detail)]
        delegate = self
        preferredDisplayMode = .allVisible
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        definesPresentationContext = true
        let controller = UIViewController()
        controller.view.backgroundColor = .white
        present(controller, animated: false, completion: nil)
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

class StackViewBoundingView: UIView {
    init(subView: UIView, size: CGSize = .zero, inset: UIEdgeInsets = .zero) {
        super.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        subView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subView)
        addConstraints([
            topAnchor.constraint(equalTo: subView.topAnchor, constant: -inset.top),
            leftAnchor.constraint(equalTo: subView.leftAnchor, constant: -inset.left),
            bottomAnchor.constraint(equalTo: subView.bottomAnchor, constant: inset.bottom),
            rightAnchor.constraint(equalTo: subView.rightAnchor, constant: -inset.right)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
