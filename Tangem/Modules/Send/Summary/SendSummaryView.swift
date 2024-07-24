//
//  SendSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    @ObservedObject var viewModel: SendSummaryViewModel
    let transitionService: SendTransitionService
    let namespace: Namespace

    private let coordinateSpaceName = UUID()

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            GroupedScrollView(spacing: 14) {
                if viewModel.destinationVisible,
                   let sendDestinationViewModel = viewModel.sendDestinationCompactViewModel {
                    SendDestinationCompactView(
                        viewModel: sendDestinationViewModel,
                        background: viewModel.editableType.sectionBackground,
                        namespace: .init(id: namespace.id, names: namespace.names)
                    )
                    .readContentOffset(
                        inCoordinateSpace: .named(coordinateSpaceName),
                        onChange: { transitionService.destinationContentOffset = $0 }
                    )
                    .transition(transitionService.transitionToDestinationCompactView)
                    .contentShape(Rectangle())
                    .allowsHitTesting(viewModel.canEditDestination)
                    .onTapGesture {
                        viewModel.userDidTapDestination()
                    }
                }

                if viewModel.amountVisible,
                   let sendAmountViewModel = viewModel.sendAmountCompactViewModel {
                    SendAmountCompactView(
                        viewModel: sendAmountViewModel,
                        background: viewModel.editableType.sectionBackground,
                        namespace: .init(id: namespace.id, names: namespace.names)
                    )
                    .readContentOffset(
                        inCoordinateSpace: .named(coordinateSpaceName),
                        onChange: { transitionService.amountContentOffset = $0 }
                    )
                    .transition(transitionService.transitionToAmountCompactView)
                    .contentShape(Rectangle())
                    .allowsHitTesting(viewModel.canEditAmount)
                    .onTapGesture {
                        viewModel.userDidTapAmount()
                    }
                }

                if viewModel.validatorVisible,
                   let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                    StakingValidatorsCompactView(
                        viewModel: stakingValidatorsCompactViewModel,
                        namespace: .init(id: namespace.id, names: namespace.names)
                    )
                    .readContentOffset(
                        inCoordinateSpace: .named(coordinateSpaceName),
                        onChange: { transitionService.validatorsContentOffset = $0 }
                    )
                    .transition(transitionService.transitionToValidatorsCompactView)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.userDidTapValidator()
                    }
                }

                if viewModel.feeVisible, let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                    SendFeeCompactView(
                        viewModel: sendFeeCompactViewModel,
                        namespace: .init(id: namespace.id, names: namespace.names)
                    )
                    .readContentOffset(
                        inCoordinateSpace: .named(coordinateSpaceName),
                        onChange: { transitionService.feeContentOffset = $0 }
                    )
                    .transition(transitionService.transitionToFeeCompactView)
                    .contentShape(Rectangle())
                    .allowsHitTesting(viewModel.canEditFee)
                    .onTapGesture {
                        viewModel.userDidTapFee()
                    }
                }

                if viewModel.showHint {
                    HintView(
                        text: Localization.sendSummaryTapHint,
                        font: Fonts.Regular.footnote,
                        textColor: Colors.Text.secondary,
                        backgroundColor: Colors.Button.secondary
                    )
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(insertion: .offset(y: 20), removal: .identity).combined(with: .opacity)
                    )
                }

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                }
            }
            .coordinateSpace(name: coordinateSpaceName)

            descriptionView
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .transition(transitionService.summaryViewTransition)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.destinationVisible)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.amountVisible)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.validatorVisible)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.feeVisible)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.transactionDescriptionIsVisible)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionView: some View {
        if let transactionDescription = viewModel.transactionDescription {
            Text(.init(transactionDescription))
                .style(Fonts.Regular.caption1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .visible(viewModel.transactionDescriptionIsVisible)
        }
    }
}

extension SendSummaryViewModel.EditableType {
    var sectionBackground: Color {
        switch self {
        case .editable:
            Colors.Background.action
        case .disable:
            Colors.Button.disabled
        }
    }
}

extension SendSummaryView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}

/*
 struct SendSummaryView_Previews: PreviewProvider {
     @Namespace static var namespace

     static let tokenIconInfo = TokenIconInfo(
         name: "Tether",
         blockchainIconName: "ethereum.fill",
         imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
         isCustom: false,
         customTokenColor: nil
     )

     static let walletInfo = SendWalletInfo(
         walletName: "Family Wallet",
         balanceValue: 2130.88,
         balance: "2 130,88 USDT (2 129,92 $)",
         blockchain: .ethereum(testnet: false),
         currencyId: "tether",
         feeCurrencySymbol: "ETH",
         feeCurrencyId: "ethereum",
         isFeeApproximate: false,
         tokenIconInfo: tokenIconInfo,
         cryptoIconURL: nil,
         cryptoCurrencyCode: "USDT",
         fiatIconURL: nil,
         fiatCurrencyCode: "USD",
         amountFractionDigits: 6,
         feeFractionDigits: 6,
         feeAmountType: .coin,
         canUseFiatCalculation: true
     )

     static let viewModel = SendSummaryViewModel(
         input: SendSummaryViewModelInputMock(),
         notificationManager: FakeSendNotificationManager(),
         fiatCryptoValueProvider: SendFiatCryptoValueProviderMock(),
         addressTextViewHeightModel: .init(),
         walletInfo: walletInfo
     )

     static var previews: some View {
         SendSummaryView(viewModel: viewModel, namespace: namespace)
     }
 }
 */
