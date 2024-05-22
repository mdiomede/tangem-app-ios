//
//  StakingAmountView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingViewNamespaceID: StakingAmountViewGeometryEffectNames {
    var amountContainer: String { "amountContainer" }
    var tokenIcon: String { "tokenIcon" }
    var amountCryptoText: String { "amountCryptoText" }
    var amountFiatText: String { "amountFiatText" }
}

protocol StakingAmountViewGeometryEffectNames {
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}

extension StakingAmountView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingAmountViewGeometryEffectNames
    }
}

struct StakingAmountView: View {
    @ObservedObject private var viewModel: StakingAmountViewModel
    private let namespace: Namespace

    init(viewModel: StakingAmountViewModel, namespace: Namespace) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountContainer

            segmentControl
        }
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
            StakingWalletInfoView(name: viewModel.walletName, balance: viewModel.balance)
                // Because the top padding is equal 16 to the white background
                // And bottom padding is equal 12
                .padding(.top, 4)

            amountContent
        }
        .defaultRoundedBackground(with: Colors.Background.action)
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

                LoadableTextView(
                    state: viewModel.alternativeAmount,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 60, height: 14),
                    lineLimit: 1
                )
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
                    cryptoIconURL: viewModel.cryptoIconURL,
                    cryptoCurrencyCode: viewModel.cryptoCurrencyCode,
                    fiatIconURL: viewModel.fiatIconURL,
                    fiatCurrencyCode: viewModel.fiatCurrencyCode,
                    disabled: viewModel.currencyPickerDisabled,
                    useFiatCalculation: $viewModel.useFiatCalculation
                )

                MainButton(title: Localization.sendMaxAmount, style: .secondary) {}
                    .frame(width: proxy.size.width / 3)
            }
        }
    }
}

struct StakingAmountView_Preview: PreviewProvider {
    static let viewModel = StakingAmountViewModel(
        walletModel: .mockETH,
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

struct StakingWalletInfoView: View {
    let name: String
    let balance: LoadableTextView.State

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)

            LoadableTextView(
                state: balance,
                font: Fonts.Regular.footnote,
                textColor: Colors.Text.tertiary,
                loaderSize: CGSize(width: 80, height: 14),
                lineLimit: 1,
                isSensitiveText: true
            )
        }
    }
}
