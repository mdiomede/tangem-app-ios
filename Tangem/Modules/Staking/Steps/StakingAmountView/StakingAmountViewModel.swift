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
    @Published var amountType: AmountType = .crypto

    var isFiatCalculation: BindingValue<Bool> {
        .init(
            root: self,
            default: false,
            get: { $0.amountType == .fiat },
            set: { $0.amountType = $1 ? .fiat : .crypto }
        )
    }

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let balanceValue: Decimal
    private let validator: TransactionValidator
    private let cryptoFiatAmountConverter: CryptoFiatAmountConverter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private weak var input: StakingAmountInput?
    private weak var output: StakingAmountOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        inputModel: StakingAmountViewModel.Input,
        cryptoFiatAmountConverter: CryptoFiatAmountConverter,
        input: StakingAmountInput,
        output: StakingAmountOutput
    ) {
        userWalletName = inputModel.userWalletName
        balance = inputModel.balanceFormatted
        tokenIconInfo = inputModel.tokenIconInfo
        currencyPickerData = inputModel.currencyPickerData

        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: inputModel.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: inputModel.tokenItem.decimalCount)

        tokenItem = inputModel.tokenItem
        balanceValue = inputModel.balanceValue
        validator = inputModel.validator

        self.cryptoFiatAmountConverter = cryptoFiatAmountConverter
        self.input = input
        self.output = output

        bind()
    }

    func userDidTapMaxAmount() {
        let fiatValue = convertToFiat(value: balanceValue)

        switch amountType {
        case .crypto:
            decimalNumberTextFieldViewModel.update(value: balanceValue)
            output?.update(amount: .typical(crypto: balanceValue, fiat: fiatValue))
        case .fiat:
            decimalNumberTextFieldViewModel.update(value: fiatValue)
            output?.update(amount: .alternative(fiat: fiatValue, crypto: balanceValue))
        }
    }
}

// MARK: - Private

private extension StakingAmountViewModel {
    func bind() {
        $amountType
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, amountType in
                viewModel.update(amountType: amountType)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel.valuePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.amountDidChange(value: value)
            }
            .store(in: &bag)

        input?
            .alternativeAmountFormattedPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: \.alternativeAmount, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func amountDidChange(value: Decimal?) {
        switch amountType {
        case .crypto:
            let fiatValue = convertToFiat(value: value)
            output?.update(amount: .typical(crypto: value, fiat: fiatValue))
            validate(amount: value)
        case .fiat:
            let cryptoValue = convertToCrypto(value: value)
            output?.update(amount: .alternative(fiat: value, crypto: cryptoValue))
            validate(amount: cryptoValue)
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

    func update(amountType: AmountType) {
        switch amountType {
        case .crypto:
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            let uiValue = decimalNumberTextFieldViewModel.value
            let cryptoValue = convertToCrypto(value: uiValue)

            decimalNumberTextFieldViewModel.update(value: cryptoValue)
            output?.update(amount: .typical(crypto: cryptoValue, fiat: uiValue))
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: 2)
            let uiValue = decimalNumberTextFieldViewModel.value
            let fiatValue = convertToFiat(value: uiValue)

            decimalNumberTextFieldViewModel.update(value: fiatValue)
            output?.update(amount: .alternative(fiat: fiatValue, crypto: uiValue))
        }
    }

    func convertToCrypto(value: Decimal?) -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if input?.amount.fiat == value {
            return input?.amount.crypto
        }

        return cryptoFiatAmountConverter.convertToCrypto(value, tokenItem: tokenItem)
    }

    func convertToFiat(value: Decimal?) -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if input?.amount.crypto == value {
            return input?.amount.fiat
        }

        return cryptoFiatAmountConverter.convertToFiat(value, tokenItem: tokenItem)
    }
}

extension StakingAmountViewModel {
    enum AmountType: Hashable {
        case crypto
        case fiat
    }

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
