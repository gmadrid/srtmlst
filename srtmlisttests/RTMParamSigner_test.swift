//
//  signertest.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

class RTMParamSigner_test: XCTestCase {

  // This is a known value/signature from the RTM site:
  //     https://www.rememberthemilk.com/services/api/authentication.rtm
  let knownParams = ["yxz": "foo", "feg": "bar", "abc": "baz"]
  let knownSecret = "BANANAS"
  let knownSig = "82044aae4dd676094f23f1ec152159ba"

  // This sig is not from the web site, it is the sig with the api_key param added.
  let knownSigWithApiKey = "d5a52545eca5f0f4c9720387df5705dc"

  var signer: RTMParamSigner!

  override func setUp() {
    super.setUp()
    signer = RTMParamSigner(apiKey: "KEY", secret: knownSecret)
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testQueryString() {
    let queryString = signer.signedQueryForParams(knownParams)
    XCTAssertEqual("abc=baz&api_key=KEY&feg=bar&yxz=foo&api_sig=\(knownSigWithApiKey)", queryString)
  }

  func testKnownSig() {
    let signature = signer.sign(knownParams)
    XCTAssert(signature == knownSig)
  }

}
