//
//  main.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

func doMain() throws {
  let keys = try Keyfile(filename: "/Users/gmadrid/.rtmcli")
  guard let apiKey = keys["apiKey"] else {
    print("Missing apiKey")
    return
  }
  guard let secret = keys["secret"] else {
    print("Missing secret")
    return
  }

  let rtmClient = RTMClient(key: apiKey, secret: secret)
  rtmClient.auth()
  
  print(rtmClient)
}

try! doMain()
