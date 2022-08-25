//
//  CardViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine
import Alamofire
import SwiftUI

struct CardPinSettings {
    var isPin1Default: Bool? = nil
    var isPin2Default: Bool? = nil
}

class CardViewModel: Identifiable, ObservableObject {
    // MARK: Services
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.scannedCardsRepository) private var scannedCardsRepository: ScannedCardsRepository

//    @Published var state: State = .created
    @Published private(set) var currentSecurityOption: SecurityModeOption = .longTap
    @Published var walletsBalanceState: WalletsBalanceState = .loaded

    var signer: TangemSigner { config.tangemSigner }
    var cardId: String { cardInfo.card.cardId }
    var userWalletId: String { cardInfo.card.userWalletId }

    var isMultiWallet: Bool {
        config.hasFeature(.multiCurrency)
    }

    var emailData: [EmailCollectedData] {
        config.emailData
    }

    var emailConfig: EmailConfig {
        config.emailConfig
    }

    var cardIdFormatted: String {
        cardInfo.cardIdFormatted
    }

    var cardIssuer: String {
        cardInfo.card.issuer.name
    }

    var cardSignedHashes: Int {
        cardInfo.card.walletSignedHashes
    }

    var canCreateBackup: Bool {
        config.hasFeature(.backup)
    }

    var canTwin: Bool {
        config.hasFeature(.twinning)
    }

    var shouldShowWC: Bool {
        !config.getFeatureAvailability(.walletConnect).isHidden
    }

    var cardTouURL: URL? {
        config.touURL
    }

    var canCountHashes: Bool {
        config.hasFeature(.signedHashesCounter)
    }

    private var cardInfo: CardInfo
    private var cardPinSettings: CardPinSettings = CardPinSettings()
    private let stateUpdateQueue = DispatchQueue(label: "state_update_queue")
