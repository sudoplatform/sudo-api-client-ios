//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Contains the configuration properties required to instantiate a `SudoApiClient` instance.
public struct SudoApiClientConfig: Equatable {

    // MARK: - Supplementary

    enum Key {
        static let region = "region"
        static let apiUrl = "apiUrl"
    }

    // MARK: - Properties

    /// The name of graphQL API.
    public let apiName: String

    /// The GraphQL API endpoint URL.
    public let apiUrl: String

    /// The AWS region where the API is deployed.
    public let region: String

    // MARK: - Lifecycle

    /// Initialize a configuration for a SudoApiClient.
    /// - Parameters:
    ///   - apiName: The name of GraphQL API.
    ///   - apiUrl: The GraphQL API endpoint URL.
    ///   - region: The AWS region where the API is deployed.
    public init(apiName: String, apiUrl: String, region: String) {
        self.apiName = apiName
        self.apiUrl = apiUrl
        self.region = region
    }

    /// Convenience initializer to construct a SudoApiClient given the API name and the corresponding config set.
    /// - Parameters:
    ///   - apiName: The name of GraphQL API.
    ///   - configSet: The dictionary containing the config values corresponding to the `apiName`.
    public init?(apiName: String, configSet: [String: Any]?) {
        guard let region = configSet?[Key.region] as? String, let apiUrl = configSet?[Key.apiUrl] as? String else {
            return nil
        }
        self.init(apiName: apiName, apiUrl: apiUrl, region: region)
    }
}
