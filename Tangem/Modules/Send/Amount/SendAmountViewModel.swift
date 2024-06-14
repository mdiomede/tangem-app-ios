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
    var amount: CryptoFiatAmount { get }

    func amountPublisher() -> AnyPublisher<CryptoFiatAmount, Never>
}

protocol SendAmountOutput: AnyObject {
    func amountDidChanged(amount: CryptoFiatAmount)
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
    private let sendAmountFormatter: SendAmountFormatter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        initial: SendAmountViewModel.Initital,
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator,
        sendAmountFormatter: SendAmountFormatter,
        cryptoFiatAmountConverter: CryptoFiatAmountConverter
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
        self.sendAmountFormatter = sendAmountFormatter

        bind()
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
            output?.amountDidChanged(amount: .typical(crypto: balanceValue, fiat: fiatValue))
        case .fiat:
            decimalNumberTextFieldViewModel.update(value: fiatValue)
            output?.amountDidChanged(amount: .alternative(fiat: fiatValue, crypto: balanceValue))
        }
    }
}

// MARK: - Private

private extension SendAmountViewModel {
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
                viewModel.amountDidChanged(value: value)
            }
            .store(in: &bag)

        input?
            .amountPublisher()
            .withWeakCaptureOf(self)
            .map { viewModel, amount in
                viewModel.sendAmountFormatter.formatAlternative(amount: amount)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.alternativeAmount, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func amountDidChanged(value: Decimal?) {
        switch amountType {
        case .crypto:
            let fiatValue = convertToFiat(value: value)
            output?.amountDidChanged(amount: .typical(crypto: value, fiat: fiatValue))
            validate(amount: value)
        case .fiat:
            let cryptoValue = convertToCrypto(value: value)
            output?.amountDidChanged(amount: .alternative(fiat: value, crypto: cryptoValue))
            validate(amount: cryptoValue)
        }
    }

    func validate(amount: Decimal?) {
        guard let amount else {
            error = nil
            return
        }

        do {
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
            output?.amountDidChanged(amount: .typical(crypto: cryptoValue, fiat: uiValue))
        case .fiat:
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            decimalNumberTextFieldViewModel.update(maximumFractionDigits: 2)
            let uiValue = decimalNumberTextFieldViewModel.value
            let fiatValue = convertToFiat(value: uiValue)

            decimalNumberTextFieldViewModel.update(value: fiatValue)
            output?.amountDidChanged(amount: .alternative(fiat: fiatValue, crypto: uiValue))
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
    }
}
