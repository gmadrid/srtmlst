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
      guard let tokenResult = rsp["token"] as? String else {
        throw AppError.MissingValue(name: "token")
      }
      print("tokenResult: \(tokenResult)")
      return tokenResult
    }
  }

  func getFrob(cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetFrob, cb: cb) { rsp in
      guard let frob = rsp["frob"] as? String else {
        throw AppError.MissingValue(name: "frob")
      }
      return frob
    }
  }

  func getToken(frob: String, cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetToken(frob: frob), cb: cb) { rsp in
      guard let authDict = rsp["auth"] as? [String:AnyObject] else {
        throw AppError.MissingValue(name: "auth")
      }
      guard let token = authDict["token"] as? String else {
        throw AppError.MissingValue(name: "token")
      }
      print("tokenResult: \(token)")
      return token
    }
  }

  func processAPIMethod(method: RTMMethod, cb: (String?, ErrorType?) -> Void, processor: ([String:AnyObject]) throws -> String) {
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

          //          print(json)
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
  
//  func acquireToken(cb: (String?, ErrorType?) -> Void) {
//    let signer = self.signer  // capture locally
//    let apiKey = signer.apiKey  // capture locally
//
//    getFrob { frob, error in
//      guard error == nil else {
//        cb(nil, error)
//        return
//      }
//
//      guard let frob = frob else {
//        cb(nil, RTMClient.makeError("missing err and frob"))
//        return
//      }
//
//      // The auth request is special, so we'll make it manually for now.
//      let site = "https://www.rememberthemilk.com/services/auth/"
//      let params = [
//        "api_key": apiKey,
//        "perms": "delete",
//        "frob": frob
//      ]
//      let query = signer.signedQueryForParams(params)
//
//      guard let components = NSURLComponents(string: site) else {
//        cb(nil, Error.NeedARealError)
//        return
//      }
//      components.query = query
//
//      guard let url = components.URL else {
//        cb(nil, Error.NeedARealError)
//        return
//      }
//      
//      print(url)
//    }
//  }
//
//  class func makeError(msg: String) -> ErrorType {
//    return NSError(domain: "srtmlst", code: 2, userInfo: [ NSLocalizedDescriptionKey: msg ])
//  }
//
//  class func makeRTMError(msg: AnyObject?) -> ErrorType {
//    return NSError(domain: "srtmlst rtm rtm", code: 2, userInfo: [ NSLocalizedDescriptionKey: msg ?? "MISSING MESSAGE" ])
//  }
//
//  func checkToken(token: String, cb: (Bool, ErrorType?) -> Void) {
//    do {
//      let url = try signer.makeURL(.CheckToken(token: token))
//
//      session.dataTaskWithURL(url) { data, _, error in
//        debugPrint(data)
//        print(error)
//
//        guard error == nil else {
//          cb(false, RTMClient.makeError("Error in check token: \(error)"))
//          return
//        }
//
//        guard let data = data else {
//          cb(false, RTMClient.makeError("data and error both nil in response"))
//          return
//        }
//
//        do {
//          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] else {
//            cb(false, RTMClient.makeError("JSON response badly formatted."))
//            return
//          }
//
//          print(json)
//          cb(false, nil)
//        } catch {
//          print(error)
//          cb(false, nil)
//        }
//
//
//      }.resume()
//    } catch {
//      print(error)
//    }
//
//  }
//
//  func getFrob(cb: (String?, ErrorType?) -> Void) {
//    do {
//      let url = try signer.makeURL(.GetFrob)
//
//      session.dataTaskWithURL(url) { data, _, error in
//        guard error == nil else {
//          cb(nil, RTMClient.makeError("Error in response: \(error!)"))
//          return
//        }
//        guard let data = data else {
//          cb(nil, RTMClient.makeError("data and error both nil in response"))
//          return
//        }
//
//        do {
//          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] else {
//            cb(nil, RTMClient.makeError("JSON response badly formatted."))
//            return
//          }
//
//          guard let stat = json["rsp"]?["stat"] as? String else {
//            cb(nil, RTMClient.makeError("Missing 'stat' field"))
//            return
//          }
//
//          guard stat == "ok" else {
//            cb(nil, RTMClient.makeRTMError(json["rsp"]?["err"]))
//            return
//          }
//
//          guard let frob = json["rsp"]?["frob"] as? String else {
//            cb(nil, RTMClient.makeError("Missing 'frob' field"))
//            return
//          }
//
//          cb(frob, nil)
//        } catch {
//          cb(nil, error)
//        }
//        }.resume()
//    } catch {
//      cb(nil, error)
//    }
//  }
//
//
//
//
//
//  func auth() {
//    getFrob { frob, error in
//    }
//  }
//
//  func paramsForMethod(method: String) -> [String:String] {
//    return ["method": method, "format": "json"]
//  }
//
}
