//
//  DerivationManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk
import Combine

class CommonDerivationManager {
    weak var delegate: DerivationManagerDelegate?

    private let keysRepository: KeysRepository
    private let userTokenListManager: UserTokenListManager

    private var bag = Set<AnyCancellable>()
    private var _hasPendingDerivations: CurrentValueSubject<Bool, Never> = .init(false)

    private var pendingDerivations: [Data: [DerivationPath]] = [:]

    internal init(keysRepository: KeysRepository, userTokenListManager: UserTokenListManager) {
        self.keysRepository = keysRepository
        self.userTokenListManager = userTokenListManager
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .sink { [weak self] entries in
                self?.process(entries)
            }
            .store(in: &bag)
    }

    private func process(_ entries: [StorageEntry]) {
        let currentKeys = keysRepository.keys

        entries.forEach { entry in
            let curve = entry.blockchainNetwork.blockchain.curve

            guard let derivationPath = entry.blockchainNetwork.derivationPath,
                  let masterKey = currentKeys.first(where: { $0.curve == curve }),
                  !masterKey.derivedKeys.keys.contains(derivationPath) else {
                return
            }

            pendingDerivations[masterKey.publicKey, default: []].append(derivationPath)
        }

        _hasPendingDerivations.send(!pendingDerivations.isEmpty)
    }
}

extension CommonDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        _hasPendingDerivations.eraseToAnyPublisher()
    }

    func deriveKeys(cardInteractor: CardDerivable, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard !pendingDerivations.isEmpty else {
            completion(.success(()))
            return
        }

        var interactor: CardDerivable? = cardInteractor

        interactor?.deriveKeys(derivations: pendingDerivations) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                var keys = keysRepository.keys
                for updatedWallet in response {
                    for derivedKey in updatedWallet.value.keys {
                        keys[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                    }
                }

                // TODO: refactor storage to single source
                keysRepository.update(keys: keys)
                delegate?.onDerived(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            interactor = nil
        }
    }
}
