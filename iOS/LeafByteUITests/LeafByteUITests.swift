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
    
    func testBasicFlow() {
        // Main Menu
        let app = XCUIApplication()
        app.buttons["Settings"].tap()
        
        // Settings
        let scrollViewsQuery = app.scrollViews
        scrollViewsQuery.children(matching: .segmentedControl).element(boundBy: 0).buttons["Files App"].tap()
        scrollViewsQuery.children(matching: .segmentedControl).element(boundBy: 1).buttons["Files App"].tap()
        app.navigationBars["Settings"].buttons["Back"].tap()
        
        // Main Menu
        app.buttons["Tutorial"].tap()
        
        // Tutorial
        let nextButton = app.buttons["Next"]
        nextButton.tap()
        
        // Background Removal
        let popoverdismissregionElement = app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        popoverdismissregionElement.tap()
        nextButton.tap()
        
        // Scale Identification
        popoverdismissregionElement.tap()
        nextButton.tap()
        
        // Results
        popoverdismissregionElement.tap()
        XCTAssert(app.staticTexts["Total Leaf Area= 521.427 cm2\nConsumed Leaf Area= 14.364 cm2 \nPercent Consumed= 2.755%"].exists)
    }
}
