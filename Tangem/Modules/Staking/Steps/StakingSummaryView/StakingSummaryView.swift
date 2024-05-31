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
    }

    var body: some View {
        GroupedScrollView(spacing: 14) {
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
        .roundedBackground(with: Colors.Background.action, verticalPadding: 16, horizontalPadding: 14)
    }
}

extension StakingSummaryView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingSummaryViewGeometryEffectNames
    }
}

struct StakingSummaryView_Preview: PreviewProvider {
    static let viewModel = StakingSummaryViewModel(coordinator: StakingSummaryRoutableMock())
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
