//
//  Utils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/23/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
import Foundation

func roundToInt(_ number: Double, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return Int(number.rounded(rule))
}

func roundToInt(_ number: Float, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return roundToInt(Double(number), rule: rule)
}

func roundToInt(_ number: CGFloat, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return roundToInt(Float(number), rule: rule)
}

// Adapted from https://stackoverflow.com/questions/40915607/how-can-i-decode-jwt-json-web-token-token-in-swift
func extractPayload(fromJwt jwt: String) -> [String: Any]? {
    let segments = jwt.components(separatedBy: ".")
    guard segments.count == 3 else {
        print("Invalid JWT does not have 3 parts: \(jwt)")
        return nil
    }
    let payloadSegment = segments[1]

    return decodeJWTPayload(payloadSegment)
}

private func decodeJWTPayload(_ rawPayload: String) -> [String: Any]? {
  guard
    let unparsedPayload = decodeBase64Url(rawPayload),
    let jsonPayload = try? JSONSerialization.jsonObject(with: unparsedPayload, options: []),
    let payload = jsonPayload as? [String: Any] else {
      print("Could not decode JWT payload: \(rawPayload)")
      return nil
  }

  return payload
}

// Note that base64url is different from base64, which is why some characters are replaced, and padding is added
private func decodeBase64Url(_ base64UrlValue: String) -> Data? {
    let unpaddedBase64Value = base64UrlValue
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    let length = Double(unpaddedBase64Value.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length

    let base64Value: String
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64Value = unpaddedBase64Value + padding
    } else {
        base64Value = unpaddedBase64Value
    }

    return Data(base64Encoded: base64Value, options: .ignoreUnknownCharacters)
}
