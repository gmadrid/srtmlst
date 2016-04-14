//
//  main.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

func doMain() throws {
  let config = try! LoadSimplePropertiesFromPath("/Users/gmadrid/.rtmcli")
  guard let apiKey = config["apiKey"] else {
    print("Missing apiKey")
    return
  }
  guard let secret = config["secret"] else {
    print("Missing secret")
    return
  }

  let rtmClient = RTMClient(key: apiKey, secret: secret)
  if let token = config["token"] {
    rtmClient.token = token
  } else {
    rtmClient.acquireToken() { token, error in
      print("GOT A TOKEN: \(token)")
      print("OR ERROR: \(error)")
    }
  }

  dispatch_main()
}

try! doMain()
