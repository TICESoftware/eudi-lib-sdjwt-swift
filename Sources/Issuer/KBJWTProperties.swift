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
import JOSESwift

public struct KBJWTProperties {
  
  public internal(set) var alg: SignatureAlgorithm
  public internal(set) var iat: Date
  public internal(set) var aud: String
  public internal(set) var nonce: String
  
  public init(alg: SignatureAlgorithm, iat: Date = Date(), aud: String, nonce: String) {
    self.alg = alg
    self.iat = iat
    self.aud = aud
    self.nonce = nonce
  }
}
