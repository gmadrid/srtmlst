//
//  signer.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class RTMParamSigner {
  let apiKey: String
  let secret: String

  init(apiKey: String, secret: String) {
    self.apiKey = apiKey
    self.secret = secret
  }

  func makeURL(method: RTMMethod) throws -> NSURL {
    var params : [String:String] = [
      "api_key": apiKey,
      "method": method.method,

      "format": "json"
    ]
    for pairs in method.params {
      params[pairs.0] = pairs.1
    }

    guard let components = NSURLComponents(string: method.baseUrlString) else {
      throw Error.NeedARealError
    }
    return try makeURLWithComponents(components, params: params)
  }

  func makeURLWithComponents(components: NSURLComponents, params: [String:String]) throws -> NSURL {
    components.query = signedQueryForParams(params)
    guard let url = components.URL else {
      throw Error.NeedARealError
    }

    return url
  }




  func unsignedQueryForParams(paramsIn: [String:String]) -> String {
    var params = paramsIn

    var result = [String]()
    for key in params.keys.sort() {
      result.append("\(key)=\(params[key]!)")
    }

    return result.joinWithSeparator("&")
  }

  func signedQueryForParams(paramsIn: [String:String]) -> String {
    var params = paramsIn
    let signature = sign(params)

    var result = [String]()
    for key in params.keys.sort() {
      result.append("\(key)=\(params[key]!)")
    }
    result.append("api_sig=\(signature)")

    return result.joinWithSeparator("&")
  }

  func sign(params: [String: String]) -> String {
    return signString(sortedStringForParams(params))
  }

  private func signString(string: String) -> String {
    return RTMParamSigner.md5(string: secret + string)
  }

  private func sortedStringForParams(params: [String:String]) -> String {
    var paramString = ""
    for key in params.keys.sort() {
      paramString += key + params[key]!
    }
    return paramString
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
