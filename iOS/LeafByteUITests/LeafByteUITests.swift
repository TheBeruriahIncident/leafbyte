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
        // Main Menu, tap Settings
        let app = XCUIApplication()
        app.buttons["Settings"].tap()
        
        // Settings, tap None for both types of saving, tap Back
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.children(matching: .segmentedControl).element(boundBy: 0).buttons["None"].tap()
        elementsQuery.children(matching: .segmentedControl).element(boundBy: 1).buttons["None"].tap()
        app.navigationBars["Settings"].buttons["Back"].tap()
        
        // Main Menu, tap Tutorial
        app.buttons["Tutorial"].tap()
        
        // Tutorial, tap Next
        elementsQuery.buttons["Next"].tap()
        
        // Background Removal, dismiss popover and tap next
        let popoverdismissregionElement = app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        popoverdismissregionElement.tap()
        let nextButton = app.buttons["Next"]
        nextButton.tap()
        
        // Scale Identification, dismiss popover and tap next
        popoverdismissregionElement.tap()
        nextButton.tap()
        
        // Background Removal, dismiss popover and tap the results text (which must have specific values)
        popoverdismissregionElement.tap()
        app.staticTexts["Total Leaf Area= 10.011 cm2\nConsumed Leaf Area= 0.143 cm2\nPercent Consumed= 1.423%"].tap()
    }
}
