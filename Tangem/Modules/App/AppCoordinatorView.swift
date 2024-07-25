//
//  AppCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 20.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AppCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var sensitiveTextVisibilityViewModel = SensitiveTextVisibilityViewModel.shared

//    var body: some View {
//        ContentView()
//    }

    var body: some View {
        NavigationView {
            switch coordinator.viewState {
            case .welcome(let welcomeCoordinator):
                WelcomeCoordinatorView(coordinator: welcomeCoordinator)
            case .uncompleteBackup(let uncompletedBackupCoordinator):
                UncompletedBackupCoordinatorView(coordinator: uncompletedBackupCoordinator)
            case .auth(let authCoordinator):
                AuthCoordinatorView(coordinator: authCoordinator)
            case .main(let mainCoordinator):
                MainCoordinatorView(coordinator: mainCoordinator)
            case .none:
                EmptyView()
            }
        }
        .animation(.default, value: coordinator.viewState)
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
        .overlayContentContainer(item: $coordinator.marketsCoordinator) { coordinator in
            MarketsCoordinatorView(coordinator: coordinator)
        }
        .bottomSheet(
            item: $sensitiveTextVisibilityViewModel.informationHiddenBalancesViewModel,
            backgroundColor: Colors.Background.primary
        ) {
            InformationHiddenBalancesView(viewModel: $0)
        }
    }
}

struct ContentView: View {
    @State private var isViewVisible = false
    @State private var transitionType: AnyTransition = .slide
    @State private var viewKey = UUID()

    var body: some View {
        VStack {
            Button("Toggle View") {
                withAnimation {
                    isViewVisible.toggle()
                }
            }
            .padding()

            Button("Change Transition") {
                changeTransition()
            }
            .padding()

            if isViewVisible {
                MyView(text: viewKey.uuidString)
                    .transition(transitionType)
                    .id(viewKey) // Force re-render with new transition
            }
        }
        .animation(.easeInOut, value: isViewVisible)
    }

    func changeTransition() {
//        withAnimation {
        viewKey = UUID() // Force the view to update
        transitionType = nextTransition()
        print("changeTransition ->> \(transitionType)")
//        }
    }

    func nextTransition() -> AnyTransition {
        index += 1
        if index % 2 == 0 {
            return .slide
        } else {
            return .scale
        }
    }
}

var index = 0

struct MyView: View {
    let text: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 200, height: 200)
                .cornerRadius(20)
                .shadow(radius: 10)

            Text(text)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
