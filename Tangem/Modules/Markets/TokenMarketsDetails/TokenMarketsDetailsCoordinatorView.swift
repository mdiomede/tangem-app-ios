//
//  TokenMarketsDetailsCoordinatorView.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenMarketsDetailsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                TokenMarketsDetailsView(viewModel: viewModel)
//                    .debugBorder(color: .red, width: 3.0)
            }

            sheets
        }
    }

    var sheets: some View {
        NavHolder()
            .detentBottomSheet(
                item: $coordinator.networkSelectorViewModel,
                detents: [.large, .medium]
            ) { viewModel in
                MarketsTokensNetworkSelectorView(viewModel: viewModel)
            }
    }
}
