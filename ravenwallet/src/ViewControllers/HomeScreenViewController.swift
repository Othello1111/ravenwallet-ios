//
//  HomeScreenViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-27.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

class HomeScreenViewController : UIViewController, Subscriber {
    
    var walletManager: WalletManager? {
        didSet {
            setInitialData()
            setupSubscriptions()
            currencyList.reload()
            if(!UserDefaults.hasDismissedPrompt){
                attemptShowPrompt()
            }
        }
    }
    private let currencyList = AssetListTableView()
    private let subHeaderView = UIView()
    private var logo: UIImageView = {
        let image = UIImageView(image: #imageLiteral(resourceName: "newLogo"))
        image.contentMode = .scaleAspectFit
        return image
    }()
    private let total = UILabel(font: .customBold(size: 30.0), color: .darkGray)
    private let totalHeader = UILabel(font: .customMedium(size: 18.0), color: .mediumGray)
    private let prompt = UIView()
    private var promptHiddenConstraint: NSLayoutConstraint!
    
    var didSelectCurrency : ((CurrencyDef) -> Void)?
    var didSelectAsset : ((Asset) -> Void)?
    var didSelectShowMoreAsset: (() -> Void)?
    var didTapSecurity: (() -> Void)?
    var didTapSupport: (() -> Void)?
    var didTapSettings: (() -> Void)?
    var didTapAddressBook: ((CurrencyDef) -> Void)?
    var didTapCreateAsset: (() -> Void)?
    var didTapTutorial: (() -> Void)?
    
    // MARK: -
    
    init(walletManager: WalletManager?) {
        self.walletManager = walletManager
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        currencyList.didSelectCurrency = didSelectCurrency
        currencyList.didSelectAsset = didSelectAsset //BMEX
        currencyList.didSelectShowMoreAsset = didSelectShowMoreAsset
        currencyList.didTapSecurity = didTapSecurity
        currencyList.didTapSupport = didTapSupport
        currencyList.didTapSettings = didTapSettings
        currencyList.didTapAddressBook = didTapAddressBook
        currencyList.didTapCreateAsset = didTapCreateAsset
        currencyList.didTapTutorial = didTapTutorial
        
        addSubviews()
        addConstraints()
        addActions()
        setInitialData()
        setupSubscriptions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) { [weak self] in
            if(!UserDefaults.hasDismissedPrompt){
                self?.attemptShowPrompt()
            }
        }
    }
    
    // MARK: Setup
    
    private func addSubviews() {
        view.addSubview(subHeaderView)
        subHeaderView.addSubview(logo)
        subHeaderView.addSubview(totalHeader)
        subHeaderView.addSubview(total)
        view.addSubview(prompt)
    }
    
    private func addConstraints() {
        let height: CGFloat = 60.0//Height with total label = 136.0
        if #available(iOS 11.0, *) {
            subHeaderView.constrain([
                subHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                subHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
                subHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                subHeaderView.heightAnchor.constraint(equalToConstant: height) ])
        } else {
            subHeaderView.constrain([
                subHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                subHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
                subHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                subHeaderView.heightAnchor.constraint(equalToConstant: height) ])
        }
        
        let yConstraint = NSLayoutConstraint(item: logo, attribute: .centerY, relatedBy: .equal, toItem: subHeaderView, attribute: .centerY, multiplier: 0.5, constant: 0.0)
        logo.constrain([
            logo.constraint(.centerX, toView: subHeaderView, constant: nil),
            logo.trailingAnchor.constraint(equalTo: subHeaderView.trailingAnchor, constant: -C.padding[2]),
            logo.leadingAnchor.constraint(equalTo: subHeaderView.leadingAnchor, constant: C.padding[2]),
            yConstraint])
        if E.isIPad {
            logo.addConstraint(logo.widthAnchor.constraint(equalTo: logo.heightAnchor, multiplier: 10.15))
        }
        
