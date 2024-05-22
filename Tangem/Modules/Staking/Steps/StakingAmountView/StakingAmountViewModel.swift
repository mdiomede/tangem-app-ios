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

    @Published var walletName: String = ""
    @Published var balance: LoadableTextView.State = .initialized
    @Published var tokenIconInfo: TokenIconInfo
    @Published var decimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published var alternativeAmount: LoadableTextView.State = .initialized

    @Published var error: String?
    @Published var currentFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published var useFiatCalculation: Bool = false

    let currencyPickerDisabled: Bool = false
    var cryptoIconURL: URL?
    let cryptoCurrencyCode: String = "ETH"
    var fiatIconURL: URL?
    let fiatCurrencyCode: String = "USD"
    let fiatCurrencySymbol: String = "USD"

    // MARK: - Dependencies

    private let walletModel: WalletModel
    private weak var coordinator: StakingAmountRoutable?
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    init(
        walletModel: WalletModel,
        coordinator: StakingAmountRoutable
    ) {
        self.walletName = "Wallet"
        self.balance = .loaded(text: "15 SOL (2 145,57 $)")
        self.walletModel = walletModel
        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        currentFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
        decimalNumberTextFieldViewModel = .init(maximumFractionDigits: 8)

        self.coordinator = coordinator
    }

    func bind() {
        currentFieldOptions = useFiatCalculation ? prefixSuffixOptionsFactory.makeCryptoOptions() : prefixSuffixOptionsFactory.makeFiatOptions()
    }

    func setupAmountFormatting() {}
}
