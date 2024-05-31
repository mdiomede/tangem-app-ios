//
//  StakingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stakingAmountViewModel: StakingAmountViewModel?

    // MARK: - Dependencies

    private weak var coordinator: StakingRoutable?

    init(
        stakingAmountViewModel: StakingAmountViewModel?,
        coordinator: StakingRoutable
    ) {
        self.stakingAmountViewModel = stakingAmountViewModel
        self.coordinator = coordinator
    }
}
