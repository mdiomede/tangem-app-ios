//
//  StakingSummaryView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingSummaryView: View {
    @ObservedObject private var viewModel: StakingSummaryViewModel
    private let namespace: Namespace

    init(viewModel: StakingSummaryViewModel, namespace: Namespace) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    var body: some View {
        VStack(spacing: 14) {
            amountContainer
        }
    }

    private var amountContainer: some View {
        VStack(spacing: 16) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36)
            )
            .matchedGeometryEffect(id: namespace.names.tokenIcon, in: namespace.id)

            VStack(spacing: 4) {
                // We have to use the TextField instead of Text here for same animaion
                TextField("", text: .constant(viewModel.amount ?? " "))
                    .matchedGeometryEffect(id: namespace.names.amountCryptoText, in: namespace.id)
                    .multilineTextAlignment(.center)
                    .disabled(true)
                    .style(DecimalNumberTextField.Appearance().font, color: DecimalNumberTextField.Appearance().textColor)

                Text(viewModel.alternativeAmount ?? " ")
                    .matchedGeometryEffect(id: namespace.names.amountFiatText, in: namespace.id)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.userDidTapAmountSection()
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .roundedBackground(
            with: Colors.Background.action,
            verticalPadding: 16,
            horizontalPadding: 14,
            geometryEffect: .init(id: namespace.names.amountContainer, namespace: namespace.id)
        )
    }
}

extension StakingSummaryView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingSummaryViewGeometryEffectNames
    }
}

struct StakingSummaryView_Preview: PreviewProvider {
    static let viewModel = StakingSummaryViewModel(
        inputModel: StakingStepsViewBuilder(userWalletName: "Wallet", wallet: .mockETH).makeStakingSummaryInput(),
        input: StakingSummaryInputMock(),
        output: StakingSummaryOutputMock(),
        router: StakingSummaryRoutableMock()
    )

    @Namespace static var namespace

    static var previews: some View {
        StakingSummaryView(
            viewModel: viewModel,
            namespace: .init(
                id: namespace,
                names: StakingViewNamespaceID()
            )
        )
    }
}
