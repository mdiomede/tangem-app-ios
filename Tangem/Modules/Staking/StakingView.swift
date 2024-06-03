//
//  StakingView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingView: View {
    @ObservedObject private var viewModel: StakingViewModel
    @Namespace private var namespace

    init(viewModel: StakingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                Colors.Background.tertiary.ignoresSafeArea()

                GroupedScrollView(spacing: 14) {
                    content
                }
            }
            .navigationTitle(Localization.commonStaking)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.step {
        case .none:
            EmptyView()
        case .amount(let stakingAmountViewModel):
            StakingAmountView(
                viewModel: stakingAmountViewModel,
                namespace: .init(
                    id: namespace,
                    names: StakingViewNamespaceID()
                )
            )
        case .summary:
            Text("Summary") // TODO: https://tangem.atlassian.net/browse/IOS-6894
        }
    }
}

struct StakingView_Preview: PreviewProvider {
    static let viewModel = StakingViewModel(
        step: nil,
        coordinator: StakingCoordinator()
    )

    static var previews: some View {
        StakingView(viewModel: viewModel)
    }
}
