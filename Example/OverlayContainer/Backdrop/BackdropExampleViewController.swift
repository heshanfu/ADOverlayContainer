//
//  BackdropViewController.swift
//  OverlayContainer_Example
//
//  Created by Gaétan Zanella on 03/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import OverlayContainer
import UIKit

class BackdropViewController: UIViewController {
    override func loadView() {
        view = PassThroughView()
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
    }
}

class BackdropExampleViewController: UIViewController {

    enum OverlayNotch: Int, CaseIterable {
        case minimum, medium, maximum
    }

    private let backdropViewController = BackdropViewController()
    private let searchViewController = SearchViewController()
    private let mapsViewController = MapsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        let overlayController = OverlayContainerViewController()
        overlayController.delegate = self
        overlayController.viewControllers = [searchViewController]
        let stackController = StackViewController()
        stackController.viewControllers = [
            mapsViewController,
            backdropViewController,
            overlayController
        ]
        addChild(stackController, in: view)
    }

    private func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .maximum:
            return availableSpace * 3 / 4
        case .medium:
            return availableSpace / 2
        case .minimum:
            return availableSpace * 1 / 4
        }
    }

    private func alpha(forTranslation translation: CGFloat,
                          maximumHeight: CGFloat,
                          minimumHeight: CGFloat) -> CGFloat {
        return 1 - (maximumHeight - translation) / (maximumHeight - minimumHeight)
    }

    private func alpha(forTranslation translation: CGFloat,
                       coordinator: OverlayContainerTransitionCoordinator) -> CGFloat {
        return alpha(
            forTranslation: translation,
            maximumHeight: coordinator.height(forNotchAt: OverlayNotch.maximum.rawValue),
            minimumHeight: coordinator.height(forNotchAt: OverlayNotch.minimum.rawValue)
        )
    }
}

extension BackdropExampleViewController: OverlayContainerViewControllerDelegate {

    // MARK: - OverlayContainerViewControllerDelegate

    func numberOfNotches(in containerViewController: OverlayContainerViewController) -> Int {
        return OverlayNotch.allCases.count
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        heightForNotchAt index: Int,
                                        availableSpace: CGFloat) -> CGFloat {
        let notch = OverlayNotch.allCases[index]
        return notchHeight(for: notch, availableSpace: availableSpace)
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
        return (overlayViewController as? SearchViewController)?.tableView
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        shouldStartDraggingOverlay overlayViewController: UIViewController,
                                        at point: CGPoint,
                                        in coordinateSpace: UICoordinateSpace) -> Bool {
        guard let header = (overlayViewController as? SearchViewController)?.header else {
            return false
        }
        return header.bounds.contains(coordinateSpace.convert(point, to: header))
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        didDragOverlay overlayViewController: UIViewController,
                                        toHeight height: CGFloat,
                                        availableSpace: CGFloat) {
        backdropViewController.view.alpha = alpha(
            forTranslation: height,
            maximumHeight: notchHeight(for: .maximum, availableSpace: availableSpace),
            minimumHeight: notchHeight(for: .minimum, availableSpace: availableSpace)
        )
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        didEndDraggingOverlay overlayViewController: UIViewController,
                                        transitionCoordinator: OverlayContainerTransitionCoordinator) {
        backdropViewController.view.alpha = alpha(
            forTranslation: transitionCoordinator.overlayTranslationHeight,
            coordinator: transitionCoordinator
        )
        transitionCoordinator.animate(alongsideTransition: { context in
            self.backdropViewController.view.alpha = self.alpha(
                forTranslation: context.targetNotchHeight,
                coordinator: transitionCoordinator
            )
        }, completion: nil)
    }
}
