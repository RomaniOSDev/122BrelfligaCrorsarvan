//
//  OnboardingView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var page = 0

    var body: some View {
        ZStack {
            AppScreenBackground()
            VStack(spacing: 0) {
                onboardingHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                TabView(selection: $page) {
                    OnboardingShapePage()
                        .tag(0)
                    OnboardingColorPage()
                        .tag(1)
                    OnboardingSequencePage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .tint(Color.appPrimary)

                VStack(spacing: 12) {
                    if page == 2 {
                        PrimaryButton(title: "Get Started") {
                            store.setOnboardingFinished()
                        }
                    } else {
                        PrimaryButton(title: "Continue") {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                page += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var onboardingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Three quick stops before you play.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer(minLength: 12)
            Text("\(page + 1) / 3")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .appFloatingPanel(cornerRadius: 14)
        }
    }
}

// MARK: - Shared page layout

private struct OnboardingPageShell<Hero: View>: View {
    let step: Int
    let name: String
    let tagline: String
    let detail: String
    @ViewBuilder let hero: () -> Hero

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 0) {
                    hero()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 220)
                }
                .padding(20)
                .appCardElevated(cornerRadius: AppStyle.panelRadius)

                VStack(alignment: .leading, spacing: 12) {
                    Text("STEP \(step) OF 3")
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(Color.appAccent.opacity(0.95))

                    Text(name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text(tagline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary.opacity(0.92))

                    Text(detail)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardSoft(cornerRadius: AppStyle.cardRadius)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Pages

private struct OnboardingShapePage: View {
    @State private var appear = false

    var body: some View {
        OnboardingPageShell(
            step: 1,
            name: "Shape Shifter",
            tagline: "Drag pieces onto glowing outlines.",
            detail: "Align playful geometry with smooth drags until every shape snaps home."
        ) {
            ZStack {
                HStack(spacing: 28) {
                    morphingShape(offset: appear ? 0 : -40)
                    morphingShape(offset: appear ? 0 : 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
        }
    }

    @ViewBuilder
    private func morphingShape(offset: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccent.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 76, height: 76)
                .opacity(appear ? 1 : 0.35)
                .shadow(color: Color.appAccent.opacity(0.45), radius: 8, y: 3)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.72), Color.appAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 46)
                .offset(x: offset * 0.2)
                .rotationEffect(.degrees(appear ? 12 : -8))
                .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, y: 6)
                .shadow(color: Color.appAccent.opacity(0.2), radius: 4, y: 2)
        }
    }
}

private struct OnboardingColorPage: View {
    @State private var pulse = false

    var body: some View {
        OnboardingPageShell(
            step: 2,
            name: "Color Dash",
            tagline: "Tap the swatch that matches the target.",
            detail: "Catch the matching tone before the timer runs out — rhythm beats hesitation."
        ) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            index == 2
                                ? LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.appAccent.opacity(0.5), Color.appAccent.opacity(0.22)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: pulse ? 48 : 36, height: pulse ? 48 : 36)
                        .scaleEffect(index == 2 ? 1.1 : 1.0)
                        .overlay {
                            if index == 2 {
                                Circle()
                                    .strokeBorder(AppStyle.rimStroke, lineWidth: 2)
                            }
                        }
                        .shadow(color: index == 2 ? Color.appPrimary.opacity(0.5) : Color.clear, radius: 14, y: 6)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(Double(index) * 0.08),
                            value: pulse
                        )
                }
            }
        }
        .onAppear {
            pulse = true
        }
    }
}

private struct OnboardingSequencePage: View {
    @State private var wave = false

    var body: some View {
        OnboardingPageShell(
            step: 3,
            name: "Sequence Quest",
            tagline: "Watch, remember, then replay the order.",
            detail: "Follow the pulse stream, then rebuild the pattern with confident taps."
        ) {
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary.opacity(0.45), Color.appAccent.opacity(0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppStyle.rimStroke.opacity(0.9), lineWidth: 1)
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.appPrimary.opacity(0.25), radius: 8, y: 4)

                        Text("\(index + 1)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                    .offset(y: wave ? -7 : 7)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.65)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: wave
                    )
                }
            }
        }
        .onAppear {
            wave = true
        }
    }
}
