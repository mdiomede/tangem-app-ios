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

    @Published var step: Step? // Tempopary optional

    // MARK: - Dependencies

    private weak var coordinator: StakingRoutable?

    init(step: Step?, coordinator: StakingRoutable) {
        self.step = step
        self.coordinator = coordinator
    }
}

extension StakingViewModel {
    enum Step {
        case amount(StakingAmountViewModel)
        case summary
    }
}
