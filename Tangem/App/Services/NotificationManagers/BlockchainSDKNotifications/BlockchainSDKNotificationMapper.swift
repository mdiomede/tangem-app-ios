//
//  BlockchainSDKNotificationMapper.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 21.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import enum BlockchainSdk.ValidationError
import enum BlockchainSdk.WithdrawalNotification

struct BlockchainSDKNotificationMapper {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private var tokenItemSymbol: String { tokenItem.currencySymbol }

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func mapToValidationErrorEvent(_ validationError: ValidationError) -> ValidationErrorEvent {
        switch validationError {
        case .balanceNotFound, .invalidAmount, .invalidFee:
            return .invalidNumber
        case .amountExceedsBalance, .totalExceedsBalance:
            return .insufficientBalance
        case .feeExceedsBalance:
            return .insufficientBalanceFee(
                configuration: .init(
                    transactionAmountTypeName: tokenItem.name,
                    feeAmountTypeName: feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: feeTokenItem.currencySymbol,
                    feeAmountTypeIconName: feeTokenItem.blockchain.iconNameFilled,
                    networkName: tokenItem.networkName,
                    currencyButtonTitle: nil
                )
            )
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            let amountText = "\(minimumAmount.value) \(tokenItemSymbol)"
            return .dustAmount(minimumAmountText: amountText, minimumChangeText: amountText)
        case .minimumBalance(let minimumBalance):
            return .existentialDepositWarning(amount: minimumBalance.value, amountFormatted: minimumBalance.string())
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxo):
            return .withdrawalMandatoryAmountChange(amount: newAmount.value, amountFormatted: newAmount.string(), blockchainName: blockchainName, maxUtxo: maxUtxo)
        case .reserve(let amount):
            return .notEnoughReserveToSwap(minimumAmountText: "\(amount.value)\(tokenItemSymbol)")
        case .cardanoHasTokens:
            return .cardanoHasTokens
        case .cardanoInsufficientBalanceToSendToken:
            return .cardanoInsufficientBalanceToSendToken(tokenSymbol: tokenItemSymbol)
        }
    }

    func mapToWithdrawalNotificationEvent(_ notification: WithdrawalNotification) -> WithdrawalNotificationEvent {
        switch notification {
        case .feeIsTooHigh(let reduceAmountBy):
            return .withdrawalOptionalAmountChange(
                amount: reduceAmountBy.value,
                amountFormatted: reduceAmountBy.string(),
                blockchainName: tokenItem.blockchain.displayName
            )
        case .cardanoWillBeSendAlongToken(let amount):
            return .cardanoWillBeSentWithToken(
                cardanoAmountFormatted: amount.value.description,
                tokenSymbol: tokenItem.currencySymbol
            )
        }
    }
}
