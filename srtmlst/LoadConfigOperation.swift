//
//  LoadConfigOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class LoadConfigOperation : Operation, ResultProvider {
  private(set) var providedResult: [String:String]?

  let configFilePath: String

  init(configFileName: String) {
    if !(configFileName as NSString).absolutePath {
      configFilePath = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(configFileName)
    } else {
      configFilePath = configFileName
    }
  }

  deinit {
    print("KILLED LCO")
  }

  override func execute() {
    do {
      providedResult = try LoadSimplePropertiesFromPath(configFilePath)
      finish()
    } catch {
      finishWithError(error.nserror)
    }
  }
}
