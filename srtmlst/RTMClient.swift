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

  class RTMList {
    let id: String
    let name: String

    init(dict: [String:AnyObject]) throws {
      id = try RTMClient.getField(dict, "id")
      name = try RTMClient.getField(dict, "name")
    }
  }

  func getLists(cb: (String?, ErrorType?) -> Void) {
    print("XXXXXXXXXXXXX")
    processAPIMethod(.GetLists(token: token!), cb: cb) { rsp in
      let listsDict : [String:AnyObject] = try RTMClient.getField(rsp, "lists")
      let listList : [AnyObject] = try RTMClient.getField(listsDict, "list")

      var result = [RTMList]()
      for listDict in listList {
        do {
          guard let typedList = listDict as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "List item of wrong type")
          }
          result.append(try RTMList(dict: typedList))
        } catch {
          cb(nil, error)
        }
      }
      print("NUM ITEMS: \(result.count)")
      return "NUM ITEMS: \(result.count)"
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
        do {
          guard error == nil else {
            throw error!
          }

          guard let data = data else {
            throw AppError.MissingDataForMethod(methodName: method.method)
          }

          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "Top-level object parse failed")
          }

          let rsp : [String:AnyObject] = try RTMClient.getField(json, "rsp")
          let stat : String = try RTMClient.getField(rsp, "stat")

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
