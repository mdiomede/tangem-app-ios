//
//  SendTransitionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendTransitionService {
    var destinationContentOffset: CGPoint = .zero
    var amountContentOffset: CGPoint = .zero
    var validatorsContentOffset: CGPoint = .zero
    var selectedValidatorContentOffset: CGPoint = .zero
    var feeContentOffset: CGPoint = .zero
    var selectedFeeContentOffset: CGPoint = .zero

    // MARK: - Destination

    func transitionToDestinationStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -destinationContentOffset.y) : .move(edge: .leading)
    }

    func transitionToDestinationCompactView(isEditMode: Bool) -> AnyTransition {
        .asymmetric(
            insertion: isEditMode ? .offset().combined(with: .opacity) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Amount

    func transitionToAmountStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -amountContentOffset.y) : .move(edge: .trailing)
    }

    func transitionToAmountCompactView(isEditMode: Bool) -> AnyTransition {
        .asymmetric(
            insertion: isEditMode ? .offset().combined(with: .opacity) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Validators

    func transitionToValidatorsStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -validatorsContentOffset.y) : .move(edge: .trailing)
    }

    func transitionToValidatorsCompactView(isEditMode: Bool) -> AnyTransition {
        let offset = -selectedValidatorContentOffset.y + validatorsContentOffset.y
        return .asymmetric(
            insertion: isEditMode ? .offset(y: offset) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Fee

    func transitionToFeeStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -feeContentOffset.y) : .move(edge: .trailing)
    }

    func transitionToFeeCompactView(isEditMode: Bool) -> AnyTransition {
        let offset: CGFloat = -selectedFeeContentOffset.y + feeContentOffset.y
        return .asymmetric(
            insertion: .offset(y: offset),
            removal: .opacity
        )
    }

    // MARK: - Summary

    var summaryViewTransition: AnyTransition {
        .asymmetric(insertion: .opacity, removal: .opacity)
    }
}
