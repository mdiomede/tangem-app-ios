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
    @Published var sendingAmountFormatted: String = ""
    @Published var alternativeAmount: String = ""

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let cryptoFiatAmountConverter: CryptoFiatAmountConverter
    private weak var input: StakingSummaryInput?
    private weak var output: StakingSummaryOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        inputModel: StakingSummaryViewModel.Input,
        cryptoFiatAmountConverter: CryptoFiatAmountConverter,
        input: StakingSummaryInput,
        output: StakingSummaryOutput
    ) {
        tokenItem = inputModel.tokenItem
        userWalletName = inputModel.userWalletName
        tokenIconInfo = inputModel.tokenIconInfo

        self.input = input
        self.cryptoFiatAmountConverter = cryptoFiatAmountConverter
        self.output = output

        bind()
    }

    func bind() {
        input?.amountPublisher()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, value in
                viewModel.update(value: value)
            })
            .store(in: &bag)
    }
}

private extension StakingSummaryViewModel {
    func update(value: Decimal?) {
        sendingAmountFormatted = BalanceFormatter().formatCryptoBalance(value, currencyCode: tokenItem.currencySymbol)
        let fiatValue = cryptoFiatAmountConverter.convertToFiat(value, tokenItem: tokenItem)

        alternativeAmount = BalanceFormatter().formatFiatBalance(fiatValue)
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