//    private var migrated = false
    private var tangemSdk: TangemSdk { tangemSdkProvider.sdk }
    private var config: UserWalletConfig
    // TODO: Move it in UserWallet
    let userTokenListManager: UserTokenListManager
    let walletListManager: WalletListManager

    var availableSecurityOptions: [SecurityModeOption] {
        var options: [SecurityModeOption] = []

        if canSetLongTap || currentSecurityOption == .longTap {
            options.append(.longTap)
        }

        if config.hasFeature(.accessCode) || currentSecurityOption == .accessCode {
            options.append(.accessCode)
        }

        if config.hasFeature(.passcode) || currentSecurityOption == .passCode {
            options.append(.passCode)
        }

        return options
    }

    var hdWalletsSupported: Bool {
        config.hasFeature(.hdWallets)
    }

    var walletModels: [WalletModel] {
        walletListManager.getWalletModels()
    }

    var wallets: [Wallet] {
        walletModels.map { $0.wallet }
    }

    var canSetLongTap: Bool {
        config.hasFeature(.longTap)
    }

    var longHashesSupported: Bool {
        config.hasFeature(.longHashes)
    }

    var canSend: Bool {
        config.hasFeature(.send)
    }

    var hasWallet: Bool {
        !walletModels.isEmpty
    }

    var cardSetLabel: String? {
        config.cardSetLabel
    }

    var canShowAddress: Bool {
        config.hasFeature(.receive)
    }

    var canShowSend: Bool {
        config.hasFeature(.withdrawal)
    }

    var supportedBlockchains: Set<Blockchain> {
        config.supportedBlockchains
    }

    var backupInput: OnboardingInput? {
        guard let backupSteps = config.backupSteps else { return nil }

        return OnboardingInput(steps: backupSteps,
                               cardInput: .cardModel(self),
                               welcomeStep: nil,
                               twinData: nil,
                               currentStepIndex: 0,
                               isStandalone: true)
    }

    var onboardingInput: OnboardingInput {
        OnboardingInput(steps: config.onboardingSteps,
                        cardInput: .cardModel(self),
                        welcomeStep: nil,
                        twinData: cardInfo.walletData.twinData,
                        currentStepIndex: 0)
    }

    var twinInput: OnboardingInput? {
        guard config.hasFeature(.twinning) else { return nil }


        return OnboardingInput(
            steps: .twins(TwinsOnboardingStep.twinningSteps),
            cardInput: .cardModel(self),
            welcomeStep: nil,
            twinData: cardInfo.walletData.twinData,
            currentStepIndex: 0,
            isStandalone: true)
    }


    var isResetToFactoryAvailable: Bool {
        config.hasFeature(.resetToFactory)
    }

    var isSuccesfullyLoaded: Bool {
        // TODO: Add extension
        !walletModels.isEmpty && walletModels.allSatisfy { $0.state.isSuccesfullyLoaded }
    }

    var hasBalance: Bool {
        walletModels.contains { $0.hasBalance } // Check it, maybe should use allSatisfy
    }

    var shoulShowLegacyDerivationAlert: Bool {
        config.warningEvents.contains(where: { $0 == .legacyDerivation })
    }

    var canExchangeCrypto: Bool { config.hasFeature(.exchange) }

    var cachedImage: UIImage? = nil

    var imageLoaderPublisher: AnyPublisher<UIImage, Never> {
        if let cached = cachedImage {
            return Just(cached).eraseToAnyPublisher()
        }

        return self.imageLoader
            .loadImage(cid: cardId,
                       cardPublicKey: cardInfo.card.cardPublicKey,
                       artworkInfo: cardInfo.artworkInfo)
            .map { [weak self] (image, canBeCached) -> UIImage in
                if canBeCached {
                    self?.cachedImage = image
                }

                return image
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        self.config = UserWalletConfigFactory(cardInfo).makeConfig()

        userTokenListManager = CommonUserTokenListManager(config: config, cardInfo: cardInfo)
        walletListManager = CommonWalletListManager(
            config: config,
            cardInfo: cardInfo,
            userTokenListManager: userTokenListManager
        )

        updateCardPinSettings()
        updateCurrentSecurityOption()
        bind()
    }

    func setupWarnings() {
        warningsService.setupWarnings(for: config)
    }

    /// What this method do?
    /// 1. `tryMigrateTokens` once, work with boolean switcher
    /// 2. Call `update` for every `walletModels`
    /// 3. Update the `walletsBalanceState` to `.inProgress` if needed and `.loaded` when the update completed
    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool) {
        if showProgressLoading {
            self.walletsBalanceState = .inProgress
        }

        // Create new walletModel if needed
        walletListManager.updateWalletModels()

        walletListManager
            .reloadAllWalletModels()
            .receive(on: RunLoop.main)
            .receiveCompletion { [weak self] _ in
                if showProgressLoading {
                    self?.walletsBalanceState = .loaded
                }
            }
            .store(in: &bag)
    }

    func subscribeWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeWalletModels()
    }

    func appendDefaultBlockchains() {
        userTokenListManager.append(entries: config.defaultBlockchains)
    }

    // MARK: - Security
    func changeSecurityOption(_ option: SecurityModeOption, completion: @escaping (Result<Void, Error>) -> Void) {
        switch option {
        case .accessCode:
            tangemSdk.startSession(with: SetUserCodeCommand(accessCode: nil),
                                   cardId: cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.cardPinSettings.isPin1Default = false
                    self.cardPinSettings.isPin2Default = true
                    self.updateCurrentSecurityOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Access Code"])
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(with: SetUserCodeCommand.resetUserCodes,
                                   cardId: cardId) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = true
                    self.updateCurrentSecurityOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Long tap"])
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(with: SetUserCodeCommand(passcode: nil),
                                   cardId: cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_passcode_body".localized)) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = false
                    self.updateCurrentSecurityOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Pass code"])
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Wallet

    func createWallet(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: CreateWalletAndReadTask(with: config.defaultCurve),
                               cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success(let card):
                self?.update(with: card)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .createWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func resetToFactory(completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: ResetToFactorySettingsTask(),
                               cardId: cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_purge_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success:
                Analytics.log(.factoryResetSuccess)
                self?.userTokenListManager.clearRepository(result: completion)
                self?.clearTwinPairKey()
                // self.update(with: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }

    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork {
        let derivationPath = derivationPath ?? blockchain.derivationPath(for: cardInfo.card.derivationStyle)
        return BlockchainNetwork(blockchain, derivationPath: derivationPath)
    }

    // MARK: - Update

    func getCardInfo() {
        cardInfo.artwork = .notLoaded
        guard config.hasFeature(.onlineImage) else {
            cardInfo.artwork = .noArtwork
            return
        }

        tangemSdk.loadCardInfo(cardPublicKey: cardInfo.card.cardPublicKey, cardId: cardId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let info):
                self.cardInfo.artwork =  info.artwork.map { .artwork($0) } ?? .noArtwork
            case .failure:
                self.cardInfo.artwork = .noArtwork
                self.warningsService.setupWarnings(for: self.config)
            }
        }
    }

    func update(with card: Card, derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]] = [:]) {
        print("🟩 Updating Card view model with new Card")
        cardInfo.card = card
        cardInfo.derivedKeys = derivedKeys
        updateCardPinSettings()
        updateCurrentSecurityOption()
        updateModel()
    }

    func update(with cardInfo: CardInfo) {
        print("🔷 Updating Card view model with new CardInfo")
        self.cardInfo = cardInfo
        updateCardPinSettings()
        updateCurrentSecurityOption()
        updateModel()
    }

    func clearTwinPairKey() { // TODO: refactor and remove
        if case let .twin(walletData, twinData) = cardInfo.walletData {
            let newData = TwinData(series: twinData.series)
            cardInfo.walletData = .twin(walletData, newData)
        }
    }

    func logSdkError(_ error: Error, action: Analytics.Action, parameters: [Analytics.ParameterKey: Any] = [:]) {
        Analytics.logCardSdkError(error.toTangemSdkError(), for: action, card: cardInfo.card, parameters: parameters)
    }

    func didScan() {
        Analytics.logScan(card: cardInfo.card, config: config)
        tangemSdkProvider.setup(with: config.sdkConfig)
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        config.getFeatureAvailability(feature).disabledLocalizedReason
    }

    func getLegacyMigrator() -> LegacyCardMigrator? {
        guard config.hasFeature(.multiCurrency) else {
            return nil
        }

        // Check if we have anything to migrate. It's impossible to get default token without default blockchain
        guard let embeddedEntry = config.embeddedBlockchain else {
            return nil
        }

        return .init(cardId: cardId, embeddedEntry: embeddedEntry)
    }

    private func updateModel() {
        print("🔶 Updating Card view model")
        warningsService.setupWarnings(for: config)
        updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: true)
    }

    private func searchBlockchains() {
        guard config.hasFeature(.tokensSearch) else { return }

        searchBlockchainsCancellable = nil

        let currentBlockhains = wallets.map { $0.blockchain }
        let unused: [StorageEntry] = config.supportedBlockchains
            .subtracting(currentBlockhains)
            .map { StorageEntry(blockchainNetwork: .init($0, derivationPath: nil), tokens: []) }

        let models = unused.compactMap {
            try? config.makeWalletModel(for: $0, derivedKeys: cardInfo.derivedKeys)
        }

        if models.isEmpty {
            return
        }

        searchBlockchainsCancellable = Publishers.MergeMany(models.map { $0.update() })
            .collect()
            .receiveCompletion { [weak self] _ in
                guard let self = self else { return }

                let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
                if !notEmptyWallets.isEmpty {
                    let entries = notEmptyWallets.map {
                        StorageEntry(blockchainNetwork: $0.blockchainNetwork, tokens: [])
                    }

                    self.add(entries: entries) { result in } // TODO: Check it
                }
            }
    }

    private func searchTokens() {
        guard config.hasFeature(.tokensSearch),
              !AppSettings.shared.searchedCards.contains(cardId) else {
            return
        }

        guard let ethBlockchain = config.supportedBlockchains.first(where: {
            if case .ethereum = $0 {
                return true
            }

            return false
        }) else {
            return
        }

        var shouldAddWalletManager = false
        let network = getBlockchainNetwork(for: ethBlockchain, derivationPath: nil)
        var ethWalletModel = walletModels.first(where: { $0.blockchainNetwork == network })

        if ethWalletModel == nil {
            shouldAddWalletManager = true
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            ethWalletModel = try? config.makeWalletModel(for: entry, derivedKeys: cardInfo.derivedKeys)
        }

        guard let ethWalletModel = ethWalletModel,
              let tokenFinder = ethWalletModel.walletManager as? TokenFinder else {
            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
            return
        }

        tokenFinder.findErc20Tokens(knownTokens: []) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let tokensAdded):
                if tokensAdded, shouldAddWalletManager {
                    let tokens = ethWalletModel.walletManager.cardTokens
                    let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
                    self.add(entries: [entry], completion: { _ in }) // TODO: Check it
                }
            case .failure(let error):
                print(error)
            }

            AppSettings.shared.searchedCards.append(self.cardId)
            self.searchBlockchains()
        }
    }

    private func updateCardPinSettings() {
        cardPinSettings.isPin1Default = !cardInfo.card.isAccessCodeSet
        cardInfo.card.isPasscodeSet.map { self.cardPinSettings.isPin2Default = !$0 }
    }

    private func updateCurrentSecurityOption() {
        if !(cardPinSettings.isPin1Default ?? true) {
            self.currentSecurityOption = .accessCode
        } else if !(cardPinSettings.isPin2Default ?? true) {
            self.currentSecurityOption = .passCode
        }
        else {
            self.currentSecurityOption = .longTap
        }
    }

    private func bind() {
        signer.signPublisher.sink { [unowned self] card in
            self.cardInfo.card = card
            self.config = UserWalletConfigFactory(cardInfo).makeConfig()
            self.warningsService.setupWarnings(for: config)
            // TODO: Save user wallet
        }
        .store(in: &bag)
    }
}

