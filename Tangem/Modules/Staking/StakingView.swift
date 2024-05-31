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
        if let stakingAmountViewModel = viewModel.stakingAmountViewModel {
            StakingAmountView(
                viewModel: stakingAmountViewModel,
                namespace: .init(
                    id: namespace,
                    names: StakingViewNamespaceID()
                )
            )
        }
    }
}

struct StakingView_Preview: PreviewProvider {
    static let viewModel = StakingViewModel(
        stakingAmountViewModel: nil,
        coordinator: StakingCoordinator()
    )

    static var previews: some View {
        StakingView(viewModel: viewModel)
    }
}
