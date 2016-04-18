//
//  AuthOperationGroup.swift
//  srtmlst
//
//  Created by George Madrid on 4/17/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/**
 * The AuthOperationGroup coordinates a series of operations that as a group have:
 *
 *    input: the config dict
 *   output: a fully authenticated RTMClient
 *
 * The constituent operations are:
 *   1) CreateClientOp: given a config, build an RTMClient. If the token is present, go to 2.
 *      If not, go to 3.
 *   2) VerifyTokenOp: round-trip to RTM to verify that the token is still valid. If it is not, 
 *      go to 3. If so, then the group operation is done, so provide output.
 *   3) AcquireTokenOp: round-trip to RTM and user interaction with the browser to obtain a
 *      new, valid token. Once acquired, we are done, so provide output.
 */
class AuthOperationGroup : GroupOperation, ResultConsumer, ResultProvider {
  var consumedResult: [String:String]?
  var providedResult: RTMClient?

  init() {
    super.init(operations: [])
  }

  override func execute() {
    guard let config = consumedResult else {
      finishWithError(AppError.MissingResult(className: self.className).nserror)
      return
    }

    guard let apiKey = config["apiKey"] else {
      finishWithError(AppError.MissingValue(name: "apiKey").nserror)
      return
    }

    guard let secret = config["secret"] else {
      finishWithError(AppError.MissingValue(name: "secret").nserror)
      return
    }

    let client = RTMClient(key: apiKey, secret: secret)
    let verifyOp: VerifyTokenOperation?
    if let token = config["token"] {
      client.token = token
      verifyOp = VerifyTokenOperation(client: client)
      addOperation(verifyOp!)
    } else {
      verifyOp = nil
    }

    let acquireOp = AcquireTokenOperation(client: client)
    if let verifyOp = verifyOp {
      acquireOp.addDependency(verifyOp)
    }
    addOperation(acquireOp)

    providedResult = client

    super.execute()
  }
}

class VerifyTokenOperation : Operation {
  let client: RTMClient

  init(client: RTMClient) {
    self.client = client
  }

  override func execute() {
    guard let token = client.token else {
      finishWithError(AppError.MissingToken.nserror)
      return
    }
    client.checkToken(token) { [weak self] result, error in
      // TODO: error checking
      self?.finish()
    }
  }
}

class AcquireTokenOperation : Operation {
  let client: RTMClient

  init(client: RTMClient) {
    self.client = client
  }

  override func execute() {
    if client.token != nil {
      // There is nothing to do, just quit
      finish()
      return
    }

    client.getFrob { [weak self] frob, error in
      guard error == nil else {
        self?.finishWithError(error?.nserror)
        return
      }

      guard let frob = frob else {
        self?.finishWithError(AppError.MissingValue(name: "frob").nserror)
        return
      }

      guard let strongSelf = self else {
        self?.finishWithError(AppError.MissingValue(name: "self").nserror)
        return
      }

      let params = [
        "api_key": strongSelf.client.signer.apiKey,
        "perms": "delete",
        "frob": frob
      ]

      do {
        let query = strongSelf.client.signer.signedQueryForParams(params)
        guard let components = NSURLComponents(string: "https://www.rememberthemilk.com/services/auth/") else {
          throw Error.NeedARealError
        }
        components.query = query

        guard let authURL = components.URL else {
          throw Error.NeedARealError
        }
        LSOpenCFURLRef(authURL, nil)
      } catch {
        strongSelf.finishWithError(error.nserror)
      }

      print("After authorizing the app in your browser, come back here and hit RETURN.")

      let stdIn = NSFileHandle.fileHandleWithStandardInput()
      stdIn.readDataOfLength(1)

      strongSelf.client.getToken(frob) { token, error in
        let toSave = [
          "apiKey": strongSelf.client.signer.apiKey,
          "secret": strongSelf.client.signer.secret,
          "token": token!
        ]

        do {
          // TODO: this is ugly
          try WriteSimplePropertiesToPath("/Users/gmadrid/.rtmcli", props: toSave)
        } catch {
          strongSelf.finishWithError(error.nserror)
          return
        }

        strongSelf.finish()
      }
    }
  }
}
