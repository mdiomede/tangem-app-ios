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

    @Published var validators: [StakingValidatorViewData] = []

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private weak var input: StakingSummaryInput?
    private weak var output: StakingSummaryOutput?
    private weak var router: StakingSummaryRoutable?

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

        input?.validatorPublisher()
            .map { validator in
                switch validator {
                case .none:
                    return []
                case .single(let validator):
                    let aprFormatted = validator.apr.map { PercentFormatter().format($0, option: .staking) }
                    return [StakingValidatorViewData(
                        id: validator.address,
                        imageURL: validator.iconURL,
                        name: validator.name,
                        aprFormatted: aprFormatted
                    )]
                case .multiple(let validators):
                    return []
                }
            }
            .assign(to: \.validators, on: self, ownership: .weak)
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
