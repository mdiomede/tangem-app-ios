//
//  SecurityPrivacyView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SecurityPrivacyView: View {
    @ObservedObject var viewModel: SecurityPrivacyViewModel
    
    var body: some View {
        List {
            securitySection
                
            privacySection
            
            saveAccessCodeSection
        }
        .listStyle(DefaultListStyle())
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("security_and_privacy_title", displayMode: .inline)
    }
    
    private var securitySection: some View {
        Section(content: {
            RowView(
                title: "security_and_privacy_security_mode".localized,
                action: viewModel.openChangeAccessMethod
            )
            
            RowView(
                title: "security_and_privacy_change_access_code".localized,
                action: viewModel.openChangeAccessCode
            )
        }, header: {
            HeaderView(title: "security_and_privacy_security".localized)
        }, footer: {
            FooterView(title: "security_and_privacy_change_access_code_footer".localized)
        })
    }

    private var privacySection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_cards".localized,
                isOn: $viewModel.isSavedCards
            )
        }, header: {
            HeaderView(title: "security_and_privacy_privacy".localized)
        }, footer: {
            FooterView(title: "security_and_privacy_saved_cards_footer".localized)
        })
    }
    
    private var saveAccessCodeSection: some View {
        Section(content: {
            ToggleRowView(
                title: "security_and_privacy_saved_access_codes".localized,
                isOn: $viewModel.isSavedPasswords
            )
        }, footer: {
            FooterView(title: "security_and_privacy_saved_access_codes_footer".localized)
        })
    }
}

private extension SecurityPrivacyView {
    struct HeaderView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .font(.regular13)
                .foregroundColor(.textTertiary)
        }
    }
    
    struct FooterView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .font(.regular13)
                .foregroundColor(.textTertiary)
        }
    }
    
    struct RowView: View {
        let title: String
        let action: () -> Void
        
        var body: some View {
            HStack {
                Button(action: action) {
                    Text(title)
                        .font(.regular17)
                        .foregroundColor(.tangemGrayDark6)
                }
                
                Spacer()
                
                Image("chevron")
            }
        }
    }
    
    struct ToggleRowView: View {
        let title: String
        let isOn: Binding<Bool>
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.regular17)
                    .foregroundColor(.tangemGrayDark6)
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .toggleStyleCompat(.tangemGreen)
            }
        }
    }
}

struct SecurityPrivacyView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecurityPrivacyView(viewModel: .mock)
                .deviceForPreview(.iPhone11Pro)
        }
    }
}

private extension SecurityPrivacyViewModel {
    static let mock = SecurityPrivacyViewModel(
        cardModel: CardViewModel(cardInfo: CardInfo(card: .card, walletData: nil, artwork: .noArtwork, twinCardInfo: nil, isTangemNote: false, isTangemWallet: false, derivedKeys: [:], primaryCard: nil)),
        coordinator: SecurityPrivacyCoordinator()
    )
}
