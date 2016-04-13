//
//  signertest.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class signertest: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testExample() {
    // This is a known value/signature from the RTM site:
    //     https://www.rememberthemilk.com/services/api/authentication.rtm
    let signature = Signer.sign(["yxz": "foo", "feg": "bar", "abc": "baz"], secret: "BANANAS")
    XCTAssert(signature == "82044aae4dd676094f23f1ec152159ba")
  }

}