// MARK: - Wallet models Operations

extension CardViewModel {
    /// Tempopary public
    func add(entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        userTokenListManager.append(entries: entries) { [weak self] result in
            switch result {
            case .success:
                completion(.success(()))
                self?.walletListManager.updateWalletModels()
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Tempopary public
    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        return walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    /// Tempopary public
    func remove(items: [(Amount.AmountType, BlockchainNetwork)]) {
        items.forEach {
            remove(amountType: $0.0, blockchainNetwork: $0.1)
        }
    }

    /// Tempopary public
    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {
        guard walletListManager.canRemove(amountType: amountType, blockchainNetwork: blockchainNetwork) else {
            assertionFailure("\(blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch amountType {
        case .coin:
            removeBlockchain(blockchainNetwork)
        case let .token(token):
            removeToken(token, blockchainNetwork: blockchainNetwork)
        case .reserve: break
        }
    }

    private func removeBlockchain(_ blockchainNetwork: BlockchainNetwork) {
        userTokenListManager.remove(blockchain: blockchainNetwork) { [weak self] result in
            switch result {
            case .success:
                self?.walletListManager.updateWalletModels()
            case let .failure(error):
                print("Remove blockchainNetwork error \(error)")
            }
        }
    }

    private func removeToken(_ token: BlockchainSdk.Token, blockchainNetwork: BlockchainNetwork) {
        userTokenListManager.remove(tokens: [token], in: blockchainNetwork) { [weak self] result in
            switch result {
            case .success:
                self?.walletListManager.removeToken(token, blockchainNetwork: blockchainNetwork)
                self?.walletListManager.updateWalletModels()
            //                _ = walletModel.removeToken(token)
            //                self?.updateState(shouldUpdate: false)
            case let .failure(error):
                print("Remove token error \(error)")
            }
        }
    }
}

extension CardViewModel {
    enum State {
        case created
        case empty
        case loaded(walletModel: [WalletModel])

        var walletModels: [WalletModel]? {
            switch self {
            case .loaded(let models):
                return models
            default:
                return nil
            }
        }
        var canUpdate: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }
    }
}

extension CardViewModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}
