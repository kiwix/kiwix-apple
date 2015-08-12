//
//  BookOrdinaryCell.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

enum BookDownloadState {
    case GoAhead
    case WithCaution
    case NotAllowed
    case Finished
    case CanPause
    case CanResume
}

class BookOrdinaryCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var bookCellAccessoryView: BookCellAccessoryView!
    var indexPath: NSIndexPath? = nil
    var delegate: BookCellDelegate?
    var downloadState: BookDownloadState = .GoAhead {
        willSet(newState) {
            for subView in bookCellAccessoryView.subviews {
                subView.removeFromSuperview()
            }
            assert((newState != .CanPause || newState != .CanResume), "Error: BookOrdinaryCell.state = \(newState)")
            switch newState {
            case .GoAhead:
                addDownloadStateIcon(DownloadGoAheadIconView())
            case .WithCaution:
                addDownloadStateIcon(DownloadWithCautionIconView())
            case .NotAllowed:
                addDownloadStateIcon(DownloadNotAllowedIconView())
            case .Finished:
                addDownloadStateIcon(DownloadFinishedIconView())
            default:
                return
            }
        }
    }
    
    func addDownloadStateIcon(view: UIView) {
        view.frame = bookCellAccessoryView.bounds
        view.backgroundColor = UIColor.clearColor()
        bookCellAccessoryView.addSubview(view)
    }
    
    override func awakeFromNib() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap")
        bookCellAccessoryView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(atIndexPath: indexPath)
    }
}

class BookDownloadingCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var articleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var bookCellAccessoryView: BookCellAccessoryView!
    
    var indexPath: NSIndexPath? = nil
    var delegate: BookCellDelegate?
    var downloadState: BookDownloadState = .CanPause {
        willSet(newState) {
            for subView in bookCellAccessoryView.subviews {
                subView.removeFromSuperview()
            }
            assert((newState == .CanPause || newState == .CanResume), "Error: BookDownloadingCell.state = \(newState)")
            switch newState {
            case .CanPause:
                addDownloadStateIcon(DownloadPauseIconView())
            case .CanResume:
                addDownloadStateIcon(DownloadResumeIconView())
            default:
                return
            }
        }
    }
    
    func addDownloadStateIcon(view: UIView) {
        view.frame = bookCellAccessoryView.bounds
        view.backgroundColor = UIColor.clearColor()
        bookCellAccessoryView.addSubview(view)
    }
    
    override func prepareForReuse() {
        progressView.setProgress(0.0, animated: false)
    }
    
    override func awakeFromNib() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap")
        bookCellAccessoryView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(atIndexPath: indexPath)
    }
}

protocol BookCellDelegate {
    func didTapOnAccessoryViewForCell(atIndexPath indexPath: NSIndexPath?)
}
