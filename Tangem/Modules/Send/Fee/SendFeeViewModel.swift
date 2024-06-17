//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

class CommonSendFeeProvider: SendFeeProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        walletModel.getFee(amount: amount, destination: destination)
    }
}

protocol SendFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
}

struct SendFee: Hashable {
    let option: FeeOption
    let value: LoadingValue<Fee>
}

class CommonSendFeeProcessor {
    private let provider: SendFeeProvider
    private var customFeeService: CustomFeeService?

    private let _cryptoAmount: CurrentValueSubject<Amount?, Never> = .init(.none)
    private let _destination: CurrentValueSubject<String?, Never> = .init(.none)
    private let _fees: CurrentValueSubject<[SendFee], Never> = .init([])

    private let _customFee: CurrentValueSubject<SendFee?, Never> = .init(.none)
    private let defaultFeeOptions: [FeeOption]
    private var feeOptions: [FeeOption] {
        var options = defaultFeeOptions
        if supportCustomFee {
            options.append(.custom)
        }
        return options
    }

    private var supportCustomFee: Bool {
        customFeeService != nil
    }

    private var bag: Set<AnyCancellable> = []

    init(
        provider: SendFeeProvider,
        defaultFeeOptions: [FeeOption],
        customFeeServiceFactory: CustomFeeServiceFactory
    ) {
        self.provider = provider
        self.defaultFeeOptions = defaultFeeOptions

        customFeeService = customFeeServiceFactory.makeService(input: self, output: self)
    }

    func bind(input: SendFeeProcessorInput) {
        input.cryptoAmountPublisher
            .withWeakCaptureOf(self)
            .sink { processor, amount in
                processor._cryptoAmount.send(amount)
            }
            .store(in: &bag)

        input.destinationPublisher
            .withWeakCaptureOf(self)
            .sink { processor, destination in
                processor._destination.send(destination)
            }
            .store(in: &bag)
    }
}

// MARK: - CustomFeeServiceInput

extension CommonSendFeeProcessor: CustomFeeServiceInput {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> {
        _cryptoAmount.compactMap { $0 }.eraseToAnyPublisher()
    }

    var destinationPublisher: AnyPublisher<String, Never> {
        _destination.compactMap { $0 }.eraseToAnyPublisher()
    }
}

// MARK: - CustomFeeServiceOutput

extension CommonSendFeeProcessor: CustomFeeServiceOutput {
    func customFeeDidChanged(_ customFee: Fee?) {
        let fee = customFee.map { SendFee(option: .custom, value: .loaded($0)) }
        _customFee.send(fee)
    }
}

// MARK: - SendFeeProcessor

extension CommonSendFeeProcessor: SendFeeProcessor {
    func setup(input: SendFeeProcessorInput) {
        bind(input: input)
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value,
              let destination = _destination.value else {
            assertionFailure("SendFeeProcessor is not ready to update fees")
            return
        }

        provider
            .getFee(amount: amount, destination: destination)
            .sink(receiveCompletion: { [weak self] completion in
                guard case .failure(let error) = completion else {
                    return
                }

                self?.update(fees: .failedToLoad(error: error))
            }, receiveValue: { [weak self] fees in
                self?.update(fees: .loaded(fees))
            })
            .store(in: &bag)
    }

    func feesPublisher() -> AnyPublisher<[SendFee], Never> {
        _fees.dropFirst().eraseToAnyPublisher()
    }

    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel] {
        customFeeService?.inputFieldModels() ?? []
    }
}

// MARK: - Private

private extension CommonSendFeeProcessor {
    func update(fees value: LoadingValue<[Fee]>) {
        switch value {
        case .loading:
            _fees.send(feeOptions.map { SendFee(option: $0, value: .loading) })
        case .loaded(let fees):
            _fees.send(mapToFees(fees: fees))
        case .failedToLoad(let error):
            _fees.send(feeOptions.map { SendFee(option: $0, value: .failedToLoad(error: error)) })
        }
    }

