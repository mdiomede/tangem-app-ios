//
//  StakingValidatorsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.xw
//

import Combine
import TangemStaking
import SwiftUI

final class StakingValidatorsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var selectedValidator: String = ""
    @Published var auxiliaryViewsVisible: Bool = true

    // MARK: - Dependencies

    private let interactor: StakingValidatorsInteractor

    private let stakingValidatorViewMapper = StakingValidatorViewMapper()
    private var bag: Set<AnyCancellable> = []

    init(interactor: StakingValidatorsInteractor) {
        self.interactor = interactor

        bind()
    }

    func onAppear() {
        auxiliaryViewsVisible = true
    }

    func onDisappear() {
        auxiliaryViewsVisible = false
    }
}

// MARK: - Private

private extension StakingValidatorsViewModel {
    func bind() {
        interactor
            .validatorsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, validators in
                validators.map {
                    viewModel.stakingValidatorViewMapper.mapToValidatorViewData(info: $0, detailsType: .checkmark)
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .selectedValidatorPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            // If viewModel already has selectedValidator
            .filter { $0.selectedValidator != $1.address }
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedValidator in
                viewModel.selectedValidator = selectedValidator.address
            }
            .store(in: &bag)

        $selectedValidator
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, validatorAddress in
                viewModel.interactor.userDidSelect(validatorAddress: validatorAddress)
            }
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension StakingValidatorsViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        switch state {
        case .appearing(.summary(_)):
            // Will be shown with animation
            auxiliaryViewsVisible = false
        case .disappearing(.summary(_)):
            auxiliaryViewsVisible = false
        default:
            break
        }
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
