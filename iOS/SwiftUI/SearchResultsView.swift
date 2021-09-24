//
//  SearchResultsView.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import Defaults
import RealmSwift

class SearchResultsHostingController: UIViewController, UISearchResultsUpdating {
    private var viewModel = ViewModel()
    private var queue = OperationQueue()
    private var bottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        queue.maxConcurrentOperationCount = 1
        
        let controller = UIHostingController(rootView: SearchResultsView().environmentObject(viewModel))
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            view.leftAnchor.constraint(equalTo: controller.view.leftAnchor),
            view.rightAnchor.constraint(equalTo: controller.view.rightAnchor),
        ])
        bottomConstraint = view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        bottomConstraint?.isActive = true
        controller.didMove(toParent: self)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardEvent(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardEvent(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Keyboard Events
    // These section of code is necessary because SwiftUI keyboard avoidance does not work as expected on iPadOS 14
    
    @objc func handleKeyboardEvent(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
              let animationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
        else {return}
        
        let height = view.convert(keyboardEndFrame, from: nil).intersection(view.bounds).height
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: animationCurve)) {
            self.bottomConstraint?.constant = height
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else { return }
        viewModel.searchTextPublisher.send(searchController.searchBar.text ?? "")
    }
}

private class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    @Published var onDeviceZimFiles = [String: ZimFile]()
    
    let searchTextPublisher = CurrentValueSubject<String, Never>("")
    private var searchSubscriber: AnyCancellable?
    private var collectionSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            searchSubscriber = database.objects(ZimFile.self)
                .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
                    NSPredicate(format: "includedInSearch == true"),
                ]))
                .collectionPublisher
                .freeze()
                .map { Array($0.map({ $0.fileID })) }
                .catch { _ in Just([]) }
                .combineLatest(searchTextPublisher)
                .sink { zimFileIDs, searchText in
                    self.updateSearchResults(searchText, Set(zimFileIDs))
                }
            collectionSubscriber = database.objects(ZimFile.self)
                .filter(NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue))
                .collectionPublisher
                .freeze()
                .map { zimFiles in
                    Dictionary(zimFiles.map { ($0.fileID, $0) }, uniquingKeysWith: { $1 })
                }
                .catch { _ in Just([String: ZimFile]()) }
                .assign(to: \.onDeviceZimFiles, on: self)
        } catch { }
    }
    
    func updateRecentSearchTexts() {
        var searchTexts = Defaults[.recentSearchTexts]
        if let index = searchTexts.firstIndex(of: searchText) {
            searchTexts.remove(at: index)
        }
        searchTexts.insert(searchText, at: 0)
        if searchTexts.count > 20 {
            searchTexts = Array(searchTexts[..<20])
        }
        Defaults[.recentSearchTexts] = searchTexts
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        self.searchText = searchText
        inProgress = true
        
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self.results = operation.results
                self.inProgress = self.queue.operationCount > 0
            }
        }
        queue.addOperation(operation)
    }
}

private struct SearchResultsView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if viewModel.onDeviceZimFiles.isEmpty {
            InfoView(
                imageSystemName: "magnifyingglass",
                title: "Nothing to search",
                help: "Add some zim files first, then start a search again."
            )
        } else if horizontalSizeClass == .regular {
            SplitView().edgesIgnoringSafeArea(.all)
        } else if viewModel.searchText.isEmpty {
            FilterView()
        } else if viewModel.inProgress {
            ActivityIndicator()
        } else if viewModel.results.isEmpty {
            InfoView(
                imageSystemName: "magnifyingglass",
                title: "No results",
                help: "Update the search text or include more zim files in search."
            )
        } else {
            ResultsListView()
        }
    }
}

