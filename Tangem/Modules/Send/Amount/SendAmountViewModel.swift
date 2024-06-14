//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendAmountInput: AnyObject {
    var amount: CryptoFiatAmount? { get }
}

protocol SendAmountOutput: AnyObject {
    func amountDidChanged(amount: CryptoFiatAmount?)
}

class SendAmountViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var animatingAuxiliaryViewsOnAppear: Bool = false

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

    var didProperlyDisappear = false

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let balanceValue: Decimal

    private weak var input: SendAmountInput?
    private weak var output: SendAmountOutput?
    private let validator: SendAmountValidator
    private let cryptoFiatAmountConverter: CryptoFiatAmountConverter
    private let cryptoFiatAmountFormatter: CryptoFiatAmountFormatter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Initital,
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator,
        cryptoFiatAmountConverter: CryptoFiatAmountConverter,
        cryptoFiatAmountFormatter: CryptoFiatAmountFormatter
    ) {
        userWalletName = initial.userWalletName
        balance = initial.balanceFormatted
        tokenIconInfo = initial.tokenIconInfo
        currencyPickerData = initial.currencyPickerData

        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: initial.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: initial.tokenItem.decimalCount)

        tokenItem = initial.tokenItem
        balanceValue = initial.balanceValue

        self.input = input
        self.output = output
        self.validator = validator
        self.cryptoFiatAmountConverter = cryptoFiatAmountConverter
        self.cryptoFiatAmountFormatter = cryptoFiatAmountFormatter

        bind()

        if let predefinedAmount = initial.predefinedAmount {
            setExternalAmount(predefinedAmount)
        }
    }

    func onAppear() {
        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        } else {
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func userDidTapMaxAmount() {
        let fiatValue = convertToFiat(value: balanceValue)

        switch amountType {
        case .crypto:
            decimalNumberTextFieldViewModel.update(value: balanceValue)
            amountDidChanged(amount: .typical(crypto: balanceValue, fiat: fiatValue))
        case .fiat:
            decimalNumberTextFieldViewModel.update(value: fiatValue)
            amountDidChanged(amount: .alternative(fiat: fiatValue, crypto: balanceValue))
        }
    }

    func setExternalAmount(_ amount: Decimal?) {
        decimalNumberTextFieldViewModel.update(value: amount)
        textFieldValueDidChanged(amount: amount)
    }
}

// MARK: - Private

private extension SendAmountViewModel {
    func bind() {
        $amountType
            .removeDuplicates()
            .pairwise()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amountType in
                let (previous, newAmountType) = amountType
                viewModel.update(previous: previous, newAmountType: newAmountType)
            }
            .store(in: &bag)

        decimalNumberTextFieldViewModel.valuePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.textFieldValueDidChanged(amount: value)
            }
            .store(in: &bag)
    }

    func textFieldValueDidChanged(amount: Decimal?) {
        guard let amount else {
            amountDidChanged(amount: .none)
            error = nil
            return
        }

        do {
            switch amountType {
            case .crypto:
                try validator.validate(amount: amount)
                let fiatValue = convertToFiat(value: amount)
                amountDidChanged(amount: .typical(crypto: amount, fiat: fiatValue))
            case .fiat:
                guard let cryptoValue = convertToCrypto(value: amount) else {
                    throw CommonError.noData
                }

                try validator.validate(amount: cryptoValue)
                amountDidChanged(amount: .alternative(fiat: amount, crypto: cryptoValue))
            }
        } catch {
            self.error = error.localizedDescription
            amountDidChanged(amount: .none)
        }
    }

    func amountDidChanged(amount: CryptoFiatAmount?) {
        output?.amountDidChanged(amount: amount)
        alternativeAmount = cryptoFiatAmountFormatter.formatAlternative(amount: amount)
    }

    func update(previous amountType: AmountType, newAmountType: AmountType) {
        switch (amountType, newAmountType) {
        case (.fiat, .crypto):
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            let fiatValue = decimalNumberTextFieldViewModel.value
            let cryptoValue = convertToCrypto(value: fiatValue)

            decimalNumberTextFieldViewModel.update(value: cryptoValue)
            amountDidChanged(amount: .typical(crypto: cryptoValue, fiat: fiatValue))
        case (.crypto, .fiat):
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: 2)
            let cryptoValue = decimalNumberTextFieldViewModel.value
            let fiatValue = convertToFiat(value: cryptoValue)

            decimalNumberTextFieldViewModel.update(value: fiatValue)
            amountDidChanged(amount: .alternative(fiat: fiatValue, crypto: cryptoValue))
        case (.crypto, .crypto), (.fiat, .fiat):
            break
        }
    }

    func convertToCrypto(value: Decimal?) -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if input?.amount?.fiat == value {
            return input?.amount?.crypto
        }

        return cryptoFiatAmountConverter.convertToCrypto(value, tokenItem: tokenItem)
    }

    func convertToFiat(value: Decimal?) -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if input?.amount?.crypto == value {
            return input?.amount?.fiat
        }

        return cryptoFiatAmountConverter.convertToFiat(value, tokenItem: tokenItem)
    }
}

// MARK: - AuxiliaryViewAnimatable

extension SendAmountViewModel: AuxiliaryViewAnimatable {}

extension SendAmountViewModel {
    enum AmountType: Hashable {
        case crypto
        case fiat
    }

    struct Initital {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceValue: Decimal
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData

        let predefinedAmount: Decimal?
    }
}
