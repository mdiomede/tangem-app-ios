//
//  StakingAmountViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

struct CryptoFiatAmountConverter {
    let formatter: DecimalNumberFormatter

    init(maximumFractionDigits: Int) {
        formatter = DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits)
    }

    func convertToCrypto(_ value: Decimal?, currencyId: String?) -> Decimal? {
        guard let value,
              let currencyId,
              let cryptoValue = BalanceConverter().convertFromFiat(value, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: 2)
        let string = formatter.format(value: formatter.mapToString(decimal: cryptoValue))
        return formatter.mapToDecimal(string: string)
    }

    func convertToFiat(_ value: Decimal?, currencyId: String?) -> Decimal? {
        guard let value,
              let currencyId,
              let fiatValue = BalanceConverter().convertToFiat(value, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: 2)
        let string = formatter.format(value: formatter.mapToString(decimal: fiatValue))
        return formatter.mapToDecimal(string: string)
    }
}

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
        prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: input.tokenItem.decimalCount)

        self.walletModel = walletModel
        self.coordinator = coordinator

        bind()
    }

    func bind() {
        $useFiatCalculation
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, useFiat in
                viewModel.update(useFiat: useFiat)
            }
            .store(in: &bag)
    }

    func update(useFiat: Bool) {
        if useFiat {
            currentFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToFiat(
                decimalNumberTextFieldViewModel.value,
                currencyId: walletModel.tokenItem.currencyId
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        } else {
            currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            let fiatValue = cryptoFiatAmountConverter.convertToCrypto(
                decimalNumberTextFieldViewModel.value,
                currencyId: walletModel.tokenItem.currencyId
            )
            decimalNumberTextFieldViewModel.update(value: fiatValue)
        }
    }

    func setupAmountFormatting() {}
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
