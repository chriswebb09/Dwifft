//
//  DwifftTests.swift
//  DwifftTests
//
//  Created by Jack Flintermann on 8/22/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import XCTest

class DwifftTests: XCTestCase {
    
    struct TestCase {
        let array1: [Character]
        let array2: [Character]
        let expectedLCS: [Character]
        let expectedDiff: String
        init(_ a: String, _ b: String, _ expected: String, _ expectedDiff: String) {
            self.array1 = Array(a.characters)
            self.array2 = Array(b.characters)
            self.expectedLCS = Array(expected.characters)
            self.expectedDiff = expectedDiff
        }
    }
    
    func testDiff() {
        let tests: [TestCase] = [
            TestCase("1234", "23", "23", "-4@3-1@0"),
            TestCase("0125890", "4598310", "590", "-8@4-2@2-1@1-0@0+4@0+8@3+3@4+1@5"),
            TestCase("BANANA", "KATANA", "AANA", "-N@2-B@0+K@0+T@2"),
            TestCase("1234", "1224533324", "1234", "+2@2+4@3+5@4+3@6+3@7+2@8"),
            TestCase("thisisatest", "testing123testing", "tsitest", "-a@6-s@5-i@2-h@1+e@1+t@3+n@5+g@6+1@7+2@8+3@9+i@14+n@15+g@16"),
            TestCase("HUMAN", "CHIMPANZEE", "HMAN", "-U@1+C@0+I@2+P@4+Z@7+E@8+E@9"),
        ]
        
        for test in tests {

            XCTAssertEqual(test.array1.LCS(test.array2), test.expectedLCS, "incorrect LCS")
            
            let diff = test.array1.diff(test.array2)
            let printableDiff = diff.results.map({ $0.debugDescription }).joined(separator: "")
            if printableDiff != test.expectedDiff {
                print("bad")
            }
            XCTAssertEqual(printableDiff, test.expectedDiff, "incorrect diff")

            let applied = test.array1.apply(diff)
            XCTAssertEqual(applied, test.array2)
            
            let reversed = diff.reversed()
            let reverseApplied = test.array2.apply(reversed)
            XCTAssertEqual(reverseApplied, test.array1)
        }
        
        
    }

    func test2D() {

        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[], []], rhs: []).results.debugDescription, "[ds(1), ds(0)]")
        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [], rhs: [[], []]).results.debugDescription, "[is(0), is(1)]")
        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [], rhs: []).results.debugDescription, "[]")

        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1], [], []], rhs: [[1]]).results.debugDescription, "[ds(2), ds(1)]")

        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[], [1], []], rhs: [[], [2], []]).results.debugDescription, "[d(1 0), i(1 0)]")

        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1], [], []], rhs: [[], [1], []]).results.debugDescription, "[ds(2), is(0)]")
        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1], [], []], rhs: [[], [1]]).results.debugDescription, "[ds(2), ds(1), is(0)]")
        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1], [], []], rhs: [[], [1, 2]]).results.debugDescription, "[ds(2), ds(1), is(0), i(1 1)]")
        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1]], rhs: [[], [1]]).results.debugDescription, "[is(0)]")

        XCTAssertEqual(ArrayDiff2D<Int>(lhs: [[1, 2, 3], [4, 5], []], rhs: [[], [1, 2], [3, 4]]).results.debugDescription, "[ds(2), d(1 1), d(0 2), is(0), i(2 0)]")

    }
    
    func testTableViewDiffCalculator() {
        
        class TestTableView: UITableView {
            
            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]
            
            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
                self.insertionExpectations = insertionExpectations
                self.deletionExpectations = deletionExpectations
                super.init(frame: CGRect.zero, style: UITableViewStyle.plain)
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.left, "incorrect insertion animation")
                for indexPath in indexPaths {
                    self.insertionExpectations[(indexPath as NSIndexPath).row]!.fulfill()
                }
            }
            
            override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
                XCTAssertEqual(animation, UITableViewRowAnimation.right, "incorrect insertion animation")
                for indexPath in indexPaths {
                    self.deletionExpectations[(indexPath as NSIndexPath).row]!.fulfill()
                }
            }
            
        }
        
        class TestViewController: UIViewController, UITableViewDataSource {
            
            let tableView: TestTableView
            let diffCalculator: TableViewDiffCalculator<Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rows = [rows]
                }
            }
            
            init(tableView: TestTableView, rows: [Int]) {
                self.tableView = tableView
                self.diffCalculator = TableViewDiffCalculator<Int>(tableView: tableView, initialRows: [rows])
                self.diffCalculator.insertionAnimation = .left
                self.diffCalculator.deletionAnimation = .right
                self.rows = rows
                super.init(nibName: nil, bundle: nil)
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                return UITableViewCell()
            }

            @objc func numberOfSections(in tableView: UITableView) -> Int {
                return self.diffCalculator.rows.count
            }
            
            @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return self.diffCalculator.rows[section].count
            }
            
        }
        
        var insertionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            insertionExpectations[i] = x
        }
        
        var deletionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            deletionExpectations[i] = x
        }
        
        let tableView = TestTableView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(tableView: tableView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCollectionViewDiffCalculator() {
        
        class TestCollectionView: UICollectionView {
            
            let insertionExpectations: [Int: XCTestExpectation]
            let deletionExpectations: [Int: XCTestExpectation]
            
            init(insertionExpectations: [Int: XCTestExpectation], deletionExpectations: [Int: XCTestExpectation]) {
                self.insertionExpectations = insertionExpectations
                self.deletionExpectations = deletionExpectations
                super.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }
            
            override func insertItems(at indexPaths: [IndexPath]) {
                super.insertItems(at: indexPaths)
                for indexPath in indexPaths {
                    self.insertionExpectations[(indexPath as NSIndexPath).item]!.fulfill()
                }
            }
            
            override func deleteItems(at indexPaths: [IndexPath]) {
                super.deleteItems(at: indexPaths)
                for indexPath in indexPaths {
                    self.deletionExpectations[(indexPath as NSIndexPath).item]!.fulfill()
                }
            }
            
        }
        
        class TestViewController: UIViewController, UICollectionViewDataSource {
            
            let testCollectionView: TestCollectionView
            let diffCalculator: CollectionViewDiffCalculator<Int>
            var rows: [Int] {
                didSet {
                    self.diffCalculator.rows = [rows]
                }
            }
            
            init(collectionView: TestCollectionView, rows: [Int]) {
                self.testCollectionView = collectionView
                self.diffCalculator = CollectionViewDiffCalculator<Int>(collectionView: self.testCollectionView, initialRows: [rows])
                self.rows = rows
                super.init(nibName: nil, bundle: nil)

                collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TestCell")
                collectionView.dataSource = self
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("not implemented")
            }

            @objc func numberOfSections(in collectionView: UICollectionView) -> Int {
                return diffCalculator.rows.count
            }
            
            @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return diffCalculator.rows[section].count
            }
            
            @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath)
            }
            
        }
        
        var insertionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 3, 4, 5] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            insertionExpectations[i] = x
        }
        
        var deletionExpectations: [Int: XCTestExpectation] = [:]
        for i in [0, 1, 2, 4] {
            let x: XCTestExpectation = expectation(description: "+\(i)")
            deletionExpectations[i] = x
        }
        
        let collectionView = TestCollectionView(insertionExpectations: insertionExpectations, deletionExpectations: deletionExpectations)
        let viewController = TestViewController(collectionView: collectionView, rows: [0, 1, 2, 5, 8, 9, 0])
        viewController.rows = [4, 5, 9, 8, 3, 1, 0]
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
}
