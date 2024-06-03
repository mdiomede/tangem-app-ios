//
//  StakingAmountViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

final class StakingAmountViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var userWalletName: String
    @Published var balance: String
    @Published var tokenIconInfo: TokenIconInfo
    @Published var currencyPickerData: SendCurrencyPickerData

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: String?

    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var useFiatCalculation: Bool = false

    // MARK: - Dependencies

    private let cryptoFiatAmountConverter: CryptoFiatAmountConverter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private let tokenItem: TokenItem
    private let balanceValue: Decimal
    private var validator: TransactionValidator
    private weak var coordinator: StakingAmountRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        input: StakingAmountViewModel.Input,
        coordinator: StakingAmountRoutable
    ) {
        userWalletName = input.userWalletName
        balance = input.balanceFormatted
        tokenIconInfo = input.tokenIconInfo
        currencyPickerData = input.currencyPickerData

        cryptoFiatAmountConverter = .init(maximumFractionDigits: input.tokenItem.decimalCount)
        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: input.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: input.tokenItem.decimalCount)

        tokenItem = input.tokenItem
        balanceValue = input.balanceValue
        validator = input.validator
        self.coordinator = coordinator

        bind()
    }

    func userDidTapMaxAmount() {
        let value: Decimal? = {
            if useFiatCalculation {
                let fiatValue = cryptoFiatAmountConverter.convertToFiat(balanceValue, tokenItem: tokenItem)
                return fiatValue
            }

            return balanceValue
        }()

        decimalNumberTextFieldViewModel.update(value: value)
        updateAlternativeAmount(value: value)
    }
}

// MARK: - Private

private extension StakingAmountViewModel {
    func bind() {
        $useFiatCalculation
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, useFiat in
                viewModel.update(useFiat: useFiat)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel.valuePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.updateAlternativeAmount(value: value)
                viewModel.validate(amount: value)
            }
            .store(in: &bag)
    }

    func update(useFiat: Bool) {
        if useFiat {
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(
                decimalNumberTextFieldViewModel.value,
                tokenItem: tokenItem
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        } else {
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToCrypto(
                decimalNumberTextFieldViewModel.value,
                tokenItem: tokenItem
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        }

        updateAlternativeAmount(value: decimalNumberTextFieldViewModel.value)
    }

    func updateAlternativeAmount(value: Decimal?) {
        guard let value else {
            alternativeAmount = nil
            return
        }

        let formatter = BalanceFormatter()

        if useFiatCalculation {
            let cryptoValue = cryptoFiatAmountConverter.convertToCrypto(value, tokenItem: tokenItem)
            alternativeAmount = formatter.formatCryptoBalance(cryptoValue, currencyCode: tokenItem.currencySymbol)
        } else {
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(value, tokenItem: tokenItem)
            alternativeAmount = formatter.formatFiatBalance(fiatValue)
        }
    }

    func validate(amount: Decimal?) {
        guard let amount else {
            error = nil
            return
        }
        do {
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
            try validator.validate(amount: amount)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

extension StakingAmountViewModel {
    struct Input {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceValue: Decimal
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData
        let validator: TransactionValidator
    }
}
