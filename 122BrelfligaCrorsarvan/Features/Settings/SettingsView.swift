//
//  SettingsView.swift
//  122BrelfligaCrorsarvan
//

import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        ScrollScreen {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Feedback, App Store review, and legal documents.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                VStack(spacing: 0) {
                    settingsRow(
                        title: "Rate us",
                        systemImage: "star.fill",
                        tint: Color.appAccent
                    ) {
                        rateApp()
                    }

                    Divider().background(Color.appTextSecondary.opacity(0.25))

                    settingsRow(
                        title: "Privacy Policy",
                        systemImage: "hand.raised.fill",
                        tint: Color.appPrimary
                    ) {
                        openPolicy(.privacyPolicy)
                    }

                    Divider().background(Color.appTextSecondary.opacity(0.25))

                    settingsRow(
                        title: "Terms of Use",
                        systemImage: "doc.text.fill",
                        tint: Color.appPrimary
                    ) {
                        openPolicy(.termsOfUse)
                    }
                }
                .appCardElevated(cornerRadius: AppStyle.cardRadius)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, alignment: .center)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.7))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openPolicy(_ link: AppExternalURL) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
