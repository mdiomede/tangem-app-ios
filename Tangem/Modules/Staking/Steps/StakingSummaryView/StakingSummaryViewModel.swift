//
//  StakingSummaryViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

final class StakingSummaryViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var userWalletName: String
    @Published var tokenIconInfo: TokenIconInfo
    @Published var amount: String?
    @Published var alternativeAmount: String?

    @Published var validator: StakingValidatorViewData?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private weak var input: StakingSummaryInput?
    private weak var output: StakingSummaryOutput?
    private weak var router: StakingSummaryRoutable?

    private var bag: Set<AnyCancellable> = []

    private var bag: Set<AnyCancellable> = []

    init(
        inputModel: StakingSummaryViewModel.Input,
        input: StakingSummaryInput,
        output: StakingSummaryOutput,
        router: StakingSummaryRoutable
    ) {
        tokenItem = inputModel.tokenItem
        userWalletName = inputModel.userWalletName
        tokenIconInfo = inputModel.tokenIconInfo

        self.input = input
        self.output = output
        self.router = router

        bind()
    }

    func userDidTapAmountSection() {
        router?.openAmountStep()
    }
}

private extension StakingSummaryViewModel {
    func bind() {
        input?.amountFormattedPublisher()
            .assign(to: \.amount, on: self, ownership: .weak)
            .store(in: &bag)

        input?.alternativeAmountFormattedPublisher()
            .assign(to: \.alternativeAmount, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

extension StakingSummaryViewModel {
    struct Input {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let validator: TransactionValidator
    }
}
