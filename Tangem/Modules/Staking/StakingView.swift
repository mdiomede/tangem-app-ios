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
        ZStack(alignment: .bottom) {
            Colors.Background.tertiary.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                GroupedScrollView(spacing: 14) {
                    content
                        .transition(transition)
                }
            }

            mainButton
        }
        .animation(.spring(), value: viewModel.step)
    }

    @ViewBuilder
    var header: some View {
        BottomSheetHeaderView(title: Localization.commonStaking)
    }

    @ViewBuilder
    var content: some View {
        let names = StakingViewNamespaceID()

        switch viewModel.step {
        case .none:
            EmptyView()
        case .amount(let viewModel):
            StakingAmountView(
                viewModel: viewModel,
                namespace: .init(id: namespace, names: names)
            )
        case .summary(let viewModel):
            StakingSummaryView(
                viewModel: viewModel,
                namespace: .init(id: namespace, names: names)
            )
        case .validators(let viewModel):
            StakingValidatorsView(
                viewModel: viewModel,
                namespace: .init(id: namespace, names: names)
            )
        }
    }

    @ViewBuilder
    var mainButton: some View {
        MainButton(title: viewModel.action.title) {
            viewModel.userDidTapActionButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var transition: AnyTransition {
        switch viewModel.animation {
        case .slideForward:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .slideBackward:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        case .fade:
            return .opacity
        }
    }
}

struct StakingView_Preview: PreviewProvider {
    static let viewModel = StakingViewModel(
        factory: .init(wallet: .mockETH, builder: .init(userWalletName: "Wallet", wallet: .mockETH, yield: .mock)),
        coordinator: StakingRoutableMock()
    )

    static var previews: some View {
        StakingView(viewModel: viewModel)
    }
}
