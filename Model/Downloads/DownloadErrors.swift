// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation

enum DownloadErrors {
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    static func localizedString(from error: NSError) -> String {
        guard let urlError = error as? URLError, error.domain == NSURLErrorDomain.description else {
            return error.localizedDescription
        }
        switch urlError.code {
        case .backgroundSessionInUseByAnotherProcess:
            return LocalString.download_service_error_client_backgroundsessioninusebyanotherprocess
        case .backgroundSessionWasDisconnected:
            return LocalString.download_service_error_client_backgroundsessionwasdisconnected
        case .cancelled:
            return LocalString.download_service_error_client_cancelled
        case .badURL:
            return LocalString.download_service_error_client_badurl
        case .timedOut:
            return LocalString.download_service_error_client_timedout
        case .unsupportedURL:
            return LocalString.download_service_error_client_unsupportedurl
        case .cannotFindHost:
            return LocalString.download_service_error_client_cannotfindhost
        case .cannotConnectToHost:
            return LocalString.download_service_error_client_cannotconnecttohost
        case .networkConnectionLost:
            return LocalString.download_service_error_client_networkconnectionlost
        case .dnsLookupFailed:
            return LocalString.download_service_error_client_dnslookupfailed
        case .httpTooManyRedirects:
            return LocalString.download_service_error_client_httptoomanyredirects
        case .resourceUnavailable:
            return LocalString.download_service_error_client_resourceunavailable
        case .notConnectedToInternet:
            return LocalString.download_service_error_client_notconnectedtointernet
        case .redirectToNonExistentLocation:
            return LocalString.download_service_error_client_redirecttononexistentlocation
        case .badServerResponse:
            return LocalString.download_service_error_client_badserverresponse
        case .zeroByteResource:
            return LocalString.download_service_error_client_zerobyteresource
        case .cannotDecodeRawData:
            return LocalString.download_service_error_client_cannotdecoderawdata
        case .cannotDecodeContentData:
            return LocalString.download_service_error_client_cannotdecodecontentdata
        case .cannotParseResponse:
            return LocalString.download_service_error_client_cannotparseresponse
        case .internationalRoamingOff:
            return LocalString.download_service_error_client_internationalroamingoff
        case .callIsActive:
            return LocalString.download_service_error_client_callisactive
        case .dataNotAllowed:
            return LocalString.download_service_error_client_datanotallowed
        case .requestBodyStreamExhausted:
            return LocalString.download_service_error_client_requestbodystreamexhausted
        case .fileDoesNotExist:
            return LocalString.download_service_error_client_filedoesnotexist
        case .fileIsDirectory:
            return LocalString.download_service_error_client_fileisdirectory
        case .noPermissionsToReadFile:
            return LocalString.download_service_error_client_nopermissionstoreadfile
        case .dataLengthExceedsMaximum:
            return LocalString.download_service_error_client_datalengthexceedsmaximum
        case .secureConnectionFailed:
            return LocalString.download_service_error_client_secureconnectionfailed
        case .serverCertificateHasBadDate:
            return LocalString.download_service_error_client_servercertificatehasbaddate
        case .serverCertificateUntrusted:
            return LocalString.download_service_error_client_servercertificateuntrusted
        case .serverCertificateHasUnknownRoot:
            return LocalString.download_service_error_client_servercertificatehasunknownroot
        case .serverCertificateNotYetValid:
            return LocalString.download_service_error_client_servercertificatenotyetvalid
        case .clientCertificateRejected:
            return LocalString.download_service_error_client_clientcertificaterejected
        case .clientCertificateRequired:
            return LocalString.download_service_error_client_clientcertificaterequired
        case .cannotLoadFromNetwork:
            return LocalString.download_service_error_client_cannotloadfromnetwork
        case .cannotCreateFile:
            return LocalString.download_service_error_client_cannotcreatefile
        case .cannotOpenFile:
            return LocalString.download_service_error_client_cannotopenfile
        case .cannotCloseFile:
            return LocalString.download_service_error_client_cannotclosefile
        case .cannotWriteToFile:
            return LocalString.download_service_error_client_cannotwritetofile
        case .cannotRemoveFile:
            return LocalString.download_service_error_client_cannotremovefile
        case .cannotMoveFile:
            return LocalString.download_service_error_client_cannotmovefile
        case .downloadDecodingFailedMidStream:
            return LocalString.download_service_error_client_downloaddecodingfailedmidstream
        case .downloadDecodingFailedToComplete:
            return LocalString.download_service_error_client_downloaddecodingfailedtocomplete
        default:
            return urlError.localizedDescription
        }
        
    }
}

// MARK: - Direct Write Download Errors (macOS only)

#if os(macOS)
/// Errors specific to the direct-write download system on macOS.
/// These errors occur when downloading directly to a custom directory (e.g., external drive).
enum DirectWriteDownloadError: LocalizedError {
    /// The destination directory doesn't exist or is not accessible
    case destinationNotAccessible(path: String)
    
    /// Not enough free space on the destination volume
    case insufficientDiskSpace(required: Int64, available: Int64)
    
    /// The destination volume was unmounted during download
    case volumeUnmounted(path: String)
    
    /// Cannot create file at the destination
    case cannotCreateFile(path: String, underlyingError: Error?)
    
    /// Cannot write to the file (I/O error during download)
    case writeError(path: String, underlyingError: Error?)
    
    /// Server doesn't support range requests (required for resume)
    case rangeRequestsNotSupported
    
    /// The partial file was modified or corrupted
    case partialFileCorrupted(path: String)
    
    /// Invalid HTTP response from server
    case invalidServerResponse(statusCode: Int)
    
    /// Download was cancelled by user
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .destinationNotAccessible(let path):
            return String(
                format: NSLocalizedString(
                    "The download directory is not accessible: %@",
                    comment: "Error when download directory is not accessible"
                ),
                path
            )
        case .insufficientDiskSpace(let required, let available):
            let requiredStr = ByteCountFormatter.string(fromByteCount: required, countStyle: .file)
            let availableStr = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            return String(
                format: NSLocalizedString(
                    "Not enough disk space. Required: %@, Available: %@",
                    comment: "Error when there's not enough disk space"
                ),
                requiredStr, availableStr
            )
        case .volumeUnmounted(let path):
            return String(
                format: NSLocalizedString(
                    "The volume was disconnected during download: %@",
                    comment: "Error when volume is unmounted during download"
                ),
                path
            )
        case .cannotCreateFile(let path, _):
            return String(
                format: NSLocalizedString(
                    "Cannot create file at: %@",
                    comment: "Error when file cannot be created"
                ),
                path
            )
        case .writeError(let path, _):
            return String(
                format: NSLocalizedString(
                    "Error writing to file: %@",
                    comment: "Error during file write"
                ),
                path
            )
        case .rangeRequestsNotSupported:
            return NSLocalizedString(
                "The server doesn't support resumable downloads",
                comment: "Error when server doesn't support range requests"
            )
        case .partialFileCorrupted(let path):
            return String(
                format: NSLocalizedString(
                    "The partial download file is corrupted: %@",
                    comment: "Error when partial file is corrupted"
                ),
                path
            )
        case .invalidServerResponse(let statusCode):
            return String(
                format: NSLocalizedString(
                    "Invalid server response (HTTP %d)",
                    comment: "Error for invalid HTTP response"
                ),
                statusCode
            )
        case .cancelled:
            return NSLocalizedString(
                "Download was cancelled",
                comment: "Error when download is cancelled"
            )
        }
    }
}
#endif
