//
//  LeafByteUITests.swift
//  LeafByteUITests
//
//  Created by Abigail Getman-Pickering on 12/20/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import XCTest

// swiftlint:disable force_unwrapping
final class LeafByteUITests: XCTestCase {

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
        sleep(1)

        // Settings, tap None for both types of saving, tap Back
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.children(matching: .segmentedControl).element(boundBy: 0).buttons["None"].tap()
        elementsQuery.children(matching: .segmentedControl).element(boundBy: 1).buttons["None"].tap()
        app.navigationBars["Settings"].buttons["Save"].tap()
        sleep(1)

        // Main Menu, tap Tutorial
        app.buttons["Tutorial"].tap()
        sleep(1)

        // Tutorial, tap Next
        elementsQuery.buttons["Next"].tap()
        sleep(1)

        // Background Removal, dismiss popover and tap next
        let popoverdismissregionElement = app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        popoverdismissregionElement.tap()
        let nextButton = app.buttons["Next"]
        nextButton.tap()
        sleep(1)

        // Scale Identification, dismiss popover and tap next
        popoverdismissregionElement.tap()
        nextButton.tap()
        sleep(1)

        // Results, dismiss popover and check the results text (which must have near-specific values)
        popoverdismissregionElement.tap()
        let resultsText = app.staticTexts.element(matching: .any, identifier: "resultsValue").label

        let totalLeafArea = extractValue(source: resultsText, valueName: "Total Leaf Area")
        let consumedLeafArea = extractValue(source: resultsText, valueName: "Consumed Leaf Area")
        let percentConsumed = extractValue(source: resultsText, valueName: "Percent Consumed")

        // See PaperDataTests#tolerance for notes on the accuracy
        XCTAssertEqual(totalLeafArea, 9.039, accuracy: 0.001)
        XCTAssertEqual(consumedLeafArea, 0.112, accuracy: 0.001)
        XCTAssertEqual(percentConsumed, 1.245, accuracy: 0.001)
    }
}

func extractValue(source: String, valueName: String) -> Float {
    let match = source.range(of: "(?<=\(valueName)= )[^ %]+", options: .regularExpression)!
    let stringValue = source[match]
    return Float(stringValue)!
}
// swiftlint:enable force_unwrapping
