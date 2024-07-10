//
//  SendAmountView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel
    let namespace: Namespace
    @FocusState private var isInputActive: Bool

//    @State private var isAppeared = false
//    @State private var containerSize: CGSize = .zero

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountContainer

            if viewModel.segmentControlVisible {
                segmentControl
            }
        }
//        .offset(y: viewModel.segmentControlVisible ? 0 : 100)
        .transition(viewModel.transition)
        .onAppear(perform: viewModel.onAppear)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.segmentControlVisible)
//        .onAppear {
//            isAppeared = true
//        }
//        .onDisappear {
//            isAppeared = false
//        }
//        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
//        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }

    private var amountContainer: some View {
        VStack(spacing: 32) {
//            if viewModel.segmentControlVisible {
            walletInfoView
                // Because the top padding have to be is 16 to the white background
                // But the bottom padding have to be is 12
                .padding(.top, 4)
            // .transition(.opacity) //  .move(edge: .bottom)
//            }

            amountContent
        }
        .defaultRoundedBackground(
            with: Colors.Background.action,
            geometryEffect: .init(
                id: namespace.names.amountContainer,
                namespace: namespace.id
            )
        )
    }

    private var walletInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.userWalletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletName, in: namespace.id)

            SensitiveText(viewModel.balance)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: namespace.names.walletBalance, in: namespace.id)
        }
    }

    private var amountContent: some View {
        VStack(spacing: 18) {
            TokenIcon(tokenIconInfo: viewModel.tokenIconInfo, size: CGSize(width: 36, height: 36))
                .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 6) {
                ZStack {
                    SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                        .initialFocusBehavior(.noFocus)
                        .alignment(.center)
                        .prefixSuffixOptions(viewModel.currentFieldOptions)
                        .minTextScale(viewModel.amountMinTextScale)
                        .focused($isInputActive)
                }
                // We have to keep frame until SendDecimalNumberTextField size fix
                // Just on appear it has the zero height. Is cause break animation
                .frame(height: 35)
                .border(Color.red)
                .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)

                Text(viewModel.error ?? " ")
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                    .lineLimit(1)
            }
        }
//        .fixedSize(horizontal: false, vertical: true)
//        .layoutPriority(1)
        .readGeometry(onChange: { print("->> size \($0.size)") })
    }

    private var segmentControl: some View {
//        GeometryReader { proxy in
        HStack(spacing: 8) {
            SendCurrencyPicker(
                data: viewModel.currencyPickerData,
                useFiatCalculation: viewModel.isFiatCalculation.asBinding
            )

            MainButton(title: Localization.sendMaxAmount, style: .secondary) {
                viewModel.userDidTapMaxAmount()
            }
            .frame(width: UIScreen.main.bounds.size.width / 3)
        }
//        }
//        .border(Color.red)
//        .transition(.move(edge: .bottom))
//        }
//        .border(Color.red)
//        .transactionMonitor("segmentControl before")
//        .transition(.move(edge: .bottom).combined(with: .opacity))
//        .transactionMonitor("segmentControl after")
//        .animation(.default, value: isAppeared)
    }
}

extension SendAmountView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendAmountViewGeometryEffectNames
    }
}

/*
 struct SendAmountView_Previews: PreviewProvider {
     static let viewModel = SendAmountViewModel(
         inputModel: SendDependenciesBuilder (userWalletName: "Wallet", wallet: .mockETH).makeStakingAmountInput(),
         cryptoFiatAmountConverter: .init(),
         input: StakingAmountInputMock(),
         output: StakingAmountOutputMock()
     )

     @Namespace static var namespace

     static var previews: some View {
         ZStack {
             Colors.Background.tertiary.ignoresSafeArea()

             SendAmountView(
                 viewModel: viewModel,
                 namespace: .init(id: namespace, names: StakingViewNamespaceID())
             )
         }
     }
 }
 */

extension View {
    @ViewBuilder
    func transactionMonitor(_ title: String, _ showAnimation: Bool = true) -> some View {
        transaction {
            print("monitor", title, terminator: showAnimation ? ": " : "\n")
            if showAnimation {
                print("monitor", $0.animation ?? "nil")
            }
        }
    }
}
