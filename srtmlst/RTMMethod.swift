//
//  RTMMethod.swift
//  srtmlst
//
//  Created by George Madrid on 4/13/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

protocol RTMMethod {
  var method: String { get }
  var baseUrlString: String { get }
}

extension RTMMethod {
  var baseUrlString: String { return "https://api.rememberthemilk.com/services/rest/" }
}

class RTMGetFrobMethod : RTMMethod {
  var method: String = "rtm.auth.getFrob"
}
