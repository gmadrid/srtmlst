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
  case GetLists(token: String)
  case GetList(token: String, listId: String?)
  case GetToken(frob: String)

  var baseUrlString: String {
    return "https://api.rememberthemilk.com/services/rest/"
  }

  var method: String {
    switch self  {
    case .CheckToken: return "rtm.auth.checkToken"
    case .GetFrob: return "rtm.auth.getFrob"
    case .GetList: return "rtm.tasks.getList"
    case .GetLists: return "rtm.lists.getList"
    case .GetToken: return "rtm.auth.getToken"
    }
  }

  var params: [String:String] {
    switch self {
    case .CheckToken(let token): return [ "auth_token" : token]
    case .GetToken(let frob): return [ "frob" : frob ]

    case .GetList(let token, let listId):
      var params = [ "auth_token": token ]
      if let listId = listId {
        params["list_id"] = listId
      }
      return params
//      return [ "auth_token": token, "list_id": listId ]

    case .GetLists(let token): return [ "auth_token" : token ]
    default: return [:]
    }
  }
}
