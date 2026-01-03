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

struct DownloadHeadCheck {
    
    enum ErrorResponse: Hashable, Identifiable {
        var id: Int { hashValue }
        
        case invalidRequest(line: Int)
        case invalidResponse(line: Int, requestURL: URL)
        case responseError(line: Int, description: String)
        case responseURLError(line: Int, urlError: URLError)
        case invalid(statusCode: Int, requestURL: URL)
        
        var message: String {
            switch self {
            case .invalidRequest(let line):
                "Invalid request code: \(line)"
            case .invalidResponse(let line, let requestURL):
                "Invalid response code: \(line) for url: \(requestURL.absoluteString)"
            case .responseError(let line, let description):
                "Response error code: \(line), reason: \(description)"
            case .responseURLError(let line, let urlError):
                "\(urlError.localizedDescription)\nURL: \(urlError.failingURL, default: "unkown"), errorCodes: \(line) | \(urlError.errorCode)"
            case .invalid(let statusCode, let requestURL):
                "Invalid status code: \(statusCode),\nfor url: \(requestURL)"
            }
        }
    }
    
    func check(task: URLSessionDownloadTask) async -> ErrorResponse? {
        guard let request = task.originalRequest,
              let url = request.url else {
            return ErrorResponse.invalidRequest(line: #line)
        }
        var headRequest = request
        headRequest.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: headRequest)
            
            guard let httpResponse = (response as? HTTPURLResponse) else {
                return ErrorResponse.invalidResponse(line: #line, requestURL: url)
            }
            let statusCode = httpResponse.statusCode
            guard ((200..<300)).contains(statusCode) else {
                return ErrorResponse.invalid(statusCode: statusCode, requestURL: url)
            }
            // no error
            return nil
        } catch {
            if let urlError = error as? URLError {
                return ErrorResponse.responseURLError(line: #line, urlError: urlError)
            } else {
                return ErrorResponse.responseError(line: #line, description: error.localizedDescription)
            }
        }
    }
}
