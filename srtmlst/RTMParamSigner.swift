//
//  signer.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class Signer {
  class func sign(params: [String: String], secret: String) -> String {
    var paramString = ""
    for key in params.keys.sort() {
      paramString += key + params[key]!
    }

    let stringToSign = secret + paramString
    return md5(string: stringToSign)
  }

  private class func md5(string string: String) -> String {
    var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
    if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
      CC_MD5(data.bytes, CC_LONG(data.length), &digest)
    }

    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
      digestHex += String(format: "%02x", digest[index])
    }

    return digestHex
  }
}