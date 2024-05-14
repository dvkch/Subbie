//
//  SubbieTests.swift
//  SubbieTests
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import XCTest
import Difference
@testable import Subbie

class SubbieTests: XCTestCase {

    var subtitles: [URL] {
        let testBundle = Bundle(for: type(of: self))
        let baseFolder = testBundle.url(forResource: "Subtitles", withExtension: nil)!
        return try! FileManager.default.contentsOfDirectory(atPath: baseFolder.path).map { baseFolder.appendingPathComponent($0) }
    }
    
    private func normalizeData(_ data: Data) -> Data {
        return String(data: data, encoding: .utf8)!
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .newlines)
            .data(using: .utf8)!
    }
    
    func testParserWriterNilpotency() throws {
        for subtitle in subtitles {
            let originalData = try Data(contentsOf: subtitle)
            let parsedSubtitle = try SubRipParser.parse(data: originalData)
            let writtenData = try SubRipParser.write(lines: parsedSubtitle)
            
            let linesDiff = diff(
                String(data: normalizeData(originalData), encoding: .utf8)!.split(separator: "\n"),
                String(data: normalizeData(writtenData), encoding: .utf8)!.split(separator: "\n")
            )
            XCTAssertTrue(
                normalizeData(originalData) == normalizeData(writtenData),
                "Found difference for \n" + linesDiff.joined(separator: ", ")
            )
        }
    }
}
