//
//  RTMMethod.swift
//  srtmlst
//
//  Created by George Madrid on 4/13/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

enum RTMMethod {
  case CheckToken(token: String)
  case GetFrob
  case GetToken(frob: String)

  var baseUrlString: String {
    return "https://api.rememberthemilk.com/services/rest/"
  }

  var method: String {
    switch self  {
    case .CheckToken: return "rtm.auth.checkToken"
    case .GetFrob: return "rtm.auth.getFrob"
    case .GetToken: return "rtm.auth.getToken"
    }
  }

  var params: [String:String] {
    switch self {
    case .CheckToken(let token): return [ "auth_token" : token]
    case .GetToken(let frob): return [ "frob" : frob ]
    default: return [:]
    }
  }
}