    func mapToFees(fees: [Fee]) -> [SendFee] {
        var defaultOptions = mapToDefaultFees(fees: fees)

        if supportCustomFee {
            var customFee = _customFee.value

            if customFee == nil, let market = defaultOptions.first(where: { $0.option == .market }) {
                customFee = SendFee(option: .custom, value: market.value)
            }

            if let custom = customFee {
                defaultOptions.append(custom)
            }
        }

        return defaultOptions
    }

    func mapToDefaultFees(fees: [Fee]) -> [SendFee] {
        switch fees.count {
        case 1:
            return [SendFee(option: .market, value: .loaded(fees[1]))]
        case 3:
            return [
                SendFee(option: .slow, value: .loaded(fees[0])),
                SendFee(option: .market, value: .loaded(fees[1])),
                SendFee(option: .fast, value: .loaded(fees[2])),
            ]
        default:
            assertionFailure("Wrong count of fees")
            return []
        }
    }
}

protocol SendFeeProcessorInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> { get }
    var destinationPublisher: AnyPublisher<String, Never> { get }
}

protocol SendFeeProcessor {
    func updateFees()
    func feesPublisher() -> AnyPublisher<[SendFee], Never>
    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel]

    func setup(input: SendFeeProcessorInput)
}

protocol SendFeeInput: AnyObject {
    var selectedFee: SendFee? { get }
    var selectedFeePublisher: AnyPublisher<SendFee?, Never> { get }
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: SendFee?)
}

class SendFeeViewModel: ObservableObject {
    @Published private(set) var selectedFeeOption: FeeOption?
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

    @Published private(set) var deselectedFeeViewsVisible: Bool = false
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false

    var feeSelectorFooterText: String {
        Localization.commonFeeSelectorFooter("[\(Localization.commonReadMore)](\(feeExplanationUrl.absoluteString))")
    }

    var didProperlyDisappear = true

    @Published private(set) var feeLevelsNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var customFeeNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var feeCoverageNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let tokenItem: TokenItem

    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private weak var router: SendFeeRoutable?

    private let processor: SendFeeProcessor
    private let notificationManager: SendNotificationManager

//    private let walletInfo: SendWalletInfo
//    private let customFeeService: CustomFeeService?
//    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    // Save this values to compare it when the focus changed and send analytics
//    private var customFeeValue: Decimal?
//    private var customFeeBeforeEditing: Decimal?

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    private var bag: Set<AnyCancellable> = []

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(
        initial: Initial,
        input: SendFeeInput,
        output: SendFeeOutput,
        router: SendFeeRoutable,
        processor: SendFeeProcessor,
        notificationManager: SendNotificationManager
    ) {
        tokenItem = initial.tokenItem
        selectedFeeOption = input.selectedFee?.option

        self.input = input
        self.output = output
        self.router = router
        self.processor = processor
        self.notificationManager = notificationManager

//        self.customFeeService = customFeeService
//        self.walletInfo = walletInfo
//        feeOptions = input.feeOptions
//        selectedFeeOption = input.selectedFeeOption

//        if feeOptions.contains(.custom) {
//            createCustomFeeModels()
//        }

//        feeRowViewModels = makeFeeRowViewModels([:])

//        setupView()
        bind()
    }

