//
//  StakingAmountViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakingAmountViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var userWalletName: String
    @Published var balance: LoadableTextView.State
    @Published var tokenIconInfo: TokenIconInfo
    @Published var currencyPickerData: SendCurrencyPickerData

    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: LoadableTextView.State = .initialized

    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var useFiatCalculation: Bool = false

    // MARK: - Dependencies

    private let cryptoFiatAmountConverter: CryptoFiatAmountConverter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private let walletModel: WalletModel
    private weak var coordinator: StakingAmountRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        input: StakingAmountViewModel.Input,
        coordinator: StakingAmountRoutable
    ) {
        userWalletName = input.userWalletName
        balance = .loaded(text: input.balanceFormatted)
        tokenIconInfo = input.tokenIconInfo
        currencyPickerData = input.currencyPickerData

        cryptoFiatAmountConverter = .init(maximumFractionDigits: input.tokenItem.decimalCount)
        prefixSuffixOptionsFactory = .init(
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: input.tokenItem.decimalCount)

        self.walletModel = walletModel
        self.coordinator = coordinator

        bind()
    }

    func userDidTapMaxAmount() {
        if useFiatCalculation {
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(walletModel.balanceValue, tokenItem: walletModel.tokenItem)
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        } else {
            decimalNumberTextFieldViewModel.update(value: walletModel.balanceValue)
        }
    }
}

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
            }
            .store(in: &bag)
    }

    func update(useFiat: Bool) {
        if useFiat {
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(
                decimalNumberTextFieldViewModel.value,
                tokenItem: walletModel.tokenItem
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        } else {
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToCrypto(
                decimalNumberTextFieldViewModel.value,
                tokenItem: walletModel.tokenItem
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        }

        updateAlternativeAmount(value: decimalNumberTextFieldViewModel.value)
    }

    func updateAlternativeAmount(value: Decimal?) {
        if useFiatCalculation {
            let cryptoValue = cryptoFiatAmountConverter.convertToCrypto(value, tokenItem: walletModel.tokenItem)
            let formatted = BalanceFormatter().formatCryptoBalance(cryptoValue, currencyCode: walletModel.tokenItem.currencySymbol)
            alternativeAmount = .loaded(text: formatted)
        } else {
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(value, tokenItem: walletModel.tokenItem)
            let formatted = BalanceFormatter().formatFiatBalance(fiatValue)
            alternativeAmount = .loaded(text: formatted)
        }
    }
}

extension StakingAmountViewModel {
    struct Input {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let balanceFormatted: String
        let currencyPickerData: SendCurrencyPickerData
    }
}
