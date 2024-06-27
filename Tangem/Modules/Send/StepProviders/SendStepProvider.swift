//
//  SendStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

protocol SendStep {
    associatedtype ViewModel: ObservableObject
    associatedtype StepView: View
//    associatedtype StepCompactView: View

    var viewModel: ViewModel { get }

    var type: SendStepName { get }
    var title: String? { get }
    var subtitle: String? { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func makeView(namespace: Namespace.ID) -> StepView
//    func makeCompactView(namespace: Namespace.ID) -> StepCompactView

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool
    func willAppear(previous step: any SendStep)
    func willClose(next step: any SendStep)
}

extension SendStep {
    var subtitle: String? { nil }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool { true }

    func willAppear(previous step: any SendStep) {}
    func willClose(next step: any SendStep) {}
}

enum SendStepName {
    case destination
    case amount
    case fee
    case summary
    case finish
}
