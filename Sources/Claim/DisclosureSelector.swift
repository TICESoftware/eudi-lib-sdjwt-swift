/*
 * Copyright (c) 2024 European Commission
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

public enum DisclosureSelectorError: Error {
  case pathNotJSONPath
  case disclosureNotDecodable
  case disclosureNotDigestable
}

class DisclosureSelector {
  
  private var signedSDJWT: SignedSDJWT
  
  public init(signedSDJWT: SignedSDJWT) {
    self.signedSDJWT = signedSDJWT
  }
  
  func selectDisclosures(paths: [String]) throws -> [Disclosure] {
    let digestCreator = DigestCreator()
    let payload = try signedSDJWT.jwt.payloadJSON()
    let allDisclosures = signedSDJWT.disclosures
    
    let selectedDisclosures = try allDisclosures.filter({ disclosure in
      guard let decodedDisclosure = disclosure.base64URLDecode() else { throw DisclosureSelectorError.disclosureNotDecodable }
      guard let disclosureDigest = digestCreator.hashAndBase64Encode(input: disclosure) else { throw DisclosureSelectorError.disclosureNotDigestable }
      return try paths.contains { path in
        guard path.hasPrefix("$.") else { throw DisclosureSelectorError.pathNotJSONPath }
        let endParts = path.split(separator: ".").dropFirst().map(String.init)
        guard let key = endParts.last else { throw DisclosureSelectorError.pathNotJSONPath }
        let nestingKeys = Array(endParts.dropLast())
        let objectContainingSDArray = payload[nestingKeys]
        let sdArray = objectContainingSDArray[Keys.sd.rawValue].arrayValue.compactMap(\.string)
        return sdArray.contains(disclosureDigest) && decodedDisclosure.objectProperty.key == key
      }
    })
    return selectedDisclosures
  }
}
