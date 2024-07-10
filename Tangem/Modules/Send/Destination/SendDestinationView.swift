//
//  SendDestinationView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationCompactView: View {
    @ObservedObject var viewModel: SendDestinationViewModel
    let editableType: SendSummaryViewModel.EditableType
    let namespace: SendDestinationView.Namespace

    var body: some View {
        GroupedSection(viewModel.fields) { field in
            switch field {
            case .address(let viewModel):
                SendDestinationAddressSummaryView(
                    addressTextViewHeightModel: viewModel.addressTextViewHeightModel,
                    address: viewModel.text
                )
                .namespace(.init(id: namespace.id, names: namespace.names))

//                SendDestinationTextView(viewModel: viewModel)
//                    .setNamespace(namespace.id)
//                    .setContainerNamespaceId(namespace.names.addressContainer)
//                    .setTitleNamespaceId(namespace.names.addressTitle)
//                    .setIconNamespaceId(namespace.names.addressIcon)
//                    .setTextNamespaceId(namespace.names.addressText)
//                    .setClearButtonNamespaceId(namespace.names.addressClearButton)
//                    .disabled(true)
            case .additionalField(let viewModel):
                if !viewModel.text.isEmpty {
                    DefaultTextWithTitleRowView(data: .init(title: viewModel.name, text: viewModel.text))
                        .titleGeometryEffect(
                            .init(id: namespace.names.addressAdditionalFieldTitle, namespace: namespace.id)
                        )
                        .textGeometryEffect(
                            .init(id: namespace.names.addressAdditionalFieldText, namespace: namespace.id)
                        )
                }
//
//                SendDestinationTextView(viewModel: viewModel)
//                    .setNamespace(namespace.id)
//                    .setContainerNamespaceId(namespace.names.addressAdditionalFieldContainer)
//                    .setTitleNamespaceId(namespace.names.addressAdditionalFieldTitle)
//                    .setIconNamespaceId(namespace.names.addressAdditionalFieldIcon)
//                    .setTextNamespaceId(namespace.names.addressAdditionalFieldText)
//                    .setClearButtonNamespaceId(namespace.names.addressAdditionalFieldClearButton)
//                    .disabled(true)
            }
        }
        .settings(\.backgroundColor, editableType.sectionBackground)
        .settings(\.backgroundGeometryEffect, .init(id: namespace.names.destinationContainer, namespace: namespace.id))
    }
}

extension SendDestinationViewModel {
    var fields: [SendDestinationCompactView.FieldType] {
        [
            addressViewModel.map { .address($0) },
            additionalFieldViewModel.map { .additionalField($0) },
        ]
        .compactMap { $0 }
    }
}

extension SendDestinationCompactView {
    enum FieldType: Identifiable {
        var id: ObjectIdentifier {
            switch self {
            case .address(let sendDestinationTextViewModel):
                sendDestinationTextViewModel.id
            case .additionalField(let sendDestinationTextViewModel):
                sendDestinationTextViewModel.id
            }
        }

        case address(SendDestinationTextViewModel)
        case additionalField(SendDestinationTextViewModel)
    }
}

struct SendDestinationView: View {
    @ObservedObject var viewModel: SendDestinationViewModel
    let namespace: Namespace

    private var auxiliaryViewTransition: AnyTransition {
        .offset(y: 100).combined(with: .opacity)
    }

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.addressViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace.id)
                    .setContainerNamespaceId(namespace.names.addressContainer)
                    .setTitleNamespaceId(namespace.names.addressTitle)
                    .setIconNamespaceId(namespace.names.addressIcon)
                    .setTextNamespaceId(namespace.names.addressText)
                    .setClearButtonNamespaceId(namespace.names.addressClearButton)
            } footer: {
                if let viewModel = viewModel.addressViewModel {
                    Text(viewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .transition(auxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressBackground,
                namespace: namespace.id
            ))

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace.id)
                    .setContainerNamespaceId(namespace.names.addressAdditionalFieldContainer)
                    .setTitleNamespaceId(namespace.names.addressAdditionalFieldTitle)
                    .setIconNamespaceId(namespace.names.addressAdditionalFieldIcon)
                    .setTextNamespaceId(namespace.names.addressAdditionalFieldText)
                    .setClearButtonNamespaceId(namespace.names.addressAdditionalFieldClearButton)
                    .padding(.vertical, 2)
            } footer: {
                if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                    Text(additionalFieldViewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .transition(auxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressAdditionalFieldBackground,
                namespace: namespace.id
            ))

            if viewModel.showSuggestedDestinations,
               let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                    .transition(.opacity)
            }
        }
        .transition(viewModel.transition)
        .onAppear(perform: viewModel.onAppear)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.showSuggestedDestinations)
    }
}

extension SendDestinationView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendDestinationViewGeometryEffectNames
    }
}

/*
 struct SendDestinationView_Previews: PreviewProvider {
     @Namespace static var namespace

     static var previews: some View {
         SendDestinationView(
             viewModel: SendDestinationViewModel(
                 input: SendSendDestinationInputMock(),
                 addressTextViewHeightModel: .init()
             ),
             namespace: namespace
         )
     }
 }
 */
