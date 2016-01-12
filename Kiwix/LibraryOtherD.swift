//
//  LibraryOtherD.swift
//  Kiwix
//
//  Created by Chris on 12/15/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension LibraryTBVC: DownloaderDelegate {
    
    // MARK: - LibraryRefresherDelegate
    
    func startedRetrievingLibrary() {
        cloudMessageItem.setText(messageLabelTextForOnlineTab, animated: true)
    }
    
    func startedProcessingLibrary() {
        cloudMessageItem.setText(messageLabelTextForOnlineTab, animated: true)
    }
    
    func finishedProcessingLibrary() {
        cloudMessageItem.setText(messageLabelTextForOnlineTab, animated: true)
        showPreferredLanguageAlertIfNeeded()
    }
    
    func failedWithErrorMessage(message: String) {
        // show message, delay some time then do a normal refresh
    }
    
    // MARK: - BookCellDelegate 
    
    func didTapOnAccessoryViewForCell(cell: BookTableCell) {
        guard let indexPath = tableView.indexPathForCell(cell) else {return}
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            didTapOnCloudBookCellAccessory(indexPath)
        case 1:
            didTapOnDownloadBookCellAccessory(indexPath)
        case 2:
            didTapOnLocalBookCellAccessory(indexPath)
        default:
            break
        }
    }
    
    func didTapOnCloudBookCellAccessory(indexPath: NSIndexPath) {
        guard let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        switch book.spaceState {
        case .Enough:
            UIApplication.downloader.startDownloadBook(book)
        case .Caution:
            let actionProceed = UIAlertAction(title: LocalizedStrings.proceed, style: .Default, handler: { (action) -> Void in
                UIApplication.downloader.startDownloadBook(book)
            })
            let actionCancel = UIAlertAction(title: LocalizedStrings.cancel, style: .Cancel, handler: nil)
            let alert = UIAlertController(title: LocalizedStrings.spaceAlert, message: LocalizedStrings.spaceAlertMessage, actions: [actionProceed, actionCancel])
            navigationController?.presentViewController(alert, animated: true, completion: nil)
        case .NotEnough:
            let actionCancel = UIAlertAction(title: LocalizedStrings.ok, style: .Cancel, handler: nil)
            let alert = UIAlertController(title: LocalizedStrings.notEnoughSpaceTitle, message: LocalizedStrings.notEnoughSpaceMessage, actions: [actionCancel])
            navigationController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func didTapOnDownloadBookCellAccessory(indexPath: NSIndexPath) {
        guard let downloadTask = selectedFetchedResultController.objectAtIndexPath(indexPath) as? DownloadTask else {return}
        guard let book = downloadTask.book else {return}
        guard let state = downloadTask.state else {return}
        switch state {
        case .Downloading, .Queued:
            UIApplication.downloader.pauseDownloadBook(book)
        case .Paused, .Error:
            UIApplication.downloader.resumeDownloadBook(book)
        }
    }
    
    func didTapOnLocalBookCellAccessory(indexPath: NSIndexPath) {
        guard let book = selectedFetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let id = book.id else {return}
        
        let actionProceed = UIAlertAction(title: LocalizedStrings.yes, style: .Default, handler: { (action) -> Void in
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                self.managedObjectContext.deleteObject(book)
            }
            
            let reader = UIApplication.multiReader.readers[id]
            guard let fileURL = reader?.fileURL else {return}
            NSFileManager.removeFile(atURL: fileURL)
        })
        let actionCancel = UIAlertAction(title: LocalizedStrings.cancel, style: .Cancel, handler: nil)
        let alert = UIAlertController(title: LocalizedStrings.deleteAlertTitle, message: LocalizedStrings.deleteAlertMessage, actions: [actionProceed, actionCancel])
        navigationController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - DownloaderDelegate
    
    func progressUpdate(progress: BookDownloadProgress) {
        guard segmentedControl.selectedSegmentIndex == 1 else {return}
        guard let taskObj = progress.book.downloadTask else {return}
        guard let indexPath = selectedFetchedResultController.indexPathForObject(taskObj) else {return}
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? DownloadBookCell else {return}
        cell.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
        guard progressShouldUpdate else {return}
        progress.calculateCurrentSpeed()
        cell.subtitleLabel.text = progress.description
        progressShouldUpdate = false
    }
}