//
//  StakingAmountView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingAmountView: View {
    @ObservedObject private var viewModel: StakingAmountViewModel
    private let namespace: Namespace

    init(viewModel: StakingAmountViewModel, namespace: Namespace) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    var body: some View {
        VStack(spacing: 14) {
            amountContainer

            segmentControl
        }
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
            walletInfoView
                // Because the top padding have to be is 16 to the white background
                // But the bottom padding have to be is 12
                .padding(.top, 4)

            amountContent
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.userWalletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
    }

    private var amountContent: some View {
        VStack(spacing: 16) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36)
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 4) {
                SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                    .initialFocusBehavior(.immediateFocus)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.currentFieldOptions)
                    .frame(maxWidth: .infinity)
                    .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)

                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)

                Text(viewModel.error ?? " ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .lineLimit(1)
            }
        }
    }

    private var segmentControl: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                SendCurrencyPicker(
                    data: viewModel.currencyPickerData,
                    useFiatCalculation: $viewModel.useFiatCalculation
                )

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                    viewModel.userDidTapMaxAmount()
                }
                .frame(width: proxy.size.width / 3)
            }
        }
    }
}

extension StakingAmountView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingAmountViewGeometryEffectNames
    }
}

struct StakingAmountView_Preview: PreviewProvider {
    static let viewModel = StakingAmountViewModel(
        input: StakingStepsViewBuilder(userWalletName: "Wallet", wallet: .mockETH).makeStakingAmountViewModel(),
        coordinator: StakingAmountRoutableMock()
    )

    @Namespace static var namespace

    static var previews: some View {
        ZStack {
            Colors.Background.tertiary.ignoresSafeArea()

            StakingAmountView(
                viewModel: viewModel,
                namespace: .init(id: namespace, names: StakingViewNamespaceID())
            )
        }
    }
}