private struct SplitView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: ViewModel
    
    func makeUIViewController(context: Context) -> UISplitViewController {
        let controller = UISplitViewController()
        controller.preferredDisplayMode = .allVisible
        controller.presentsWithGesture = false
        controller.viewControllers = [UIHostingController(rootView: FilterView()), UIViewController()]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
        guard uiViewController.viewControllers.count == 2 else { return }
        uiViewController.viewControllers[1] = UIHostingController(rootView: content)
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.searchText.isEmpty {
            InfoView(
                imageSystemName: "magnifyingglass",
                title: "No results",
                help: "Enter some text to start a search."
            )
        } else if viewModel.inProgress  {
            ActivityIndicator()
        } else if viewModel.results.isEmpty {
            InfoView(
                imageSystemName: "magnifyingglass",
                title: "No results",
                help: "Update the search text or include more zim files in search."
            )
        } else {
            GeometryReader { geometry in
                ResultsListView()
                    .padding(.horizontal, max(0, (geometry.size.width - 700) / 2))
                    .environmentObject(self.viewModel) // HACK: this line seems to be required on iPadOS 13 simulator
            }
        }
   }
}

private struct FilterView: View {
    @Default(.recentSearchTexts) var recentSearchTexts
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) var zimFiles
    
    var body: some View {
        List {
            if recentSearchTexts.count > 0 {
                Section(header: HStack {
                    Text("Recent")
                    Spacer()
                    Button("Clear", action: { recentSearchTexts = [] }).foregroundColor(.secondary)
                }) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(recentSearchTexts, id: \.hash) { searchText in
                                Button {
                                    guard var url = URL(string: "kiwix://search/") else { return }
                                    url.appendPathComponent(searchText)
                                    UIApplication.shared.open(url)
                                } label: {
                                    Text(searchText)
                                        .font(.callout)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 2)
                                        .foregroundColor(.white)
                                        .background(Color.blue.cornerRadius(CGFloat.infinity))
                                }
                            }
                        }.padding(.horizontal, 16)
                    }.listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }
            if zimFiles.count > 0 {
                Section(header: HStack {
                    Text("Search Filter")
                    Spacer()
                    if zimFiles.count == zimFiles.filter({ $0.includedInSearch }).count {
                        Button("None", action: { excludeAllInSearch() }).foregroundColor(.secondary)
                    } else {
                        Button("All", action: { includeAllInSearch() }).foregroundColor(.secondary)
                    }
                }) {
                    ForEach(zimFiles) { zimFile in
                        Button { toggleSearch(zimFile.fileID) } label: {
                            ListRow(
                                title: zimFile.title,
                                detail: zimFile.description,
                                faviconData: zimFile.faviconData,
                                accessories: zimFile.includedInSearch ? [.includedInSearch] : []
                            )
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
    
    private func toggleSearch(_ zimFileID: String) {
        guard let database = try? Realm(),
              let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
        try? database.write {
            zimFile.includedInSearch = !zimFile.includedInSearch
        }
    }
    
    private func includeAllInSearch() {
        guard let database = try? Realm() else { return }
        try? database.write {
            database.objects(ZimFile.self)
                .filter(NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue))
                .forEach { $0.includedInSearch = true }
        }
    }
    
    private func excludeAllInSearch() {
        guard let database = try? Realm() else { return }
        try? database.write {
            database.objects(ZimFile.self)
                .filter(NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue))
                .forEach { $0.includedInSearch = false }
        }
    }
}

private struct ResultsListView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.results) { result in
                Button {
                    UIApplication.shared.open(result.url)
                    viewModel.updateRecentSearchTexts()
                } label: {
                    HStack(alignment: result.snippet == nil ? .center : .top) {
                        Favicon(data: viewModel.onDeviceZimFiles[result.zimFileID]?.faviconData)
                        VStack(alignment: .leading) {
                            Text(result.title).fontWeight(.medium).lineLimit(1)
                            if #available(iOS 15.0, *), let snippet = result.snippet {
                                Text(AttributedString(snippet)).font(.caption)
                            } else if let snippet = result.snippet?.string {
                                Text(snippet).font(.caption)
                            }
                        }.foregroundColor(.primary)
                    }
                }
            }
        }.listStyle(PlainListStyle())
    }
}

private struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .large)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}
