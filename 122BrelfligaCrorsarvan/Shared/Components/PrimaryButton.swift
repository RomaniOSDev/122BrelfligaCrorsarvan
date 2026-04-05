//
//  PrimaryButton.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppStyle.buttonRadius, style: .continuous)
                        .fill(AppStyle.primaryButtonFill)
                        .shadow(color: Color.appPrimary.opacity(0.45), radius: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.buttonRadius, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppStyle.buttonRadius, style: .continuous)
                        .fill(AppStyle.secondaryButtonFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.buttonRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.85), Color.appPrimary.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.appPrimary.opacity(0.15), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}
