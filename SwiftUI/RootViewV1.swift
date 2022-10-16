//
//  RootViewV1.swift
//  Kiwix
//
//  Created by Chris Li on 8/2/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

#if os(iOS)
import SwiftUI
import UIKit

import Introspect

/// Root view for iOS & iPadOS
struct RootViewV1: UIViewControllerRepresentable {
    @Binding var url: URL?
    @State private var isSearchActive = false
    @StateObject private var searchViewModel = SearchViewModel()
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let view = Content(isSearchActive: $isSearchActive, url: $url).environmentObject(searchViewModel)
        let controller = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: controller)
        
        // configure search bar
        let searchBar = UISearchBar()
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        searchBar.searchBarStyle = .minimal
        
        // configure navigation item
        controller.navigationItem.titleView = searchBar
        if #available(iOS 15.0, *) {
            controller.navigationItem.scrollEdgeAppearance = {
                let apperance = UINavigationBarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
            navigationController.toolbar.scrollEdgeAppearance = {
                let apperance = UIToolbarAppearance()
                apperance.configureWithDefaultBackground()
                return apperance
            }()
        }
        
        // observe bookmark toggle notification
        context.coordinator.bookmarkToggleObserver = NotificationCenter.default.addObserver(
            forName: ReadingViewModel.bookmarkNotificationName, object: nil, queue: nil
        ) { notification in
            let isBookmarked = notification.object != nil
            let hudController = HUDController()
            hudController.modalPresentationStyle = .custom
            hudController.transitioningDelegate = hudController
            hudController.direction = isBookmarked ? .down : .up
            hudController.imageView.image = isBookmarked ? #imageLiteral(resourceName: "StarAdd") : #imageLiteral(resourceName: "StarRemove")
            hudController.label.text = isBookmarked ?
                NSLocalizedString("Added", comment: "Bookmark HUD") :
                NSLocalizedString("Removed", comment: "Bookmark HUD")
            controller.present(hudController, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    hudController.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        guard let searchBar = navigationController.topViewController?.navigationItem.titleView as? UISearchBar else { return }
        
        if isSearchActive {
            searchBar.text = searchViewModel.searchText
        } else {
            // Triggers "AttributeGraph: cycle detected through attribute" if not dispatched (iOS 16.0 SDK)
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let rootView: RootViewV1
        var bookmarkToggleObserver: NSObjectProtocol?
        
        init(_ rootView: RootViewV1) {
            self.rootView = rootView
            super.init()
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            rootView.searchViewModel.searchText = searchText
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            withAnimation {
                rootView.isSearchActive = true
            }
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.text = ""
            rootView.searchViewModel.searchText = ""
        }
    }
}

private struct Content: View {
    @Binding var isSearchActive: Bool
    @Binding var url: URL?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Group {
            if isSearchActive {
                Search() { result in
                    url = result.url
                    isSearchActive = false
                }
            } else if url == nil {
                Welcome(url: $url)
            } else {
                WebView(url: $url).ignoresSafeArea(.container)
            }
        }
        .onChange(of: url) { _ in isSearchActive = false }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular, !isSearchActive {
                    NavigateBackButton()
                    NavigateForwardButton()
                    OutlineMenu()
                    BookmarkMultiButton(url: url)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular, !isSearchActive {
                    if #available(iOS 15.0, *) {
                        RandomArticleMenu(url: $url)
                    } else {
                        RandomArticleButton(url: $url)
                    }
                    if #available(iOS 15.0, *) {
                        MainArticleMenu(url: $url)
                    } else {
                        MainArticleButton(url: $url)
                    }
                    LibraryButton()
                    SettingsButton()
                } else if isSearchActive {
                    Button("Cancel") {
                        isSearchActive = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact, !isSearchActive {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                    }
                    Spacer()
                    OutlineButton()
                    Spacer()
                    BookmarkMultiButton(url: url)
                    Spacer()
                    if #available(iOS 15.0, *) {
                        RandomArticleMenu(url: $url)
                    } else {
                        RandomArticleButton(url: $url)
                    }
                    Spacer()
                    MoreActionMenu(url: $url)
                }
            }
        }
        .introspectNavigationController { controller in
            controller.setToolbarHidden(horizontalSizeClass != .compact || isSearchActive, animated: false)
        }
    }
}

class HUDController: UIViewController, UIViewControllerTransitioningDelegate {
    private let visualView = UIVisualEffectView(effect: {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemMaterial)
        } else {
            return UIBlurEffect(style: .extraLight)
        }
    }())
    private let stackView = UIStackView()
    let imageView = UIImageView()
    let label = UILabel()
    var direction: HUDAnimationDirection = .down
    
    override func loadView() {
        view = visualView
        visualView.layer.cornerRadius = 10
        visualView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = { if #available(iOS 13.0, *) { return .secondaryLabel } else { return .gray } }()
        
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        visualView.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: visualView.contentView.widthAnchor, multiplier: 0.8),
            stackView.heightAnchor.constraint(equalTo: visualView.contentView.heightAnchor, multiplier: 0.8),
            stackView.centerXAnchor.constraint(equalTo: visualView.contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: visualView.contentView.centerYAnchor)])
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDAnimator(direction: direction, isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HUDAnimator(direction: direction, isPresentation: false)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HUDPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class HUDAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: HUDAnimationDirection
    let isPresentation: Bool
    
    init(direction: HUDAnimationDirection, isPresentation: Bool) {
        self.direction = direction
        self.isPresentation = isPresentation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: isPresentation ? .to : .from),
            let presentedController = transitionContext.viewController(forKey: isPresentation ? .to : .from) else {return}
        let containerView = transitionContext.containerView

        var initialFrame = transitionContext.initialFrame(for: presentedController)
        var finalFrame = transitionContext.finalFrame(for: presentedController)
        
        if isPresentation {
            let dy = direction == .up ? containerView.frame.height - finalFrame.minY : -finalFrame.maxY
            initialFrame = finalFrame.offsetBy(dx: 0, dy: dy)
        } else {
            let dy = direction == .up ? -initialFrame.maxY : containerView.frame.height - initialFrame.minY
            finalFrame = initialFrame.offsetBy(dx: 0, dy: dy)
        }
        
        if isPresentation {
            transitionContext.containerView.addSubview(presentedView)
        }
        presentedView.frame = initialFrame
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0.0,
                       usingSpringWithDamping: isPresentation ? 0.7 : 1.0,
                       initialSpringVelocity: 0.0,
                       options: isPresentation ? .curveEaseOut : .curveEaseIn,
                       animations:{ presentedView.frame = finalFrame
        }) { (finished) in
            transitionContext.completeTransition(finished)
        }
    }
}

class HUDPresentationController: UIPresentationController {
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let dimension = min(250, parentSize.height * 0.5, parentSize.width * 0.5)
        return CGSize(width: dimension, height: dimension)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {return .zero}
        var frame = CGRect.zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        return frame.offsetBy(dx: (containerView.bounds.width - frame.width) / 2, dy: (containerView.bounds.height - frame.height) / 2)
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

enum HUDAnimationDirection {
    case up, down
}
#endif
