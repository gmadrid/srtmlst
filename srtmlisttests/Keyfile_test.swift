//
//  Keyfile_test.swift
//  srtmlst
//
//  Created by George Madrid on 4/13/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import XCTest

func XCTAssertEqualDictionaries<S, T: Equatable>(first: [S:T], _ second: [S:T]) {
  XCTAssert(first == second)
}


class Keyfile_test: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testNamePassedToRead() {
    try! LoadSimplePropeesFromPath("thename") { fn in
      XCTAssertEqual("thename", fn)
      return NSData()
    }
  }

  func testNamePassedToWrite() {
    try! WriteSimplePropertiesToPath("thewritename", props: [:]) { fn, _ in
      XCTAssertEqual("thewritename", fn)
    }
  }

  func testEmptyRead() {
    let props = try! LoadSimplePropertiesFromPath("foobar") { fn in
      return "".dataUsingEncoding(NSUTF8StringEncoding)!
    }

    XCTAssertEqual(0, props.count)
  }

  func testEmptyWrite() {
    try! WriteSimplePropertiesToPath("foobar", props: [:], writeFunc: { (fn, data) in
      XCTAssertEqual(0, data.length)
    })
  }

  func testReadProps() {
    let dict = try! LoadSimplePropertiesFromPath("") { _ in
      return (
        "foo=bar\n"
          + "quux=foo\n"
          + "bam=bam\n"
        ).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    XCTAssertEqual(3, dict.count)
    XCTAssertEqual("bar", dict["foo"])
    XCTAssertEqual("foo", dict["quux"])
    XCTAssertEqual("bam", dict["bam"])
  }

  func testReadPropsNoTerminatingNewline() {
    let dict = try! LoadSimplePropertiesFromPath("") { _ in
      return (
        "foo=bar\n"
          + "quux=foo\n"
          + "bam=bam"
        ).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    XCTAssertEqual(3, dict.count)
    XCTAssertEqual("bar", dict["foo"])
    XCTAssertEqual("foo", dict["quux"])
    XCTAssertEqual("bam", dict["bam"])
  }

  func testReadWithBadEncoding() {
    XCTAssertThrowsError(try LoadSimplePropertiesFromPath("") { _ in
      // Grab some bytes that will not encode as valid UTF-8.
      let testBytes : [UInt8] = [ 0x9a, 0xaa, 0xba, 0xca ]
      return NSData(bytes: testBytes, length: testBytes.count)
    }, "Bad Encoding") { err in
      if case Error.CouldNotEncodeContents = err {
        return
      }
      XCTFail("Expected CoundNotEncode exception")
    }
  }

  func testReadPropsWithSpaces() {
    let dict = try! LoadSimplePropertiesFromPath("") { _ in
      return (
        " foo  =   bar    \n"
          + "\tquux =\t  foo \n"
          + " bam = bam \n"
        ).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    XCTAssertEqual(3, dict.count)
    XCTAssertEqual("bar", dict["foo"])
    XCTAssertEqual("foo", dict["quux"])
    XCTAssertEqual("bam", dict["bam"])
  }

  func testReadMissing() {
    XCTAssertThrowsError(try LoadSimplePropertiesFromPath("") { fn in
      throw Error.CouldNotReadFile(filename: fn)
    })
  }

  func testReadBadFormat() {
    XCTAssertThrowsError(try LoadSimplePropertiesFromPath("") { _ in
      return "foo:bar".dataUsingEncoding(NSUTF8StringEncoding)!
    })
  }

  func testWriteProps() {
    let props = [ "foo": "bar", "quux": "quu", "bam": "bamf"]
    try! WriteSimplePropertiesToPath("", props: props) { _, data in
      guard let strRep = String(data: data, encoding: NSUTF8StringEncoding) else {
        XCTFail("Couldn't decode the data.")
        return
      }
      let desiredString = "bam = bamf\nfoo = bar\nquux = quu\n"
      XCTAssertEqual(desiredString, strRep)
    }
  }
}
