//
//  UIKitSwiftUIBridgeTests.swift
//  Common
//
//  Created by Ricardo Santos on 15/11/2025.
//

@testable import Common
import SwiftUI
import Testing
import UIKit

@Suite(.serialized)
struct UIKitSwiftUIBridgeTests {
    // Simple SwiftUI view for testing
    struct TestView: View {
        var body: some View { Text("Hello") }
    }

    // MARK: - asViewController

    @Test
    @MainActor
    func testAsViewController() {
        let vc = TestView().asViewController

        #expect(vc is UIViewController)
        #expect(vc.view != nil)

        // Layout should not crash
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
    }

    // MARK: - uiView

    @Test
    @MainActor
    func testUIViewConversion() {
        let view = TestView().uiView

        #expect(view is UIView)
        #expect(view.subviews.isEmpty) // hosting is inside controller, not here

        // Background gets cleared by our extension
        #expect(view.backgroundColor == .clear)
    }

    // MARK: - UIView embedSwiftUIView

    @Test
    @MainActor
    func testEmbedSwiftUIView() {
        let container = UIView()
        let view = TestView()

        container.embedSwiftUIView(view)

        #expect(container.subviews.count == 1)
        let hosted = container.subviews.first!

        // Should be pinned to edges
        #expect(hosted.translatesAutoresizingMaskIntoConstraints == false)
        #expect(container.constraints.count >= 4)
    }

    // MARK: - setNeedsUpdateSize

    @Test
    @MainActor
    func testSetNeedsUpdateSize() {
        let view = UIView()
        let superview = UIView()
        superview.addSubview(view)

        // Should not crash
        view.setNeedsUpdateSize(animated: false)

        // No visible assertion — test is mainly “doesn’t crash”
        #expect(true)
    }

    // MARK: - addChildSwiftUIView into container

    @Test
    @MainActor
    func testAddChildSwiftUIViewIntoContainer() {
        let vc = UIViewController()
        let container = UIView()
        vc.view.addSubview(container)

        let swiftUIView = TestView()

        vc.addChildSwiftUIView(swiftUIView, into: container)

        #expect(vc.children.count == 1)
        #expect(container.subviews.count == 1)

        let hostedView = container.subviews.first!
        #expect(hostedView.translatesAutoresizingMaskIntoConstraints == false)
    }

    // MARK: - addChildSwiftUIView into VC root view

    @Test
    @MainActor
    func testAddChildSwiftUIViewToRootView() {
        let vc = UIViewController()
        _ = vc.view // force load

        let swiftUIView = TestView()
        vc.addChildSwiftUIView(swiftUIView)

        #expect(vc.children.count == 1)
        #expect(vc.view.subviews.count == 1)
    }

    // MARK: - presentSwiftUIView

    @Test
    @MainActor
    func testPresentSwiftUIView() {
        // We cannot actually present modally in a test runner,
        // but we can verify that our override is triggered.

        let view = TestView()

        // Intercept UIKit's presentation call
        var didCallPresentation = false

        class TestVC: UIViewController {
            var onPresent: (() -> Void)?
            override func present(_: UIViewController,
                                  animated _: Bool,
                                  completion: (() -> Void)? = nil)
            {
                onPresent?()
                completion?()
            }
        }

        let mockVC = TestVC()
        mockVC.onPresent = { didCallPresentation = true }

        // Act
        mockVC.presentSwiftUIView(view)

        // Assert
        #expect(didCallPresentation == true)
    }
}