        totalHeader.constrain([
            totalHeader.trailingAnchor.constraint(equalTo: total.trailingAnchor),
            totalHeader.bottomAnchor.constraint(equalTo: total.topAnchor, constant: 0.0),
            totalHeader.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: C.padding[2]),
            totalHeader.heightAnchor.constraint(equalToConstant: 0)//BMEX to show totalHeader just remove this line
            ])
        total.constrain([
            total.trailingAnchor.constraint(equalTo: subHeaderView.trailingAnchor, constant: -C.padding[2]),
            total.topAnchor.constraint(equalTo: totalHeader.bottomAnchor),
            total.heightAnchor.constraint(equalToConstant: 0)//BMEX to show total just remove this line
            ])
        
        promptHiddenConstraint = prompt.heightAnchor.constraint(equalToConstant: 0.0)
        prompt.constrain([
            prompt.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            prompt.topAnchor.constraint(equalTo: subHeaderView.bottomAnchor),
            promptHiddenConstraint
            ])
        
        addChild(currencyList, layout: {
            currencyList.view.constrain([
                currencyList.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                currencyList.view.topAnchor.constraint(equalTo: prompt.bottomAnchor),
                currencyList.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                currencyList.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        })
    }
    
    private func addActions() {
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        logo.addGestureRecognizer(gr)
        logo.isUserInteractionEnabled = true
    }
    
    private func setInitialData() {
        view.backgroundColor = .whiteBackground
        subHeaderView.backgroundColor = .whiteBackground
        subHeaderView.clipsToBounds = false
        logo.contentMode = .scaleToFill
        
        navigationItem.titleView = UIView()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = #imageLiteral(resourceName: "TransparentPixel")
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "TransparentPixel"), for: .default)
        
        totalHeader.text = S.HomeScreen.totalAssets
        totalHeader.textAlignment = .left
        total.textAlignment = .left
        total.text = "0"
        title = ""
        
        updateTotalAssets()
        //Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshPeerManagerConnect), userInfo: nil, repeats: true)
    }
    
    @objc func refreshPeerManagerConnect() {
        if walletManager!.peerManager?.connectionStatus != BRPeerStatusConnected {
            DispatchQueue.walletQueue.async { [weak self] in
                self?.walletManager!.peerManager?.disconnect()
                self?.walletManager!.peerManager?.connect()
            }
        }
    }
    
    @objc private func longPressed(sender:UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            Store.trigger(name: .playGif("logoGif"))
        }
    }
    
    private func updateTotalAssets() {
        let fiatTotal = Store.state.currencies.map {
            let balance = Store.state[$0].balance ?? 0
            let rate = Store.state[$0].currentRate?.rate ?? 0
            return Double(balance)/$0.baseUnit * rate * 0.001
            }.reduce(0.0, +)
        let format = NumberFormatter()
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = format.positiveFormat.replacingCharacters(in: format.positiveFormat.range(of: "#")!, with: "-#")
        format.currencySymbol = Store.state[Currencies.rvn].currentRate?.currencySymbol ?? ""
        self.total.text = format.string(from: NSNumber(value: fiatTotal))
    }
    
    private func setupSubscriptions() {
        Store.unsubscribe(self)
        
        Store.subscribe(self, selector: {
            var result = false
            let oldState = $0
            let newState = $1
            $0.currencies.forEach { currency in
                if oldState[currency].balance != newState[currency].balance {
                    result = true
                }
                
                if oldState[currency].currentRate?.rate != newState[currency].currentRate?.rate {
                    result = true
                }
            }
            return result
        },
                        callback: { _ in
                            self.updateTotalAssets()
        })
        
        // prompts
        Store.subscribe(self, name: .didUpgradePin, callback: { _ in
            if self.currentPrompt?.type == .upgradePin {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .didEnableShareData, callback: { _ in
            if self.currentPrompt?.type == .shareData {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .didWriteRecoveryPhrase, callback: { _ in
            if self.currentPrompt?.type == .recoveryPhrase {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .didRescanBlockChain, callback: { _ in
            if self.currentPrompt?.type == .rescanBlockChain {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .playGif(""), callback: {  [weak self] in
            guard let trigger = $0 else { return }
            if case .playGif(let gifName) = trigger {
                let logoGif = UIImage.gifImageWithName(name: gifName)
                let imageView = UIImageView(image: logoGif)
                imageView.backgroundColor = UIColor.black
                imageView.frame = CGRect(x: 0, y: 0, width: self!.view.frame.size.width, height: self!.view.frame.size.height)
                imageView.contentMode = UIView.ContentMode.scaleAspectFit
                imageView.alpha = 0.0
                self!.view.addSubview(imageView)
                imageView.fadeIn(0.5, delay: 0.0, completion: { _ in
                    imageView.fadeOut(0.5, delay: 6.1, completion: { _ in
                        imageView.removeFromSuperview()
                    })
                })
            }
        })
    }
    
    // MARK: - Prompt
    
    private let promptDelay: TimeInterval = 0.6
    
    private var currentPrompt: Prompt? {
        didSet {
            if currentPrompt != oldValue {
                var afterFadeOut: TimeInterval = 0.0
                if let oldPrompt = oldValue {
                    afterFadeOut = 0.15
                    UIView.animate(withDuration: 0.2, animations: {
                        oldValue?.alpha = 0.0
                    }, completion: { _ in
                        oldPrompt.removeFromSuperview()
                    })
                }
                
                if let newPrompt = currentPrompt {
                    newPrompt.alpha = 0.0
                    prompt.addSubview(newPrompt)
                    newPrompt.constrain(toSuperviewEdges: .zero)
                    prompt.layoutIfNeeded()
                    promptHiddenConstraint.isActive = false
                    
                    // fade-in after fade-out and layout
                    UIView.animate(withDuration: 0.2, delay: afterFadeOut + 0.15, options: .curveEaseInOut, animations: {
                        newPrompt.alpha = 1.0
                    })
                } else {
                    promptHiddenConstraint.isActive = true
                }
                
                // layout after fade-out
                UIView.animate(withDuration: 0.2, delay: afterFadeOut, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    private func attemptShowPrompt() {
        guard let walletManager = walletManager else {
            currentPrompt = nil
            return
        }
        if let type = PromptType.nextPrompt(walletManager: walletManager) {
            currentPrompt = Prompt(type: type)
            currentPrompt!.dismissButton.tap = { [unowned self] in
                self.currentPrompt = nil
                UserDefaults.hasDismissedPrompt = true
            }
            currentPrompt!.continueButton.tap = { [unowned self] in
                if let trigger = type.trigger(currency: Currencies.rvn) {
                    Store.trigger(name: trigger)
                }
                self.currentPrompt = nil
            }
            if type == .biometrics {
                UserDefaults.hasPromptedBiometrics = true
            }
            if type == .shareData {
                UserDefaults.hasPromptedShareData = true
            }
        } else {
            currentPrompt = nil
        }
    }
    
    // MARK: -
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

