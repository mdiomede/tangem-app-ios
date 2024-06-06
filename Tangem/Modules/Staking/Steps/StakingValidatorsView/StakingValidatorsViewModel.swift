//
//  StakingValidatorsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemStaking

final class StakingValidatorsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var validators: [StakingValidatorViewData]
    @Published var selectedValidators: [String] = []

    // MARK: - Dependencies

    private weak var input: StakingValidatorsInput?
    private weak var output: StakingValidatorsOutput?
    private weak var coordinator: StakingValidatorsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        inputModel: StakingValidatorsViewModel.Input,
        input: StakingValidatorsInput,
        output: StakingValidatorsOutput,
        coordinator: StakingValidatorsRoutable
    ) {
        let percentFormatter = PercentFormatter()
        validators = inputModel.validators.map { validator in
            StakingValidatorViewData(
                id: validator.address,
                imageURL: validator.iconURL,
                name: validator.name,
                aprFormatted: validator.apr.map(percentFormatter.expressRatePercentFormat(value:))
            )
        }

        self.input = input
        self.output = output
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
//        setupView()
    }
}

extension StakingValidatorsViewModel {
//    func setupView() {}

    func bind() {
        input?.validatorPublisher()
            .map { validator in
                switch validator {
                case .single(let validator): validator.address
                case .multiple(let validators): validators.map { $0.address }
                }
            }
            .assign(to: \.selectedValidators, on: self, ownership: .weak)
            .store(bag)
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
