//
//  SendView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    let transitionService: SendTransitionService

    @Namespace private var namespace

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let backgroundColor = Colors.Background.tertiary
    private let bottomGradientHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 14) {
            headerView

            ZStack(alignment: .bottom) {
                currentPage
//                    .transition(viewModel.stepAnimation.transition)
                    .allowsHitTesting(!viewModel.isUserInteractionDisabled)
//                    .onAppear(perform: viewModel.onCurrentPageAppear)
//                    .onDisappear(perform: viewModel.onCurrentPageDisappear)

                bottomOverlay
            }
            .animation(Constants.defaultAnimation, value: viewModel.step.type)
        }
        .background(backgroundColor.ignoresSafeArea())
        .interactiveDismissDisabled(viewModel.shouldShowDismissAlert)
        .scrollDismissesKeyboardCompat(.immediately)
        .alert(item: $viewModel.alert) { $0.alert }
        .safeAreaInset(edge: .bottom) {
            bottomContainer
                .animation(Constants.defaultAnimation, value: viewModel.showBackButton)
        }
//        .animation(SendView.Constants.defaultAnimation, value: viewModel.title)
    }

    @ViewBuilder
    private var headerView: some View {
        if let title = viewModel.title {
            ZStack(alignment: .center) {
                HStack {
                    Button(Localization.commonClose, action: viewModel.dismiss)
                        .foregroundColor(viewModel.closeButtonColor)
                        .disabled(viewModel.closeButtonDisabled)

                    Spacer()

                    switch viewModel.step.navigationTrailingViewType {
                    case .none:
                        EmptyView()
                    case .qrCodeButton(let action):
                        Button(action: action) {
                            Assets.qrCode.image
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                        }
                    }
                }

                headerText(title: title)
            }
            .animation(Constants.defaultAnimation, value: viewModel.step.navigationTrailingViewType)
            .frame(height: 44)
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func headerText(title: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .multilineTextAlignment(.center)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal, alignment: .center)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step.type {
        case .destination(let sendDestinationViewModel):
            SendDestinationView(
                viewModel: sendDestinationViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
            .onAppear(perform: {
                print("->>> SendDestinationView onAppear")
            })
            .onDisappear(perform: {
                print("->>> SendDestinationView onDisappear")
            })
        case .amount(let sendAmountViewModel):
            SendAmountView(
                viewModel: sendAmountViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        case .fee(let sendFeeViewModel):
            SendFeeView(
                viewModel: sendFeeViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        case .validators(let stakingValidatorsViewModel):
            StakingValidatorsView(
                viewModel: stakingValidatorsViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        case .summary(let sendSummaryViewModel):
            SendSummaryView(
                viewModel: sendSummaryViewModel,
                transitionService: transitionService,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        case .finish(let sendFinishViewModel):
            SendFinishView(
                viewModel: sendFinishViewModel,
                namespace: .init(id: namespace, names: SendGeometryEffectNames())
            )
        }
    }

    @ViewBuilder
    private var bottomContainer: some View {
        VStack(spacing: 10) {
            if let url = viewModel.transactionURL {
                HStack(spacing: 8) {
                    MainButton(
                        title: Localization.commonExplore,
                        icon: .leading(Assets.globe),
                        style: .secondary,
                        action: { viewModel.explore(url: url) }
                    )
                    MainButton(
                        title: Localization.commonShare,
                        icon: .leading(Assets.share),
                        style: .secondary,
                        action: { viewModel.share(url: url) }
                    )
                }
                .transition(.opacity)
            }

            HStack(spacing: 8) {
                if viewModel.showBackButton {
                    SendViewBackButton(
                        backgroundColor: backButtonStyle.background(isDisabled: false),
                        cornerRadius: backButtonStyle.cornerRadius(for: backButtonSize),
                        height: backButtonSize.height,
                        action: viewModel.userDidTapBackButton
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                MainButton(
                    title: viewModel.mainButtonType.title,
                    icon: viewModel.mainButtonType.icon,
                    style: .primary,
                    size: .default,
                    isLoading: viewModel.mainButtonLoading,
                    isDisabled: viewModel.mainButtonDisabled,
                    action: viewModel.userDidTapActionButton
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        LinearGradient(colors: [backgroundColor.opacity(0), backgroundColor], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .frame(maxHeight: bottomGradientHeight)
            .padding(.horizontal, 16)
            .allowsHitTesting(false)
    }
}

// MARK: - Back button

private struct SendViewBackButton: View {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            backgroundColor
                .cornerRadiusContinuous(cornerRadius)
                .overlay(
                    Assets.arrowLeftMini
                        .image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                )
                .frame(size: CGSize(bothDimensions: height))
        }
    }
}

extension SendView {
    enum Constants {
        static let amountMinTextScale = 0.5
        static let animationDuration: TimeInterval = 1.3
        static let defaultAnimation: Animation = .linear(duration: animationDuration)
    }
}

// MARK: - Preview

/*
 struct SendView_Preview: PreviewProvider {
     static let card = FakeUserWalletModel.wallet3Cards

     static let viewModel = SendViewModel(
         walletName: card.userWalletName,
         walletModel: card.walletModelsManager.walletModels.first!,
         userWalletModel: card,
         transactionSigner: TransactionSignerMock(),
         sendType: .send,
         emailDataProvider: EmailDataProviderMock(),
         canUseFiatCalculation: true,
         coordinator: SendRoutableMock()
     )

     static var previews: some View {
         SendView(viewModel: viewModel)
             .previewDisplayName("Full screen")

         NavHolder()
             .sheet(isPresented: .constant(true)) {
                 SendView(viewModel: viewModel)
             }
             .previewDisplayName("Sheet")
     }
 }
 */
