//
//  SearchResultsView.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
private class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var inProgress = false
    @Published var results = [SearchResult]()
    @Published var recentSearchTexts = UserDefaults.standard.recentSearchTexts
    @ObservedResults(
        ZimFile.self,
        configuration: Realm.defaultConfig,
        filter: NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
        sortDescriptor: SortDescriptor(keyPath: "size", ascending: false)
    ) var zimFiles
    
    var searchTextPublisher = CurrentValueSubject<String, Never>("")
    private var searchObserver: AnyCancellable?
    private var queue = OperationQueue()
    
    init() {
        queue.maxConcurrentOperationCount = 1
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue),
                NSPredicate(format: "includedInSearch == true"),
            ])
            searchObserver = database.objects(ZimFile.self).filter(predicate)
                .collectionPublisher
                .freeze()
                .map { zimFiles in return Array(zimFiles.map({ $0.fileID })) }
                .catch { _ in Just([]) }
                .combineLatest(searchTextPublisher)
                .sink { zimFileIDs, searchText in
                    self.updateSearchResults(searchText, Set(zimFileIDs))
                }
        } catch { }
    }
    
    func toggleZimFileIncludedInSearch(_ zimFileID: String) {
        do {
            let database = try Realm()
            guard let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) else { return }
            try database.write {
                zimFile.includedInSearch = !zimFile.includedInSearch
            }
        } catch {}
    }
    
    func includeAllZimFilesInSearch() {
        do {
            let database = try Realm()
            try database.write {
                for zimFile in database.objects(ZimFile.self) {
                    zimFile.includedInSearch = true
                }
            }
        } catch {}
    }
    
    func excludeAllZimFilesInSearch() {
        do {
            let database = try Realm()
            try database.write {
                for zimFile in database.objects(ZimFile.self) {
                    zimFile.includedInSearch = false
                }
            }
        } catch {}
    }
    
    func updateRecentSearchTexts() {
        var searchTexts = UserDefaults.standard.recentSearchTexts
        if let index = searchTexts.firstIndex(of: searchText) {
            searchTexts.remove(at: index)
        }
        searchTexts.insert(searchText, at: 0)
        if searchTexts.count > 20 {
            searchTexts = Array(searchTexts[..<20])
        }
        UserDefaults.standard.recentSearchTexts = searchTexts
        recentSearchTexts = searchTexts
    }
    
    func clearRecentSearchTexts() {
        UserDefaults.standard.recentSearchTexts = []
        recentSearchTexts = []
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<String>) {
        self.searchText = searchText
        inProgress = true
        
        queue.cancelAllOperations()
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [weak self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self?.results = operation.results
                self?.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
}

@available(iOS 13.0, *)
private struct SearchResultsView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if viewModel.zimFiles.isEmpty {
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

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
private struct FilterView: View {
    @State private var showAlert = false
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        List {
            if viewModel.recentSearchTexts.count > 0 {
                Section(header: HStack {
                    Text("Recent")
                    Spacer()
                    Button("Clear", action: {
                        if #available(iOS 14.0, *) {
                            showAlert = true
                        } else {
                            // iOS 13 simulator crashes when showing alert here, so I have to skip the alert
                            viewModel.clearRecentSearchTexts()
                        }
                    }).foregroundColor(.secondary)
                }) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(UserDefaults.standard.recentSearchTexts, id: \.hash) { searchText in
                                Button {
                                    guard let url = URL(string: "kiwix://search/\(searchText)") else { return }
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
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }
            if viewModel.zimFiles.count > 0 {
                Section(header: HStack {
                    Text("Search Filter")
                    Spacer()
                    if viewModel.zimFiles.count == viewModel.zimFiles.filter({ $0.includedInSearch }).count {
                        Button("None", action: { viewModel.excludeAllZimFilesInSearch() }).foregroundColor(.secondary)
                    } else {
                        Button("All", action: { viewModel.includeAllZimFilesInSearch() }).foregroundColor(.secondary)
                    }
                }) {
                    ForEach(viewModel.zimFiles) { zimFile in
                        Button {
                            viewModel.toggleZimFileIncludedInSearch(zimFile.fileID)
                        } label: {
                            ZimFileCell(zimFile, accessories: [.includedInSearch])
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Clear Recent Search"),
                message: Text("All recent search texts will be cleared. This action is not recoverable."),
                primaryButton: .destructive( Text("Delete"), action: { viewModel.clearRecentSearchTexts() }),
                secondaryButton: .cancel()
            )
        }
    }
}

@available(iOS 13.0, *)
private struct ResultsListView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.results) { result in
                Button {
                    UIApplication.shared.open(result.url)
                    viewModel.updateRecentSearchTexts()
                } label: {
                    HStack {
                        Favicon(data: viewModel.zimFiles.first(where: { $0.fileID == result.zimFileID })?.faviconData)
                        VStack(alignment: .leading) {
                            Text(result.title).fontWeight(.medium).lineLimit(1)
                            if let snippet = result.snippet?.string {
                                Text(snippet).font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
private struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .large)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

@available(iOS 13.0, *)
private struct InfoView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let imageSystemName: String
    let title: String
    let help: String
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer(minLength: geometry.size.height * 0.3)
                if verticalSizeClass == .regular {
                    VStack {
                        makeImage(geometry)
                        text
                    }
                } else {
                    HStack {
                        makeImage(geometry)
                        text
                    }
                }
                Spacer()
                Spacer()
            }.frame(width: geometry.size.width)
        }
    }
    
    private func makeImage(_ geometry: GeometryProxy) -> some View {
        ZStack {
            GeometryReader { geometry in
                Image(systemName: imageSystemName)
                    .resizable()
                    .padding(geometry.size.height * 0.25)
                    .foregroundColor(.secondary)
            }
            Circle().foregroundColor(.secondary).opacity(0.2)
        }.frame(
            width: max(60, min(geometry.size.height * 0.2, geometry.size.width * 0.2, 100)),
            height: max(60, min(geometry.size.height * 0.2, geometry.size.width * 0.2, 100))
        )
    }
    
    var text: some View {
        VStack(spacing: 10) {
            Text(title).font(.title).fontWeight(.medium)
            Text(help).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding()
    }
}

@available(iOS 13.0, *)
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(
            imageSystemName: "magnifyingglass",
            title: "Nothing to search",
            help: "Add some zim files first, then start a search."
        )
        .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
        .previewDisplayName("iPhone 12 Pro")
    }
}
