//
//  LibraryTBVCD.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension LibraryTBVC {
    
    // MARK: - Configure
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.selectedFetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = self.selectedFetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier: String = {
            switch segmentedControl.selectedSegmentIndex {
            case 0: return "CloudBookCell"
            case 1: return "DownloadBookCell"
            case 2: return "LocalBookCell"
            default: return "CloudBookCell"
            }
        }()
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            guard let cell = cell as? CloudBookCell else {return}
            configureCloudBookCell(cell, atIndexPath: indexPath)
        case 1:
            guard let cell = cell as? DownloadBookCell else {return}
            configureDownloadBookCell(cell, atIndexPath: indexPath)
        case 2:
            guard let cell = cell as? LocalBookCell else {return}
            configureLocalBookCell(cell, atIndexPath: indexPath)
        default:
            break
        }
    }
    
    func configureBookCell(book: Book, cell: BookTableCell, atIndexPath indexPath: NSIndexPath) {
        cell.titleLabel.text = book.title
        cell.hasPicIndicator.backgroundColor = (book.isNoPic?.boolValue ?? true) ? UIColor.lightGrayColor() : UIColor.havePicTintColor
        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
        cell.delegate = self
    }
    
    func configureCloudBookCell(cell: CloudBookCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        
        configureBookCell(book, cell: cell, atIndexPath: indexPath)
        cell.subtitleLabel.text = cloudDetailBooks.contains(book) ? book.veryDetailedDescription : book.detailedDescription
        
        switch book.spaceState {
        case .Enough:
            cell.accessoryImageTintColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
        case .Caution:
            cell.accessoryImageTintColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
        case .NotEnough:
            cell.accessoryImageTintColor = UIColor.grayColor().colorWithAlphaComponent(0.75)
        }
    }
    
    func configureDownloadBookCell(cell: DownloadBookCell, atIndexPath indexPath: NSIndexPath) {
        guard let downloadTask = selectedFetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return}
        guard let book = downloadTask.book else {return}
        
        configureBookCell(book, cell: cell, atIndexPath: indexPath)
        cell.dateLabel.text = book.dateFormatted
        cell.articleCountLabel.text = book.articleCountFormatted
        
        guard let id = book.id else {return}
        guard let progress = UIApplication.downloader.progresses[id] else {return}
        cell.subtitleLabel.text = progress.description
        cell.progressView.progress = Float(progress.fractionCompleted)
        
        guard let state = downloadTask.state else {return}
        switch state {
        case .Downloading, .Queued:
            cell.accessoryImageTintColor = UIColor.orangeColor().colorWithAlphaComponent(0.75)
            cell.accessoryImageView.highlighted = false
        case .Paused, .Error:
            cell.accessoryHighlightedImageTintColor = UIColor.greenColor().colorWithAlphaComponent(0.75)
            cell.accessoryImageView.highlighted = true
        }
    }
    
    func configureLocalBookCell(cell: LocalBookCell, atIndexPath indexPath: NSIndexPath) {
        guard let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        
        configureBookCell(book, cell: cell, atIndexPath: indexPath)
        cell.subtitleLabel.text = localDetailBooks.contains(book) ? book.veryDetailedDescription : book.detailedDescription
        cell.accessoryImageTintColor = UIColor.redColor().colorWithAlphaComponent(0.75)
    }
    
    // MARK: - Table View  Data Source
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard segmentedControl.selectedSegmentIndex != 1 else {return nil}
        guard tableView.numberOfSections > 1 else {return nil}
        guard let langName = self.selectedFetchedResultController.sections?[section].name else {return nil}
        return langName
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard segmentedControl.selectedSegmentIndex != 1 else {return nil}
        let sectionIndexTitles = self.selectedFetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 && segmentedControl.selectedSegmentIndex == 0 else {return nil}
        return sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return self.selectedFetchedResultController.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if cloudDetailBooks.contains(book) {
                cloudDetailBooks.remove(book)
            } else {
                cloudDetailBooks.insert(book)
            }
        case 2:
            if localDetailBooks.contains(book) {
                localDetailBooks.remove(book)
            } else {
                localDetailBooks.insert(book)
            }
        default:
            break
        }
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.numberOfSections > 1 else {return 0.0}
        guard segmentedControl.selectedSegmentIndex != 1 else {return 0.0}
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard segmentedControl.selectedSegmentIndex != 1 else {return}
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFontOfSize(14)
    }
    
    // MARK: - Table View Edit
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return segmentedControl.selectedSegmentIndex == 1 ? true : false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let cancelAction = UITableViewRowAction(style: .Destructive, title: LocalizedStrings.cancel) { (action, indexPath) -> Void in
            guard let downloadTask = self.selectedFetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return}
            self.managedObjectContext.deleteObject(downloadTask)
            guard let book = downloadTask.book else {return}
            UIApplication.downloader.cancelDownloadBookAndNotProduceResumeData(book)
        }
        return [cancelAction]
    }
}

