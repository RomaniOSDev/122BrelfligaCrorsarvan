//
//  ContentView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameProgressStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
