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
import XCTest

@testable import eudi_lib_sdjwt_swift

final class BuilderTest: XCTestCase {

  func testBuildingAnObject_GivenMultipleTypesOfClaims_ThenStringIsNotEmpty() {
    @SDJWTBuilder
    var sdObject: SdElement {
      PlainClaim("name", "Edmun")
      SdArrayClaim("Nationalites", array: [.flat(value: "DE"), .flat(value: 123)])
      ObjectClaim("adress") {
        PlainClaim("locality", "gr")
        FlatDisclosedClaim("adress", "Al. Mich")
      }
    }

    let sd = sdObject
    XCTAssert(sd.jsonString?.isEmpty == false)
  }

  func testMatchignOutput_GivenAFixedSaltValue_ThenJSONExists() {

    let salt = "2GLC42sKQveCfGfryNRN9w"
    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    @SDJWTBuilder
    var sdObject: SdElement {
      ObjectClaim("Adress") {
        ObjectClaim("Locality") {
          FlatDisclosedClaim("street_addres2s", "C Level")
          FlatDisclosedClaim("street_address", "Schulst. 12")
          PlainClaim("street", "Schulstr. 12")
          PlainClaim("street2", "Mich")
        }
      }
    }

    let unsignedJwt = factory.createJWT(sdJwtObject: sdObject.asObject)

    switch unsignedJwt {
    case .success((let json, let disclosures)):
      XCTAssert(true)
    case .failure(let err):
      XCTFail("Failed to Create SDJWT")
    }

  }

  func testNestedArrays_GivenFixedSalts() {

    let salt = "_26bc4LT-ac6q2KI6cBW5es"
    let factory = SDJWTFactory(saltProvider: MockSaltProvider(saltString: salt))

    @SDJWTBuilder
    var jwt: SdElement {
      FlatDisclosedClaim("name", "nikos")
    }

    let unsignedJwt = factory.createJWT(sdJwtObject: jwt.asObject)
    validateObjectResults(factoryResult: unsignedJwt, expectedDigests: jwt.expectedDigests)
  }

  func testPlainObjects_GivenNoElementsToBeDisclosed_ThenExpectedDigestsMatchesTheProducedDigests() {
    @SDJWTBuilder
    var plainJWT: SdElement {
      PlainClaim("string", "name")
      PlainClaim("number", 36524)
      PlainClaim("bool", true)
      PlainClaim("array", ["GR", "DE"])
    }

    @SDJWTBuilder
    var objects: SdElement {
      ObjectClaim("Object", value: plainJWT)
      ObjectClaim("ArrayObject") {
        SdArrayClaim("Array", array: [plainJWT])
      }
    }

    let jwtFactory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    let unsignedPlain = jwtFactory.createJWT(sdJwtObject: plainJWT.asObject)

    let objectPlain = jwtFactory.createJWT(sdJwtObject: objects.asObject)

    validateObjectResults(factoryResult: unsignedPlain, expectedDigests: 0)
    validateObjectResults(factoryResult: objectPlain, expectedDigests: 1)
  }

  func testDisclosedObjects_GivenOnlyFlatElementsToBeDisclosed_ThenExpectedDigestsMatchesTheProducedDigests() {
    @SDJWTBuilder
    var plainJWT: SdElement {
      FlatDisclosedClaim("string", "name")
      FlatDisclosedClaim("number", 36524)
      FlatDisclosedClaim("bool", true)
      FlatDisclosedClaim("array", ["GR", "DE"])
    }

    let json = plainJWT.asJSON

    @SDJWTBuilder
    var objects: SdElement {
      FlatDisclosedClaim("Flat Object", plainJWT.asJSON)
    }

    let jwtFactory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    let unsignedPlain = jwtFactory.createJWT(sdJwtObject: plainJWT.asObject)

    let objectPlain = jwtFactory.createJWT(sdJwtObject: objects.asObject)

    validateObjectResults(factoryResult: unsignedPlain, expectedDigests: 4)
    validateObjectResults(factoryResult: objectPlain, expectedDigests: 1)
  }

  func testRecursive() {
    @SDJWTBuilder
    var objects: SdElement {
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "Schulstr. 12")
        FlatDisclosedClaim("locality", "Schulpforta")
        FlatDisclosedClaim("region", "Sachs,n-Anhalt")
        PlainClaim("country", "DE")
        RecursiveObject("deep object embeded") {
          PlainClaim("deep", "deeep value")
          FlatDisclosedClaim("deep_disclosed", "deep disclosed claim")
        }
      }
    }

    let jwtFactory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    let recursiveObject = jwtFactory.createJWT(sdJwtObject: objects.asObject)

    validateObjectResults(factoryResult: recursiveObject, expectedDigests: objects.expectedDigests)
  }

  func testRecursiveDisclosedObjects_GivenPlainAndFlatElementsToBeDisclosed_ThenExpectedDigestsMatchesTheProducedDigests() {
    @SDJWTBuilder
    var objects: SdElement {
      ObjectClaim("address") {
        FlatDisclosedClaim("street_address", "Schulstr. 12")
        FlatDisclosedClaim("locality", "Schulpforta")
        FlatDisclosedClaim("region", "Sachs,n-Anhalt")
        PlainClaim("country", "DE")
        RecursiveObject("deep object embeded") {
          PlainClaim("deep", "deeep value")
          FlatDisclosedClaim("deep_disclosed", "deep disclosed claim")
        }
      }
    }

    let jwtFactory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    let recursiveObject = jwtFactory.createJWT(sdJwtObject: objects.asObject)

    validateObjectResults(factoryResult: recursiveObject, expectedDigests: 5)
  }

  func testDisclosedObjects_GivenArrayElementsToBeDisclosed_ThenExpectedDigestsMatchesTheProducedDigests() {
    @SDJWTBuilder
    var array: SdElement {
      RecursiveSdArrayClaim("nationalities") {
        SdElement.flat("DE")
        SdElement.plain("GR")
      }
    }

    let jwtFactory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    let recursiveObject = jwtFactory.createJWT(sdJwtObject: array.asObject)

    validateObjectResults(factoryResult: recursiveObject, expectedDigests: array.expectedDigests)
  }

  func testNestedArrays() {
    @SDJWTBuilder
    var nestedArrays: SdElement {
      SdArrayClaim("array", array: [
        .array([
          .plain(1),
          .flat(2),
          .object({
            FlatDisclosedClaim("nested object in array key", "nested object in array value")
          })
        ]),
        .plain(value: "other value"),
      ])
    }

    let factory = SDJWTFactory(saltProvider: DefaultSaltProvider())

    validateObjectResults(factoryResult: factory.createJWT(sdJwtObject: nestedArrays.asObject), expectedDigests: 3)
  }
}