    func onAppear() {
        let deselectedFeeViewAppearanceDelay = SendView.Constants.animationDuration / 3
        DispatchQueue.main.asyncAfter(deadline: .now() + deselectedFeeViewAppearanceDelay) {
            withAnimation(SendView.Constants.defaultAnimation) {
                self.deselectedFeeViewsVisible = true
            }
        }

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }
    }

    func onDisappear() {
        deselectedFeeViewsVisible = false
    }

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    /*
     private func createCustomFeeModels() {
         guard let customFeeService else { return }

         let editableCustomFeeService = customFeeService as? EditableCustomFeeService
         let onCustomFeeFieldChange: ((Decimal?) -> Void)?
         if let editableCustomFeeService {
             onCustomFeeFieldChange = { [weak self] value in
                 self?.customFeeValue = value
                 editableCustomFeeService.setCustomFee(value: value)
             }
         } else {
             onCustomFeeFieldChange = nil
         }

         let customFeeModel = SendCustomFeeInputFieldModel(
             title: Localization.sendMaxFee,
             amountPublisher: input.customFeePublisher.decimalPublisher,
             disabled: editableCustomFeeService == nil,
             fieldSuffix: walletInfo.feeCurrencySymbol,
             fractionDigits: walletInfo.feeFractionDigits,
             amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
             footer: customFeeService.customFeeDescription,
             onFieldChange: onCustomFeeFieldChange
         ) { [weak self] focused in
             self?.onCustomFeeChanged(focused)
         }

         customFeeModels = [customFeeModel] + customFeeService.inputFieldModels()
     }
     */

//    private func setupView() {
//        updateViewModels(values: feeOptions.reduce(into: [:]) { $0[$1] = .loading })
//    }

    private func bind() {
        processor.feesPublisher()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, values in
                viewModel.updateIfNeeded(values: values)
                viewModel.updateViewModels(values: values)
            }
            .store(in: &bag)

        input?.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.updateSelectedOption(selectedFee: selectedFee)
            }
            .store(in: &bag)

//        input
//            .customFeePublisher
//            .withWeakCaptureOf(self)
//            .map { (self, customFee) -> String? in
//                guard
//                    let customFee,
//                    let feeCurrencyId = self.walletInfo.feeCurrencyId,
//                    let fiatFee = self.balanceConverter.convertToFiat(customFee.amount.value, currencyId: feeCurrencyId)
//                else {
//                    return nil
//                }
//
//                return self.balanceFormatter.formatFiatBalance(fiatFee)
//            }
//            .withWeakCaptureOf(self)
//            .sink { (self, customFeeInFiat) in
//                self.customFeeInFiat.send(customFeeInFiat)
//            }
//            .store(in: &bag)

//        input.isFeeIncludedPublisher
//            .assign(to: \.isFeeIncluded, on: self, ownership: .weak)
//            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeLevels)
            .assign(to: \.feeLevelsNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .customFee)
            .assign(to: \.customFeeNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeIncluded)
            .assign(to: \.feeCoverageNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateSelectedOption(selectedFee: SendFee?) {
        selectedFeeOption = selectedFee?.option

        let showCustomFeeFields = selectedFee?.option == .custom
        customFeeModels = showCustomFeeFields ? processor.customFeeInputFieldModels() : []
    }

    private func updateIfNeeded(values: [SendFee]) {
        guard input?.selectedFee == nil,
              let market = values.first(where: { $0.option == .market }) else {
            return
        }

        output?.feeDidChanged(fee: market)
    }

    private func updateViewModels(values: [SendFee]) {
        feeRowViewModels = values.map { fee in
            mapToFeeRowViewModel(fee: fee)
        }
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel {
        let feeComponents = mapToFormattedFeeComponents(fee: fee.value)

        return FeeRowViewModel(
            option: fee.option,
            formattedFeeComponents: feeComponents,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == fee.option
            }, set: { root, newValue in
                if newValue {
                    root.userDidSelected(fee: fee)
                }
            })
        )
    }

    private func mapToFormattedFeeComponents(fee: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch fee {
        case .loading:
            return .loading
        case .loaded(let value):
            let feeComponents = feeFormatter.formattedFeeComponents(fee: value.amount.value, tokenItem: tokenItem)
            return .loaded(feeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }

    private func userDidSelected(fee: SendFee) {
        if fee.option == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        selectedFeeOption = fee.option
        output?.feeDidChanged(fee: fee)
    }
}

extension SendFeeViewModel: AuxiliaryViewAnimatable {}

extension SendFeeViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let feeOptions: [FeeOption]
    }
}

// MARK: - private extensions

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.amount.value }.eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}
