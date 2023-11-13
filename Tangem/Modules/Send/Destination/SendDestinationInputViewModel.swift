//
//  SendDestinationInputViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendDestinationInputViewModel: Identifiable {
    let name: String
    var input: Binding<String>
    let showAddressIcon: Bool
    let placeholder: String
    let description: String
    let didPasteAddress: ([String]) -> Void

    var hasTextInClipboard = false
    var errorText: String?

    init(name: String, input: Binding<String>, showAddressIcon: Bool, placeholder: String, description: String, didPasteAddress: @escaping ([String]) -> Void) {
        self.name = name
        self.input = input
        self.showAddressIcon = showAddressIcon
        self.placeholder = placeholder
        self.description = description
        self.didPasteAddress = didPasteAddress

        NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
            .sink { [weak self] _ in
                self?.updatePasteButton()
            }
            .store(in: &bag)

        updatePasteButton()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func onAppear() {
        updatePasteButton()
    }

    func onBecomingActive() {
        updatePasteButton()
    }

    func didTapLegacyPasteButton() {
        guard let input = UIPasteboard.general.string else {
            return
        }

        didPasteAddress([input])
    }

    func clearInput() {
        input.wrappedValue = ""
    }

    private func updatePasteButton() {
        hasTextInClipboard = UIPasteboard.general.hasStrings
    }
}
