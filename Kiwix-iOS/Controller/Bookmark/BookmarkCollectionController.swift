//
//  BookmarkCollectionController.swift
//  Kiwix
//
//  Created by Chris Li on 1/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class BookmarkCollectionController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    private(set) var itemWidth: CGFloat = 0.0
    private(set) var shouldReloadCollectionView = false
    @IBOutlet weak var collectionView: UICollectionView!
    @IBAction func removaAll(_ sender: UIBarButtonItem) {
        let context = AppDelegate.persistentContainer.viewContext
        context.perform {
            let fetchRequest = Article.fetchRequest() as! NSFetchRequest<Article>
            let articles = try? context.fetch(fetchRequest)
            articles?.forEach({ (article) in
                context.delete(article)
            })
            try? context.save()
        }
    }
    
    var book: Book? {
        didSet {
            title = book?.title ?? "All"
        }
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func configureItemWidth(collectionViewWidth: CGFloat) {
        let itemsPerRow = ((collectionViewWidth - 10) / 320).rounded()
        self.itemWidth = floor((collectionViewWidth - (itemsPerRow + 1) * 10) / itemsPerRow)
    }
    
    // MARK: - override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.alwaysBounceVertical = true
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureItemWidth(collectionViewWidth: collectionView.frame.width)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        configureItemWidth(collectionViewWidth: collectionView.frame.width)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - UICollectionView Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! BookmarkCollectionCell
        let article = fetchedResultController.object(at: indexPath)
        cell.titleLabel.text = article.title
        cell.snippetLabel.text = article.snippet
        if let data = article.thumbImageData {
            cell.thumbImageView.image = UIImage(data: data)
        }
        cell.bookTitleLabel.text = article.book?.title
        if let date = article.bookmarkDate {cell.bookmarkDetailLabel.text = dateFormatter.string(from: date)}
        
        return cell
    }
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let article = fetchedResultController.object(at: indexPath)
        guard let url = article.url else {return}
        GlobalQueue.shared.add(articleLoadOperation: ArticleLoadOperation(url: url))
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemWidth, height: itemWidth * 0.72)
    }
    
    // MARK: - NSFetchedResultsController
    
    private var closures = [() -> Void]()
    let managedObjectContext = AppDelegate.persistentContainer.viewContext
    lazy var fetchedResultController: NSFetchedResultsController<Article> = {
        let fetchRequest = Article.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false)]
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "isBookmarked = true"))
        if let book = self.book { predicates.append(NSPredicate(format: "book == %@", book)) }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        try? controller.performFetch()
        return controller as! NSFetchedResultsController<Article>
    }()
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard collectionView.numberOfSections > 0,
                let newIndexPath = newIndexPath,
                collectionView.numberOfItems(inSection: newIndexPath.section) > 0 else {
                    shouldReloadCollectionView = true
                    break
            }
            closures.append({ [weak self] in self?.collectionView.insertItems(at: [newIndexPath]) })
        case .delete:
            guard let indexPath = indexPath else {break}
            closures.append({ [weak self] in self?.collectionView.deleteItems(at: [indexPath]) })
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {break}
            closures.append({ [weak self] in self?.collectionView.moveItem(at: indexPath, to: newIndexPath) })
        case .update:
            guard let indexPath = indexPath, collectionView.numberOfItems(inSection: indexPath.section) != 1 else {
                self.shouldReloadCollectionView = true
                break
            }
            closures.append({ [weak self] in self?.collectionView.reloadItems(at: [indexPath]) })
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            closures.append({ [weak self] in self?.collectionView.insertSections(IndexSet(integer: sectionIndex)) })
        case .delete:
            closures.append({ [weak self] in self?.collectionView.deleteSections(IndexSet(integer: sectionIndex)) })
        case .move:
            break
        case .update:
            closures.append({ [weak self] in self?.collectionView.reloadSections(IndexSet(integer: sectionIndex)) })
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        OperationQueue.main.addOperation({
            if self.shouldReloadCollectionView {
                self.collectionView.reloadData()
            } else {
                self.collectionView.performBatchUpdates({ 
                    self.closures.forEach({ $0() })
                }, completion: { (completed) in
                    self.closures.removeAll()
                })
            }
        })
    }
}

