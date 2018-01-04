//
//  LeafByteUITests.swift
//  LeafByteUITests
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import XCTest

class LeafByteUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    func testNavigatingToSettings() {
        let app = XCUIApplication()
        app.buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Back"].tap()
        app.buttons["Photo Library"].tap()
        
        // I don't know how to make the UIAutomation proceed through the ImagePicker, so the test stops here.
    }
}
