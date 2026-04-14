//
//  HapticManager.swift
//  timetracker
//
//  Created by Moritz Engelhardt on 06.02.25.
//

import UIKit

class HapticManager {
    static func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
