//
//  ViewController.swift
//  Tangem
//
//  Created by Yulia Moskaleva on 24/01/2018.
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemKit

class ReaderViewController: UIViewController, TestCardParsingCapable, DefaultErrorAlertsCapable {
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    var tangemSession: TangemSession?
    
    private struct Constants {
        static let hintLabelDefaultText = "Press Scan and touch banknote with your iPhone as shown above"
        static let hintLabelScanningText = "Hold the card close to the reader"
    }
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel! {
        didSet {
            hintLabel.font = UIFont.tgm_maaxFontWith(size: 16.0, weight: .medium)
        }
    }
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var warningLabelButton: UIButton!
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.layer.cornerRadius = 30.0
            scanButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            scanButton.layer.shadowRadius = 5.0
            scanButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            scanButton.layer.shadowColor = UIColor.black.cgColor
            scanButton.layer.shadowOpacity = 0.08
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = {
            self.showFeatureRestrictionAlertIfNeeded()
        }()
    }
    
    // MARK: Actions
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.infoButton.alpha = fabs(self.infoButton.alpha - 1)
            self.warningLabel.alpha = fabs(self.warningLabel.alpha - 1)
        }
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        showSimulationSheet()
        #else
        initiateScan()
        #endif
    }
    
    func initiateScan() {
        if tangemSession != nil {
            tangemSession?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startSession()
            }
        } else {
            startSession()
        }
    }
    
    private func startSession() {
        tangemSession = TangemSession(delegate: self)
        tangemSession?.start()
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ReaderMoreViewController") as? ReaderMoreViewController else {
            return
        }
        
        viewController.contentText = "Tangem for iOS\nVersion \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)"
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    func launchSimulationParsingOperationWith(payload: Data) {
        tangemSession = TangemSession(payload: payload, delegate: self)
        tangemSession?.start()
    }
    
}

extension ReaderViewController : TangemSessionDelegate {

    func tangemSessionDidRead(card: Card) {
        guard card.isBlockchainKnown /*&& !card.isTestBlockchain*/ else {
            handleUnknownBlockchainCard()
            DispatchQueue.main.async {
                self.hintLabel.text = Constants.hintLabelDefaultText
            }
            return
        }
        
        switch card.genuinityState {
        case .pending:
            self.hintLabel.text = Constants.hintLabelScanningText
        case .nonGenuine:
            handleNonGenuineTangemCard(card) {
                UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
            }
        case .genuine:
            UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
        }
    }

    func tangemSessionDidFailWith(error: TangemSessionError) {
        switch error {
        case .locked:
            handleCardParserLockedCard()
        case .payloadError:
            handleCardParserWrongTLV()
        case .readerSessionError:
            handleReaderSessionError()
        }

        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }

}
