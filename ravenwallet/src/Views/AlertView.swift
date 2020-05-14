//
//  AlertView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-22.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

enum AlertType {
    case pinSet(callback: () -> Void)
    case addressAdded(callback: (() -> Void)?)
    case addressUpdated
    case addressDeleted
    case recoveryPhraseSet(callback: () -> Void)
    case sendSuccess
    case sendAssetSuccess
    case reissueAssetSuccess
    case burnAssetSuccess
    case createSuccess(txHash:String)
    case addressesCopied
    case sweepSuccess(callback: () -> Void)
    case none
    

    var header: String {
        switch self {
        case .pinSet:
            return S.Alerts.pinSet
        case .addressAdded:
            return S.Alerts.addressAdded
        case .addressUpdated:
            return S.Alerts.addressUpdated
        case .addressDeleted:
            return S.Alerts.addressDeleted
        case .recoveryPhraseSet:
            return S.Alerts.recoveryPhraseSet
        case .sendSuccess:
            return S.Alerts.sendSuccess
        case .sendAssetSuccess:
            return S.Alerts.sendAssetSuccess
        case .burnAssetSuccess:
            return S.Alerts.burnAssetSuccess
        case .createSuccess:
            return S.Alerts.createSuccess
        case .reissueAssetSuccess:
            return S.Alerts.reissueAssetSuccess
        case .addressesCopied:
            return S.Alerts.copiedAddressesHeader
        case .sweepSuccess:
            return S.Import.success
        case .none:
            return "none"
        }
    }

    var subheader: String {//BMEX
        switch self {
        case .pinSet:
            return ""
        case .addressAdded:
            return ""
        case .addressUpdated:
            return ""
        case .addressDeleted:
            return ""
        case .recoveryPhraseSet:
            return S.Alerts.recoveryPhraseSetSubheader
        case .sendSuccess:
            return S.Alerts.sendSuccessSubheader
        case .sendAssetSuccess:
            return S.Alerts.sendAssetSuccessSubheader
        case .burnAssetSuccess:
            return S.Alerts.burnAssetSuccessSubheader
        case .createSuccess(let txHash):
            return S.Alerts.createSuccessSubheader + txHash
        case .reissueAssetSuccess:
            return S.Alerts.reissueAssetSuccessSubheader
        case .addressesCopied:
            return S.Alerts.copiedAddressesSubheader
        case .sweepSuccess:
            return S.Import.successBody
        case .none:
            return "none"
        }
    }

    var icon: UIView {
        return CheckView()
    }
}

extension AlertType : Equatable {}

func ==(lhs: AlertType, rhs: AlertType) -> Bool {
    switch (lhs, rhs) {
    case (.pinSet(_), .pinSet(_)):
        return true
    case (.addressAdded(_), .addressAdded(_)):
        return true
    case (.addressUpdated, .addressUpdated):
        return true
    case (.addressDeleted, .addressDeleted):
        return true
    case (.recoveryPhraseSet(_), .recoveryPhraseSet(_)):
        return true
    case (.sendSuccess, .sendSuccess):
        return true
    case (.sendAssetSuccess, .sendAssetSuccess):
        return true
    case (.burnAssetSuccess, .burnAssetSuccess):
        return true
    case (.reissueAssetSuccess, .reissueAssetSuccess):
        return true
    case (.createSuccess, .createSuccess):
        return true
    case (.addressesCopied, .addressesCopied):
        return true
    case (.sweepSuccess(_), .sweepSuccess(_)):
        return true
    case (.none, .none):
        return true
    default:
        return false
    }
}

class AlertView : UIView, GradientDrawable {

    private let type: AlertType
    private let header = UILabel()
    private let subheader = UILabel()
    private let separator = UIView()
    private let icon: UIView
    private let iconSize: CGFloat = 96.0
    private let separatorYOffset: CGFloat = 48.0

    init(type: AlertType) {
        self.type = type
        self.icon = type.icon

        super.init(frame: .zero)
        layer.cornerRadius = 6.0
        layer.masksToBounds = true
        setupSubviews()
    }

    func animate() {
        guard let animatableIcon = icon as? AnimatableIcon else { return }
        animatableIcon.animate()
    }

    private func setupSubviews() {
        addSubview(header)
        addSubview(subheader)
        addSubview(icon)
        addSubview(separator)

        setData()
        addConstraints()
    }

    private func setData() {
        header.text = type.header
        header.textAlignment = .center
        header.font = UIFont.customBold(size: 14.0)
        header.textColor = .white

        icon.backgroundColor = .clear
        separator.backgroundColor = .transparentWhite

        subheader.text = type.subheader
        subheader.textAlignment = .center
        subheader.font = UIFont.customBody(size: 14.0)
        subheader.textColor = .white
    }

    private func addConstraints() {

        //NB - In this alert view, constraints shouldn't be pinned to the bottom
        //of the view because the bottom actually extends off the bottom of the screen a bit.
        //It extends so that it still covers up the underlying view when it bounces on screen.

        header.constrainTopCorners(sidePadding: C.padding[2], topPadding: C.padding[2])
        separator.constrain([
            separator.constraint(.height, constant: 1.0),
            separator.constraint(.width, toView: self, constant: 0.0),
            separator.constraint(.top, toView: self, constant: separatorYOffset),
            separator.constraint(.leading, toView: self, constant: nil) ])
        icon.constrain([
            icon.constraint(.centerX, toView: self, constant: nil),
            icon.constraint(.centerY, toView: self, constant: nil),
            icon.constraint(.width, constant: iconSize),
            icon.constraint(.height, constant: iconSize) ])
        subheader.constrain([
            subheader.constraint(.leading, toView: self, constant: C.padding[2]),
            subheader.constraint(.trailing, toView: self, constant: -C.padding[2]),
            subheader.constraint(toBottom: icon, constant: C.padding[3]) ])
    }

    override func draw(_ rect: CGRect) {
        drawGradient(rect)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
