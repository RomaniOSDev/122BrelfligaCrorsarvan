//
//  VisualStyle.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

enum AppStyle {
    static let cardRadius: CGFloat = 20
    static let panelRadius: CGFloat = 22
    static let buttonRadius: CGFloat = 16

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appSurface.opacity(0.35),
                Color.appBackground.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surfaceFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface,
                Color.appSurface.opacity(0.88),
                Color.appPrimary.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var rimStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.appAccent.opacity(0.45),
                Color.appPrimary.opacity(0.18),
                Color.appAccent.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary,
                Color.appPrimary.opacity(0.82),
                Color.appAccent.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var secondaryButtonFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.95),
                Color.appBackground.opacity(0.5),
                Color.appSurface.opacity(0.75)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            AppStyle.screenGradient
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.14), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color.appAccent.opacity(0.1), Color.clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Full-screen gradient backdrop (replaces flat appBackground where needed).
    func appScreenBackdrop() -> some View {
        background(AppScreenBackground())
    }

    /// Strong elevation: gradient surface, luminous edge, layered shadows.
    func appCardElevated(cornerRadius: CGFloat = AppStyle.cardRadius) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppStyle.surfaceFill)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppStyle.rimStroke, lineWidth: 1)
                }
            )
            .shadow(color: Color.appPrimary.opacity(0.2), radius: 20, y: 12)
            .shadow(color: Color.appAccent.opacity(0.12), radius: 8, y: 4)
    }

    /// Medium depth for nested panels.
    func appCardSoft(cornerRadius: CGFloat = AppStyle.cardRadius) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppStyle.surfaceFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.14), radius: 14, y: 8)
    }

    /// Floating banner / compact chips (results, onboarding).
    func appFloatingPanel(cornerRadius: CGFloat = AppStyle.panelRadius) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppStyle.surfaceFill)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppStyle.rimStroke.opacity(0.85), lineWidth: 1)
                }
            )
            .shadow(color: Color.appPrimary.opacity(0.28), radius: 16, y: 10)
            .shadow(color: Color.appBackground.opacity(0.4), radius: 4, y: 2)
    }

    /// Dimmed locked tiles (level grid).
    func appLockedTile(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.appSurface.opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
            )
            .opacity(0.62)
    }
}
