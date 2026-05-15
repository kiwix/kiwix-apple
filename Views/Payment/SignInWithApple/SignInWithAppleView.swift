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
    
    /// Check if the user deleted / revoked the Apple Sign In
    /// account link to Kiwix in System Settings
    /// - Returns: true if the account has been deleted
    func isSignInRevoked() async -> Bool {
        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userId)
        switch state {
        case .some(.revoked):
            // the only case when we are certain we should delete user account details
            return true
        default:
            return false
        }
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

struct SignInWithAppleView<Content: View>: View {
    
    @Default(.userAccount) private var userAccount: UserAccount?
    @State private var authState: AuthState = .loading
    private let didLogedInContent: (UserAccount) -> Content
    
    init(@ViewBuilder didLogedInContent: @escaping (UserAccount) -> Content) {
        self.didLogedInContent = didLogedInContent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            switch authState {
            case .loading:
                LoadingProgressView()
            case .noAccount:
                title(text: "To donate on a monthly basis, please")
                appleButton(label: .signUp)
            case .expired(_):
                title(text: "To manage your monthly donations, please")
                appleButton(label: .signIn)
            case let .loggedIn(userAccount):
                didLogedInContent(userAccount)
            case .errorLogin:
                title(text: "Ooops! Something went wrong.")
                    .foregroundStyle(.red)
                appleButton(label: .signIn)
            }
        }
        .task {
            guard let userAccount else {
                authState = .noAccount
                return
            }
            guard await userAccount.isSignInRevoked() == false else {
                self.userAccount = nil // delete it
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
    private func title(text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)
            .modifier(LineHeightModifier(value: 28))
    }
    
    @ViewBuilder
    private func appleButton(label: SignInWithAppleButton.Label) -> some View {
        VStack(spacing: 32) {
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
                            Log.Payment.error("no current account locally, haven't received email and/or fullName")
                        }
                    default:
                        Log.Payment.error("invalid type of credentials recieved: \(authorization.credential.description)")
                        authState = .errorLogin(userId: nil)
                    }
                case let .failure(error):
                    Log.Payment.error("Apple Sign in failed with: \(error.localizedDescription)")
                    authState = .errorLogin(userId: nil)
                }
            }
            .frame(maxWidth: 320)
            
            // security note
            Text("Apple Pay donations are securely encrypted and verified using native security frameworks.")
                .foregroundStyle(.tertiary)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .font(.system(size: 12))
                .fontWeight(.medium)
        }
    }
}

private struct LineHeightModifier: ViewModifier {
    let value: CGFloat
    
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .lineHeight(.exact(points: value))
        } else {
            content
        }
    }
}
