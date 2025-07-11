//
//  ExtendedPowerManager.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/11/25.
//
import AppKit
import IOKit.pwr_mgt
import Foundation
class ExtendedPowerManager {
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private var isDisplayAssertionActive = false
    private var isSystemAssertionActive = false
    
    func preventAllSleep() {
        preventDisplaySleep()
        preventSystemSleep()
    }
    
    func preventDisplaySleep() {
        guard !isDisplayAssertionActive else { return }
        
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "MyApp - Prevent Display Sleep" as CFString,
            &displayAssertionID
        )
        
        isDisplayAssertionActive = (result == kIOReturnSuccess)
    }
    
    func preventSystemSleep() {
        guard !isSystemAssertionActive else { return }
        
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "MyApp - Prevent System Sleep" as CFString,
            &systemAssertionID
        )
        
        isSystemAssertionActive = (result == kIOReturnSuccess)
    }
    
    func allowAllSleep() {
        if isDisplayAssertionActive {
            IOPMAssertionRelease(displayAssertionID)
            isDisplayAssertionActive = false
        }
        
        if isSystemAssertionActive {
            IOPMAssertionRelease(systemAssertionID)
            isSystemAssertionActive = false
        }
    }
    
    deinit {
        allowAllSleep()
    }
}
