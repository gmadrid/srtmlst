//
//  rtm.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class RTMClient {
  let signer: RTMParamSigner
  let queue: NSOperationQueue
  let session: NSURLSession
  var token: String?

  init(key: String, secret: String, queue: NSOperationQueue? = nil, session: NSURLSession? = nil) {
    self.signer = RTMParamSigner(apiKey: key, secret: secret)
    self.queue = queue ?? NSOperationQueue()
    if session != nil {
      self.session = session!
    } else {
      let sess = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: nil, delegateQueue: self.queue)
      sess.sessionDescription = "RTMClient Session"
      self.session = sess
    }
  }

  func checkToken(token: String, cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.CheckToken(token: token), cb: cb) { rsp in
      let authDict: [String:AnyObject] = try RTMClient.getField(rsp, "auth")
      return try RTMClient.getField(authDict, "token")
    }
  }

  func getFrob(cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetFrob, cb: cb) { rsp in
      return try RTMClient.getField(rsp, "frob")
    }
  }

  func getToken(frob: String, cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetToken(frob: frob), cb: cb) { rsp in
      let authDict : [String:AnyObject] = try RTMClient.getField(rsp, "auth")
      return try RTMClient.getField(authDict, "token")
    }
  }

  private static func getField<T>(obj: [String:AnyObject], _ name: String) throws -> T {
    guard let result = obj[name] as? T else {
      throw AppError.MissingValue(name: name)
    }
    return result
  }

  private func processAPIMethod(method: RTMMethod, cb: (String?, ErrorType?) -> Void, processor: ([String:AnyObject]) throws -> String) {
    do {
      let url = try signer.makeURL(method)
      session.dataTaskWithURL(url) { data, _, error in
        guard error == nil else {
          cb(nil, error)
          return
        }

        guard let data = data else {
          cb(nil, AppError.MissingDataForMethod(methodName: method.method))
          return
        }

        do {
          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "Top-level object parse failed")
          }

          guard let rsp = json["rsp"] as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "Missing rsp")
          }

          guard let stat = rsp["stat"] as? String else {
            throw AppError.BadlyFormattedJSON(desc: "Missing stat")
          }

          guard stat == "ok" else {
            let msg: String = rsp["err"] as? String ?? "Missing \"err\" on error response"
            throw AppError.RTMError(err: msg)
          }

          let val = try processor(rsp)
          cb(val, nil)
        } catch {
          cb(nil, error)
        }
        }.resume()
    } catch {
      cb(nil, error)
    }
  }
}
