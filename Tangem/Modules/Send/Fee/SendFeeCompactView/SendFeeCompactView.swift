//
//  SendFeeCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel
    let namespace: SendFeeView.Namespace

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .setNamespace(namespace.id)
                .setOptionNamespaceId(namespace.names.feeOption(feeOption: feeRowViewModel.option))
                .setAmountNamespaceId(namespace.names.feeAmount(feeOption: feeRowViewModel.option))
                .disabled(true)
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .matchedGeometryEffect(id: namespace.names.feeTitle, in: namespace.id)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.feeContainer, namespace: namespace.id))

//        GroupedSection(viewModel.selectedFeeSummaryViewModel) { data in
//            SendFeeSummaryView(data: data)
//                .setNamespace(namespace.id)
//                .setTitleNamespaceId(namespace.names.feeTitle)
//                .setOptionNamespaceId(namespace.names.feeOption(feeOption: data.feeOption))
//                .setAmountNamespaceId(namespace.names.feeAmount(feeOption: data.feeOption))
//                .overlay(alignment: .bottom) {
//                    feeRowViewSeparator(for: data.feeOption)
//                }
//                .overlay {
//                    ForEach(viewModel.deselectedFeeRowViewModels) { model in
//                        FeeRowView(viewModel: model)
//                            .setNamespace(namespace.id)
//                            .setOptionNamespaceId(namespace.names.feeOption(feeOption: model.option))
//                            .setAmountNamespaceId(namespace.names.feeAmount(feeOption: model.option))
//                            .allowsHitTesting(false)
//                            .hidden()
//                            .overlay(alignment: .bottom) {
//                                feeRowViewSeparator(for: model.option)
//                            }
//                    }
//                }
//        }
        // Fee uses a regular background regardless of whether it's enabled or not
    }

//    private func feeRowViewSeparator(for option: FeeOption) -> some View {
//        Separator(height: .minimal, color: Colors.Stroke.primary)
//            .padding(.leading, GroupedSectionConstants.defaultHorizontalPadding)
//            .opacity(0)
//            .matchedGeometryEffect(id: namespace.names.feeSeparator(feeOption: option), in: namespace.id)
//    }
}
