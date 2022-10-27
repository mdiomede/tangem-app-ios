//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OnboardingCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view models
    @Published private(set) var singleCardViewModel: SingleCardOnboardingViewModel? = nil
    @Published private(set) var twinsViewModel: TwinsOnboardingViewModel? = nil
    @Published private(set) var walletViewModel: WalletOnboardingViewModel? = nil

    // MARK: - Child coordinators
    @Published var mainCoordinator: MainCoordinator? = nil

    // MARK: - Child view models
    @Published var buyCryptoModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    @Published var addressQrBottomSheetContentViewVodel: AddressQrBottomSheetContentViewVodel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil

    // For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}

    private var options: OnboardingCoordinator.Options!

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: OnboardingCoordinator.Options) {
        self.options = options
        let input = options.input
        switch input.steps {
        case .singleWallet:
            let model = SingleCardOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            singleCardViewModel = model
        case .twins:
            let model = TwinsOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            twinsViewModel = model
        case .wallet:
            let model = WalletOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            walletViewModel = model
        }
    }
}

extension OnboardingCoordinator {
    enum DestinationOnFinish {
        case main, root, dismiss
    }
    struct Options {
        let input: OnboardingInput
        let destination: DestinationOnFinish
    }
}

extension OnboardingCoordinator: OnboardingTopupRoutable {
    func openCryptoShop(at url: URL, closeUrl: String, action: @escaping (String) -> Void) {
        buyCryptoModel = .init(url: url,
                               title: "wallet_button_topup".localized,
                               addLoadingIndicator: true,
                               withCloseButton: true, urlActions: [closeUrl: { [weak self] response in
                                   DispatchQueue.main.async {
                                       action(response)
                                       self?.buyCryptoModel = nil
                                   }
                               }])
    }

    func openQR(shareAddress: String, address: String, qrNotice: String) {
        addressQrBottomSheetContentViewVodel = .init(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
    }
}

extension OnboardingCoordinator: WalletOnboardingRoutable {
    func openAccessCodeView(callback: @escaping (String) -> Void) {
        accessCodeModel = .init(successHandler: { [weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }

    func openSupportChat(cardId: String, dataCollector: EmailDataCollector) {
        supportChatViewModel = SupportChatViewModel(cardId: cardId, dataCollector: dataCollector)
    }
}

extension OnboardingCoordinator: OnboardingRoutable {
    func onboardingDidFinish() {
        switch options.destination {
        case .main:
            guard let card = options.input.cardInput.cardModel else {
                closeOnboarding()
                return
            }
            
            openMain(with: card)
        case .root:
            popToRoot()
        case .dismiss:
            closeOnboarding()
        }
    }

    func closeOnboarding() {
        dismiss()
    }

    private func openMain(with cardModel: CardViewModel) {
        Analytics.log(.screenOpened)
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        mainCoordinator = coordinator
    }
}
