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
