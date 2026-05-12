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

import AuthenticationServices
import Defaults
import SwiftUI

struct User: Codable, Defaults.Serializable {
    let email: String
    let fullName: String
}

private enum AuthState {
    case loading
    case noAccount
    case account(userId: String, user: User)
}

struct SignInWithAppleView: View {
    
    @Default(.user) private var user
    @State private var authState: AuthState = .loading
    
    var body: some View {
        VStack {
            switch authState {
            case .loading:
                LoadingProgressView()
            case .noAccount:
                signInWithApple()
            case let .account(_, user):
                Text("Welcome back: \(user.fullName) (\(user.email))")
                    .font(.headline)
            }
        }
        .padding()
        .task {
            if let user {
                authState = .account(userId: "", user: user)
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
            authState = .noAccount
        }
    }
    
    @ViewBuilder
    private func signInWithApple() -> some View {
        Text("To donate on a monthly basis, please")
            .font(.headline)
        
        SignInWithAppleButton(.signUp) { authRequest in
            authRequest.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case let .success(authorization):
                switch authorization.credential {
                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                    if let email = appleIDCredential.email,
                       let fullName = appleIDCredential.fullName {
                        let currentUser = User(email: email, fullName: fullName.formatted())
                        user = currentUser
                        authState = .account(userId: appleIDCredential.user, user: currentUser)
                    } else {
                        debugPrint("\(#function) no email, no fullName")
                    }
                default:
                    // TODO: handle this
                    break
                }
            case let .failure(error):
                debugPrint("\(#function) error: \(error)")
            }
        }
    }
}

#Preview {
    SignInWithAppleView()
}
