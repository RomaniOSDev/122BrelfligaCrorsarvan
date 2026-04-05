//
//  MainTabView.swift
//  122BrelfligaCrorsarvan
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selected = 0

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                ActivitiesListView()
            }
            .tabItem {
                Label("Activities", systemImage: "sparkles")
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
        .tint(Color.appPrimary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(Color.appSurface)
            appearance.shadowColor = UIColor(Color.appPrimary.opacity(0.14))
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
