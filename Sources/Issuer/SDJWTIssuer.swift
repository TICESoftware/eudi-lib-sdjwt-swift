/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Foundation
import JOSESwift
import SwiftyJSON

class SDJWTIssuer {

  // MARK: - Properties

  var sdjwt: SDJWT

  enum Purpose {
    case issuance(JWSHeader, ClaimSet)
    case presentation(JWSHeader, ClaimSet, KBJWTContent?)
  }

  // MARK: - Lifecycle

  init(purpose: Purpose) throws {
    switch purpose {
    case .issuance(let header, let claimSet):
      self.sdjwt = try SDJWT(header: header, claimSet: claimSet)
    case .presentation(let header, let claimSet,  let kbJwtContent):
      if let kbJwtContent {
        self.sdjwt = try SDJWT(header: header, claimSet: claimSet, kbJwtHeader: kbJwtContent.header, KBJWTBody: kbJwtContent.payload)
      } else {
        self.sdjwt = try SDJWT(header: header, claimSet: claimSet)
      }
    }

  }

  // MARK: - Methods

  func createSignedJWT<KeyType>(jwsController: JWSController<KeyType>) throws -> JWS {
    try sdjwt.jwt.sign(signer: jwsController.signer)
  }

  func createSignedKBJWT<KeyType>(jwsController: JWSController<KeyType>) throws -> JWS? {
    try sdjwt.kbJwt?.sign(signer: jwsController.signer)
  }

  func serialize(jws: JWS) -> Data? {
    let jwsString = jws.compactSerializedString
    let disclosures = self.sdjwt.disclosures.reduce(into: "") { partialResult, disclosure in
      partialResult += "~\(disclosure)"
    }

//    let kbJwtString = "~" + (self.kbJwt?.compactSerializedString ?? "")

    let output = jwsString + disclosures //+ kbJwtString
    return output.data(using: .utf8)
  }

  // TODO: Revisit Logic of who handles the signing 
//  func createKBJWT() throws -> KBJWT {
//    let header = JWSHeader(algorithm: .ES256)
//    let payload = Payload(Data())
//    let signer = jwsController.signer
//    let jws = try JWS(header: header, payload: payload, signer: signer)
//
//    return jws
//  }
}
