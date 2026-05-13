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

struct UserAccount: Codable, Defaults.Serializable {
    static private let hours24: TimeInterval = 24 * 60 * 60 // in seconds
    // instead of decoding the JWT token, we can set the expiry to the very same 24 hours
    static func defaultExpiry() -> TimeInterval {
        Date().addingTimeInterval(Self.hours24).timeIntervalSince1970
    }
    
    let userId: String
    let email: String
    let fullName: String
    let jwt: Data
    let expiry: TimeInterval
    
    func updatingWith(jwt newJWT: Data) -> UserAccount {
        UserAccount(
            userId: userId,
            email: email,
            fullName: fullName,
            jwt: newJWT,
            expiry: Self.defaultExpiry()
        )
    }
    
    func isExpired() -> Bool {
        expiry <= Date().timeIntervalSince1970
    }
}

private enum AuthState {
    case loading
    case noAccount
    case expired(userId: String) // userId from ASAuthorizationAppleIDCredential.user
    case loggedIn(userAccount: UserAccount)
    case errorLogin(userId: String?)
}

struct SignInWithAppleView: View {
    
    @Default(.userAccount) private var userAccount
    @State private var authState: AuthState = .loading
    
    var body: some View {
        VStack {
            switch authState {
            case .loading:
                LoadingProgressView()
            case .noAccount:
                Text("To donate on a monthly basis, please")
                    .font(.headline)
                signInWithApple()
            case .expired(_):
                continueWithApple()
            case let .loggedIn(userAccount):
                Text("Welcome back: \(userAccount.fullName) (\(userAccount.email))").font(.headline)
            case .errorLogin:
                Text("Ooops! Something went wrong.")
                signInWithApple()
            }
        }
        .padding()
        .task {
            guard let userAccount else {
                authState = .noAccount
                return
            }
            if userAccount.isExpired() {
                authState = .expired(userId: userAccount.userId)
            } else {
                authState = .loggedIn(userAccount: userAccount)
            }
        }
    }
    
    @ViewBuilder
    private func continueWithApple() -> some View {
        appleButton(label: .continue)
    }
    
    @ViewBuilder
    private func signInWithApple() -> some View {
        appleButton(label: .signIn)
    }
    
    @ViewBuilder
    private func appleButton(label: SignInWithAppleButton.Label) -> some View {
        SignInWithAppleButton(label) { authRequest in
            authRequest.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case let .success(authorization):
                switch authorization.credential {
                case let credential as ASAuthorizationAppleIDCredential:
                    guard let token = credential.identityToken else {
                        authState = .errorLogin(userId: credential.user)
                        return
                    }
                    if let current = userAccount {
                        let verifiedAccount = current.updatingWith(jwt: token)
                        userAccount = verifiedAccount // save it
                        authState = .loggedIn(userAccount: verifiedAccount)
                    } else if let email = credential.email, let fullName = credential.fullName {
                        let verifiedAccount = UserAccount(
                            userId: credential.user,
                            email: email,
                            fullName: fullName.formatted(),
                            jwt: token,
                            expiry: UserAccount.defaultExpiry()
                        )
                        userAccount = verifiedAccount // save it
                        authState = .loggedIn(userAccount: verifiedAccount)
                    } else {
                        authState = .errorLogin(userId: credential.user)
                        debugPrint("\(#function) no current account locally, haven't received email and/or fullName")
                    }
                default:
                    debugPrint("\(#function) invalid type of credentials recieved: \(authorization.credential)")
                    authState = .errorLogin(userId: nil)
                }
            case let .failure(error):
                debugPrint("\(#function) error: \(error)")
                authState = .errorLogin(userId: nil)
            }
        }
    }
}

#Preview {
    SignInWithAppleView()
}
