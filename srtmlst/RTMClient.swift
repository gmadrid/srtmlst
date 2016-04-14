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

  func acquireToken(cb: (String?, ErrorType?) -> Void) {
    let signer = self.signer  // capture locally
    let apiKey = signer.apiKey  // capture locally

    getFrob { frob, error in
      guard error == nil else {
        cb(nil, error)
        return
      }

      guard let frob = frob else {
        cb(nil, RTMClient.makeError("missing err and frob"))
        return
      }

      // The auth request is special, so we'll make it manually for now.
      let site = "https://www.rememberthemilk.com/services/auth/"
      let params = [
        "api_key": apiKey,
        "perms": "delete",
        "frob": frob
      ]
      let query = signer.signedQueryForParams(params)

      guard let components = NSURLComponents(string: site) else {
        cb(nil, Error.NeedARealError)
        return
      }
      components.query = query

      guard let url = components.URL else {
        cb(nil, Error.NeedARealError)
        return
      }
      
      print(url)
    }
  }

  class func makeError(msg: String) -> ErrorType {
    return NSError(domain: "srtmlst", code: 2, userInfo: [ NSLocalizedDescriptionKey: msg ])
  }

  class func makeRTMError(msg: AnyObject?) -> ErrorType {
    return NSError(domain: "srtmlst rtm rtm", code: 2, userInfo: [ NSLocalizedDescriptionKey: msg ?? "MISSING MESSAGE" ])
  }

  func getFrob(cb: (String?, ErrorType?) -> Void) {
    do {
      let url = try signer.makeURL(RTMGetFrobMethod())

      session.dataTaskWithURL(url) { data, _, error in
        guard error == nil else {
          cb(nil, RTMClient.makeError("Error in response: \(error!)"))
          return
        }
        guard let data = data else {
          cb(nil, RTMClient.makeError("data and error both nil in response"))
          return
        }

        do {
          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject] else {
            cb(nil, RTMClient.makeError("JSON response badly formatted."))
            return
          }

          guard let stat = json["rsp"]?["stat"] as? String else {
            cb(nil, RTMClient.makeError("Missing 'stat' field"))
            return
          }

          guard stat == "ok" else {
            cb(nil, RTMClient.makeRTMError(json["rsp"]?["err"]))
            return
          }

          guard let frob = json["rsp"]?["frob"] as? String else {
            cb(nil, RTMClient.makeError("Missing 'frob' field"))
            return
          }

          cb(frob, nil)
        } catch {
          cb(nil, error)
        }
        }.resume()
    } catch {
      cb(nil, error)
    }
  }





  func auth() {
    getFrob { frob, error in
    }
  }

  func paramsForMethod(method: String) -> [String:String] {
    return ["method": method, "format": "json"]
  }

}
