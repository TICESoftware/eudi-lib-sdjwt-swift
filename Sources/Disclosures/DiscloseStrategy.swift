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

protocol DiscloseStrategyProtocol: ClaimConvertible {
  var key: String { get }
  var claim: Claim { get }

  func asElement() -> Claim
}

protocol ClaimConvertible {
  func asElement() -> Claim
}

struct FlatDisclose: DiscloseStrategyProtocol {

  // MARK: - Properties

  var key: String
  var claim: Claim

  // MARK: - LifeCycle

  init(name: String,
       builder: () -> Claim) {
    self.key = name
    self.claim = builder()

  }

  // MARK: - Methods

  func asElement() -> Claim {
    let disclosed = DisclosedClaim(self.key, self.claim.value)
    guard let disclosed = disclosed.flatDisclose(digestCreator: DigestCreator()) else {
      return disclosed
    }
    return disclosed
  }

  func flatDisclose(claim: Claim, signer: DigestCreator) -> Self? {
    return nil
    var claim = claim
    var hashedElement = try? claim.base64Encode(saltProvider: signer.saltProvider)
    hashedElement?.key = "_sd"
//
//    guard let hashedValue = try? self.hashValue(signer: signer, base64EncodedValue: hashedElement.value) else {
//      return nil
//    }
////
//    hashedElement.value = .array([hashedValue])
//
//    return hashedElement
  }
}

// TODO: Add the correct functionality in the DSL

extension DisclosedClaim {

  func flatDisclose(digestCreator: DigestCreator) -> Self? {

    var hashedElement = self.base64Encode(saltProvider: digestCreator.saltProvider)
    hashedElement.key = "_sd"

    guard let hashedValue = try? self.hashValue(digestCreator: digestCreator, base64EncodedValue: hashedElement.value) else {
      return nil
    }

    hashedElement.value = .array([hashedValue])

    return hashedElement
  }
}
