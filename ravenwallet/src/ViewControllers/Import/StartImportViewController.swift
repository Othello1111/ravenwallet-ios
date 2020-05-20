//
//  StartImportViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-06-13.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import Core

class StartImportViewController : UIViewController, Subscriber {
    
    init(walletManager: WalletManager) {
        self.walletManager = walletManager
        self.currency = walletManager.currency
        assert(walletManager.currency is Raven, "Importing only supports Ravencoin")
        super.init(nibName: nil, bundle: nil)
    }
    
    private let walletManager: WalletManager
    private let currency: CurrencyDef
    private let header = BlueGradiantCenterHeader()
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "ImportIllustration"))
    private let message = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let warning = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let assetWarning = UILabel.wrapping(font: .customBody(size: 16.0), color: .sentRed)
    private let buttonScan = ShadowButton(title: S.Import.scan, type: .primary)
    private let buttonSeed = ShadowButton(title: S.Import.enterSeed, type: .primary)
    private let bulletWarning = UIImageView(image: #imageLiteral(resourceName: "deletecircle"))
    private let bulletAssetWarning = UIImageView(image: #imageLiteral(resourceName: "deletecircle"))
    private let leftCaption = UILabel.wrapping(font: .customMedium(size: 13.0), color: .white)
    private let rightCaption = UILabel.wrapping(font: .customMedium(size: 13.0), color: .white)
    private let balanceActivity = BRActivityViewController(message: S.Import.checking)
    private let importingActivity = BRActivityViewController(message: S.Import.importing)
    private let unlockingActivity = BRActivityViewController(message: S.Import.unlockingActivity)
    private var utxos:[[String: Any]] = []
    private var countSFail:Int = 0
    private var chain:Int32 = SEQUENCE_EXTERNAL_CHAIN
    private var walletBalance:UInt64 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        addConstraints()
        addSubscriptions()
        setInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if walletManager.peerManager?.connectionStatus == BRPeerStatusDisconnected {
            DispatchQueue.walletQueue.async { [weak self] in
                self?.walletManager.peerManager?.connect()
            }
        }
    }
    
    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(illustration)
        header.addSubview(leftCaption)
        header.addSubview(rightCaption)
        view.addSubview(message)
        view.addSubview(buttonScan)
        view.addSubview(buttonSeed)
        view.addSubview(bulletWarning)
        view.addSubview(bulletAssetWarning)
        view.addSubview(warning)
        view.addSubview(assetWarning)
    }
    
    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0, topPadding: 0)
        header.constrain([
            header.constraint(.height, constant: E.isIPhoneXOrLater ? 250.0 : 220.0) ])
        illustration.constrain([
            illustration.constraint(.width, constant: 64.0),
            illustration.constraint(.height, constant: 84.0),
            illustration.constraint(.centerX, toView: header, constant: 0.0),
            illustration.constraint(.centerY, toView: header, constant: E.isIPhoneXOrLater ? 4.0 : -C.padding[1]) ])
        leftCaption.constrain([
            leftCaption.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: C.padding[1]),
            leftCaption.trailingAnchor.constraint(equalTo: header.centerXAnchor, constant: -C.padding[2]),
            leftCaption.widthAnchor.constraint(equalToConstant: 80.0)])
        rightCaption.constrain([
            rightCaption.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: C.padding[1]),
            rightCaption.leadingAnchor.constraint(equalTo: header.centerXAnchor, constant: C.padding[2]),
            rightCaption.widthAnchor.constraint(equalToConstant: 80.0)])
        message.constrain([
            message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            message.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]),
            message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
        bulletWarning.constrain([
            bulletWarning.leadingAnchor.constraint(equalTo: message.leadingAnchor),
            bulletWarning.topAnchor.constraint(equalTo: message.bottomAnchor, constant: C.padding[4]),
            bulletWarning.widthAnchor.constraint(equalToConstant: 16.0),
            bulletWarning.heightAnchor.constraint(equalToConstant: 16.0) ])
        warning.constrain([
            warning.leadingAnchor.constraint(equalTo: bulletWarning.trailingAnchor, constant: C.padding[2]),
            warning.topAnchor.constraint(equalTo: bulletWarning.topAnchor, constant: 0.0),
            warning.trailingAnchor.constraint(equalTo: message.trailingAnchor) ])
        bulletAssetWarning.constrain([
            bulletAssetWarning.leadingAnchor.constraint(equalTo: message.leadingAnchor),
            bulletAssetWarning.topAnchor.constraint(equalTo: warning.bottomAnchor, constant: C.padding[2]),
            bulletAssetWarning.widthAnchor.constraint(equalToConstant: 16.0),
            bulletAssetWarning.heightAnchor.constraint(equalToConstant: 16.0) ])
        assetWarning.constrain([
            assetWarning.leadingAnchor.constraint(equalTo: warning.leadingAnchor),
            assetWarning.topAnchor.constraint(equalTo: warning.bottomAnchor, constant: C.padding[2]),
            assetWarning.trailingAnchor.constraint(equalTo: warning.trailingAnchor) ])
        buttonScan.constrain([
            buttonScan.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[3]),
            buttonScan.bottomAnchor.constraint(equalTo: buttonSeed.topAnchor, constant: -C.padding[2]),
            buttonScan.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[3]),
            buttonScan.constraint(.height, constant: C.Sizes.buttonHeight) ])
        buttonSeed.constrain([
            buttonSeed.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[3]),
            buttonSeed.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -C.padding[4]),
            buttonSeed.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[3]),
            buttonSeed.constraint(.height, constant: C.Sizes.buttonHeight) ])
        
    }
    
    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0[self.currency].balance != $1[self.currency].balance },
                        callback: { [unowned self] in
                            if let balance = $0[self.currency].balance {
                                self.walletBalance = balance
                            }
        })
    }
    
    private func setInitialData() {
        view.backgroundColor = .white
        illustration.contentMode = .scaleAspectFill
        message.text = S.Import.importMessage
        leftCaption.text = S.Import.leftCaption
        leftCaption.textAlignment = .center
        rightCaption.text = S.Import.rightCaption
        rightCaption.textAlignment = .center
        warning.text = S.Import.importWarning
        assetWarning.text = S.Import.importAssettWarning
        
        buttonScan.tap = strongify(self) { myself in
            let scan = ScanViewController(scanKeyCompletion: { address in
                myself.didReceiveAddress(address)
            }, isValidURI: { (string) -> Bool in
                return string.isValidPrivateKey || string.isValidBip38Key
            })
            myself.parent?.present(scan, animated: true, completion: nil)
        }
        
        buttonSeed.tap = strongify(self) { myself in
            let recoverWalletViewController = EnterPhraseViewController(walletManager: myself.walletManager, reason: .importUtxoFromServer({ phrase in
                myself.present(myself.balanceActivity, animated: true, completion: {
                    self.utxos.removeAll()
                    self.chain = SEQUENCE_EXTERNAL_CHAIN
                    self.recursiveFetchUTXOS(index: 0, phrase: phrase, completion: { prevKey in
                        myself.handleData(data: myself.utxos, key: prevKey, isAsset: false)
                    })
                })
            }))
            myself.navigationController?.pushViewController(recoverWalletViewController, animated: true)
        }
    }
    
    private func didReceiveAddress(_ address: String) {
        if address.isValidPrivateKey {
            if let key = BRKey(privKey: address) {
                checkBalance(key: key)
            }
        } else if address.isValidBip38Key {
            unlock(address: address, callback: { key in
                self.checkBalance(key: key)
            })
        }
    }
    
    private func unlock(address: String, callback: @escaping (BRKey) -> Void) {
        let alert = UIAlertController(title: S.Import.title, message: S.Import.password, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = S.Import.passwordPlaceholder
            textField.isSecureTextEntry = true
            textField.returnKeyType = .done
        })
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: { _ in
            self.present(self.unlockingActivity, animated: true, completion: {
                if let password = alert.textFields?.first?.text {
                    if let key = BRKey(bip38Key: address, passphrase: password) {
                        self.unlockingActivity.dismiss(animated: true, completion: {
                            callback(key)
                        })
                        return
                    }
                }
                self.unlockingActivity.dismiss(animated: true, completion: {
                    self.showErrorMessage(S.Import.wrongPassword)
                })
            })
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func recursiveFetchUTXOS(index:Int, phrase:String, completion: @escaping (BRKey)->Void) {
        var privKey = self.walletManager.generatePrevKey(phrase, index: index, chain: chain)
        if countSFail > 20 {
            countSFail = 0
            completion(privKey!)
            return
        }
        let address = privKey?.address()
        self.walletManager.apiClient?.isAddressUsed(address: address!, completion: { isUsed in
            if(isUsed){
                self.countSFail = 0
                self.walletManager.apiClient?.fetchUTXOS(address: address!, isAsset: false, completion:{ data in
                    self.utxos.append(contentsOf: data!)
                    self.chain = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? SEQUENCE_INTERNAL_CHAIN : SEQUENCE_EXTERNAL_CHAIN
                    let nextIndex = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? (index+1) : index
                    self.recursiveFetchUTXOS(index: nextIndex, phrase: phrase, completion: completion)
                })
            }
            else{
                self.countSFail = self.countSFail + 1
                self.chain = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? SEQUENCE_INTERNAL_CHAIN : SEQUENCE_EXTERNAL_CHAIN
                let nextIndex = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? (index+1) : index
                self.recursiveFetchUTXOS(index: nextIndex, phrase: phrase, completion: completion)
            }
        })
        //Todo : for Asset, should update asset api to add this
        //        self.walletManager.apiClient?.fetchUTXOS(address: address!, isAsset: false, completion:{ data in
        //            self.addUtxos(data: data, isAsset: false)
        //            print("BMEX index RVN ", index, ", chain : ", self.chain, ", address :", address!, " data : ", data?.count)
        ////            self.walletManager.apiClient?.fetchUTXOS(address: address!, isAsset: true, completion: { data in
        ////                self.addUtxos(data: data, isAsset: true)
        ////                print("BMEX index Asset ", index, ", chain : ", self.chain, ", address :", address!, " data : ", data?.count)
        ////                self.chain = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? SEQUENCE_INTERNAL_CHAIN : SEQUENCE_EXTERNAL_CHAIN
        ////                let nextIndex = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? (index+1) : index
        ////                self.recursiveFetchUTXOS(index: nextIndex, phrase: phrase, completion: completion)
        ////            })
        //            self.chain = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? SEQUENCE_INTERNAL_CHAIN : SEQUENCE_EXTERNAL_CHAIN
        //            let nextIndex = (self.chain == SEQUENCE_EXTERNAL_CHAIN) ? (index+1) : index
        //            self.recursiveFetchUTXOS(index: nextIndex, phrase: phrase, completion: completion)
        //        })
    }
    
    private func addUtxos(data:[[String: Any]]?, isAsset:Bool){
        if(data?.count != 0){
            self.countSFail = 0
            if(!isAsset){
                self.utxos.append(contentsOf: data!)
            }
        }else {
            self.countSFail = self.countSFail + 1
        }
    }
    
    private func checkBalance(key: BRKey) {
        var key = key
        guard let address = key.address() else { return }
        self.fetchUTXOS(address: address, isAsset: false, key: key, callBack: {
            self.fetchUTXOS(address: address, isAsset: true, key: key)
        })
    }
    
    func fetchUTXOS(address: String, isAsset:Bool, key: BRKey, callBack:(()->Void)? = nil) {
        present(balanceActivity, animated: true, completion: {
            self.walletManager.apiClient?.fetchUTXOS(address: address, isAsset: isAsset, completion: { data in
                guard let data = data else { return }
                self.handleData(data: data, key: key, isAsset: isAsset, callBack: callBack)
            })
        })
    }
    
    private func handleData(data: [[String: Any]], key: BRKey, isAsset:Bool, callBack:(()->Void)? = nil) {
        var key = key
        guard let tx = UnsafeMutablePointer<BRTransaction>() else { return }
        guard let wallet = walletManager.wallet else { return }
        guard let address = key.address() else { return }
        guard let fees = Currencies.rvn.state.fees else { return }
        guard !wallet.containsAddress(address) else {
            return showErrorMessage(S.Import.Error.duplicate)
        }
        let outputs = data.compactMap { SimpleUTXO(json: $0) }
        let balance = outputs.map { $0.satoshis }.reduce(0, +)
        outputs.forEach { output in
            tx.addInput(txHash: output.hash, index: output.index, amount: output.satoshis, script: output.script)
        }
        
        let pubKeyLength = key.pubKey()?.count ?? 0
        walletManager.wallet?.feePerKb = fees.regular
        let fee = wallet.feeForTxSize(tx.size + 34 + (pubKeyLength - 34)*tx.inputs.count)
        balanceActivity.dismiss(animated: true, completion: {
            guard outputs.count > 0 && balance > 0 else {
                if isAsset {
                    return self.showErrorMessage(S.Import.Error.emptyasset, callBack: callBack)
                }
                else {
                    return self.showErrorMessage(S.Import.Error.empty, callBack: callBack)
                }
            }
            if isAsset {
                guard fee + wallet.minOutputAmount <= self.walletBalance else {
                    return self.showErrorMessage(S.Send.nilFeeError)
                }
            }
            else {
                guard fee + wallet.minOutputAmount <= balance else {
                    return self.showErrorMessage(S.Import.Error.highFees)
                }
            }
            guard let rate = Currencies.rvn.state.currentRate else { return }
            let feeAmount = Amount(amount: fee, rate: rate, maxDigits: Currencies.rvn.state.maxDigits, currency: Currencies.rvn)
            let balanceText = self.getBalanceMessage(outputs: outputs, isAsset: isAsset, rate: rate)
            let feeText = Store.state.isSwapped ? feeAmount.localCurrency : feeAmount.bits
            let message = String(format: S.Import.confirm, balanceText, feeText)
            let alert = UIAlertController(title: S.Import.title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: {_ in
                callBack?()
            }))
            alert.addAction(UIAlertAction(title: S.Import.importButton, style: .default, handler: { _ in
                self.publish(tx: tx, balance: balance, fee: fee, key: key, isAsset: isAsset, outputs: outputs, callBack:callBack)
            }))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func getBalanceMessage(outputs:[SimpleUTXO], isAsset:Bool, rate:Rate) -> String {
        if isAsset {
            var balanceMessage = ""
            var index = 0
            outputs.forEach { output in
                let plus:String = (index > 0) ? " + " : ""
                balanceMessage = balanceMessage + plus
                balanceMessage = balanceMessage + String(output.satoshis) + " " + output.assetName!
                index = index + 1
            }
            return balanceMessage
        }
        else {
            let balance = outputs.map { $0.satoshis }.reduce(0, +)
            let balanceAmount = Amount(amount: balance, rate: rate, maxDigits: Currencies.rvn.state.maxDigits, currency: Currencies.rvn)
            let balanceText = Store.state.isSwapped ? balanceAmount.localCurrency : balanceAmount.bits
            return balanceText
        }
    }
    
    private func publish(tx: UnsafeMutablePointer<BRTransaction>, balance: UInt64, fee: UInt64, key: BRKey, isAsset:Bool, outputs:[SimpleUTXO], callBack:(()->Void)? = nil) {
        guard let wallet = walletManager.wallet else { return }
        guard var script = BRAddress(string: wallet.receiveAddress)?.scriptPubKey else { return }
        guard walletManager.peerManager?.connectionStatus != BRPeerStatusDisconnected else { return }
        present(importingActivity, animated: true, completion: {
            if isAsset {
                outputs.forEach { output in
                    let newScript = tx.addAssetOutput(amount: output.satoshis, assetName: output.assetName!, script: script)
                    script = newScript
                    tx.addOutput(amount:0, script: script)
                    wallet.addFeeToTx(tx)
                    self.walletManager.signTx(tx)
                }
            }
            else{
                tx.addOutput(amount: balance - fee, script: script)
            }
            var keys = [key]
            let _ = tx.sign(keys: &keys)
            guard tx.isSigned else {
                self.importingActivity.dismiss(animated: true, completion: {
                    self.showErrorMessage(S.Import.Error.signing)
                })
                return
            }
            self.walletManager.peerManager?.publishTx(tx, completion: { [weak self] success, error in
                guard let myself = self else { return }
                DispatchQueue.main.async {
                    myself.importingActivity.dismiss(animated: true, completion: {
                        DispatchQueue.main.async {
                            if let error = error {
                                myself.showErrorMessage(error.localizedDescription)
                                return
                            }
                            myself.showSuccess(callBack: callBack)
                        }
                    })
                }
            })
        })
        
    }
    
    private func showSuccess(callBack:(()->Void)? = nil) {
        Store.perform(action: Alert.Show(.sweepSuccess(callback: { [weak self] in
            guard let myself = self else { return }
            guard let callBack = callBack else {
                myself.dismiss(animated: true, completion: nil)
                return
            }
            callBack()
        })))
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Data {
    var reverse: Data {
        let tempBytes = Array(([UInt8](self)).reversed())
        return Data(bytes: tempBytes)
    }
}
