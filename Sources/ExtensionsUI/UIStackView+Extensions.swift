//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public extension UIStackView {
    var view: UIView { self }
}

public extension UIStackView {
    static func defaultVerticalStackView(
        _ defaultMargin: CGFloat = 16,
        _ spacing: CGFloat = 5
    ) -> UIStackView {
        let layoutMargins = UIEdgeInsets(
            top: 0,
            left: defaultMargin,
            bottom: 0,
            right: defaultMargin
        )

        let v = UIStackView()
        v.isLayoutMarginsRelativeArrangement = true
        v.axis = .vertical
        v.distribution = .fill
        v.spacing = spacing
        v.alignment = .fill
        v.autoresizesSubviews = false
        v.layoutMargins = layoutMargins
        v.clipsToBounds = false
        return v
    }

    static func defaultHorizontalStackView(
        _ defaultMargin: CGFloat = 16,
        _ spacing: CGFloat = 5
    ) -> UIStackView {
        let layoutMargins = UIEdgeInsets(
            top: 0,
            left: defaultMargin,
            bottom: 0,
            right: defaultMargin
        )

        let h = UIStackView()
        h.isLayoutMarginsRelativeArrangement = true
        h.axis = .horizontal
        h.spacing = spacing
        h.distribution = .equalCentering
        h.alignment = .center
        h.autoresizesSubviews = false
        h.layoutMargins = layoutMargins
        h.clipsToBounds = false
        return h
    }
}

public extension UIStackView {
    func addSeparator(
        color: UIColor = .darkGray,
        size: CGFloat = 3,
        stackViewInvisibleSeparatorLineTag: Int = 5000,
        stackViewVisibleSeparatorLineTag: Int = 50001
    ) {
        let separator = UIView()
        separator.backgroundColor = color
        separator.tag = (color == .clear)
            ? stackViewInvisibleSeparatorLineTag
            : stackViewVisibleSeparatorLineTag

        addArrangedSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: size).isActive = true
    }

    func edgeStackViewToSuperView(insets: UIEdgeInsets = .zero) {
        guard let superview else { return }
        layouts.edgesToSuperview(insets: insets)
        layouts.width(to: superview)
    }

    // MARK: - Centering helpers

    func addHorizontallyCentered(any: Any, margin: CGFloat) {
        if let view = any as? UIView {
            let h = UIStackView.defaultHorizontalStackView(0, 0)
            let left = UIView()
            let right = UIView()

            h.addArrangedSubview(left)
            h.addArrangedSubview(view)
            h.addArrangedSubview(right)

            left.backgroundColor = .clear
            right.backgroundColor = .clear

            if margin > 0 {
                h.alignment = .trailing
                h.distribution = .fill
                left.layouts.width(margin)
                right.layouts.width(margin)
            }

            addArrangedSubview(h)
            return
        }

        if let swiftUIView = any as? AnyView {
            addHorizontallyCentered(any: swiftUIView, margin: margin)
        }
    }

    func addHorizontallyCentered(any: Any, size: CGSize) {
        if let view = any as? UIView {
            let container = UIView()
            container.addSubview(view)
            view.layouts.centerToSuperview()
            view.layouts.size(size)
            container.layouts.height(size.height)

            addArrangedSubview(container)
            return
        }

        if let swiftUIView = any as? AnyView {
            addHorizontallyCentered(any: swiftUIView, size: size)
        }
    }

    // MARK: - Add arranged subviews

    func addArranged(any: Any, id: String? = nil) {
        if let v = any as? UIView {
            addArranged(any: v, id: id)
            return
        }

        if let v = any as? AnyView {
            addArranged(view: v, id: id)
            return
        }

        Common_Logs.error("Not predicted for [\(any)]", "\(Self.self)")
    }

    func addArranged(view: some View, id: String? = nil) {
        guard let uiView = view.asViewController.view else { return }
        addArranged(uiView: uiView, id: id)
    }

    func addArranged(uiView: UIView?, id: String? = nil) {
        guard let uiView else { return }

        if let id {
            uiView.accessibilityIdentifier = id

            if uiView.superview == nil {
                addArrangedSubview(uiView)
            } else if let existing = arrangedSubviews.first(where: { $0.accessibilityIdentifier == id }),
                      let position = arrangedSubviews.firstIndex(of: existing)
            {
                removeArrangedSubview(existing)
                insertArrangedSubview(uiView, at: position)
            }
        } else {
            if uiView.superview == nil {
                addArrangedSubview(uiView)
            }
        }

        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }

    // MARK: - Index helpers

    func arrangedSubview(at index: Int) -> UIView? {
        guard index >= 0, index < arrangedSubviews.count else { return nil }
        return arrangedSubviews[index]
    }

    func indexOfArrangedSubview(_ view: UIView) -> Int? {
        arrangedSubviews.firstIndex(of: view)
    }

    // MARK: - Insert API

    func insertArrangedSubview(_ view: UIView, atIndex: Int) {
        insertArrangedSubview(view, at: atIndex)
        setNeedsLayout()
        layoutIfNeeded()
    }

    func insertArrangedSubview(_ view: UIView, belowArrangedSubview subview: UIView) {
        guard let idx = indexOfArrangedSubview(subview) else { return }
        insertArrangedSubview(view, at: idx + 1)
        setNeedsLayout()
        layoutIfNeeded()
    }

    func insertArrangedSubview(_ view: UIView, aboveArrangedSubview subview: UIView) {
        guard let idx = indexOfArrangedSubview(subview) else { return }
        insertArrangedSubview(view, at: idx)
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Removal

    func removeArrangedSubview(at index: Int) {
        guard index >= 0, index < arrangedSubviews.count else { return }
        let v = arrangedSubviews[index]
        removeArrangedSubview(v)
        v.removeFromSuperview()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func removeAllArrangedSubviews(after index: Int) {
        guard index >= 0, index < arrangedSubviews.count else { return }

        let toRemove = arrangedSubviews.suffix(from: index + 1)
        for v in toRemove {
            NSLayoutConstraint.deactivate(v.constraints)
            removeArrangedSubview(v)
            v.removeFromSuperview()
        }
    }

    func removeAllArrangedSubviews() {
        let all = arrangedSubviews
        for v in all {
            removeArrangedSubview(v)
            NSLayoutConstraint.deactivate(v.constraints)
            v.removeFromSuperview()
        }
    }
}
