//
//  DesignMode.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/24/25.
//

import Foundation


struct DesignMode {
    static var isRunning: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
