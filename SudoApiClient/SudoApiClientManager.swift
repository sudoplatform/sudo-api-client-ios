//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoUser
import SudoLogging
import SudoConfigManager

/// Manages a pool of GraphQL client instances, indexed by configuration namespace and unique by (apiUrl, region),
/// shared by multiple platform service clients.
public class SudoApiClientManager {

    // MARK: - Supplementary

    /// Singleton instance of `SudoApiClientManager`.
    public static let instance = SudoApiClientManager()

    /// Serial operation queue shared (default) by `SudoApiClient` instances for GraphQL mutations and queries with unsatisfied
    /// preconditions.
    public static let serialOperationQueue: ApiOperationQueue = DefaultApiOperationQueue(maxConcurrentOperationCount: 1, maxQueueDepth: 10)

    /// Concurrent operation queue shared (default) by `SudoApiClient` instances for GraphQL queries with all preconditions met.
    public static let concurrentOperationQueue: ApiOperationQueue = DefaultApiOperationQueue(maxConcurrentOperationCount: 3, maxQueueDepth: 10)

    private struct Config {

        // Default configuration namespace.
        struct Namespace {
            static let apiService = "apiService"
        }

    }

    // MARK: - Properties

    private var namespacedClients: [String: SudoApiClient] = Dictionary()

    private let logger: Logger

    private let defaultConfigSet: [String: Any]?
    private let defaultConfigProvider: SudoApiClientConfigProvider

    private let queue = DispatchQueue(label: "com.sudoplatform.apiclient")

    /// Initializes `ApiClientManager`.
    ///
    /// - Parameter logger: Logger used for logging.
    private init?(logger: Logger? = nil) {
        self.logger = logger ?? Logger.sudoApiClientLogger

        guard let config = DefaultSudoConfigManager()?.getConfigSet(namespace: Config.Namespace.apiService) else {
            self.logger.error("Configuration set for \"\(Config.Namespace.apiService)\" not found.")
            return nil
        }

        self.logger.info("Initializing SudoApiClientManager with config: \(config)")

        guard let configProvider = SudoApiClientConfigProvider(config: config) else {
            self.logger.error("Invalid config: \"\(config)\".")
            return nil
        }

        self.defaultConfigSet = config
        self.defaultConfigProvider = configProvider
    }

    /// Returns an appropriately configured GraphQL API client. All configuration namespaces with the same
    /// apiUrl/region value will share the same client.
    ///
    /// - Parameter sudoUserClient: `SudoUserClient` instance used for authenticating the GraphQL API client.
    public func getClient(sudoUserClient: SudoUserClient, configNamespace: String? = nil) throws -> SudoApiClient {
        guard let requestedConfig = configNamespace == nil ? self.defaultConfigSet : DefaultSudoConfigManager()?.getConfigSet(namespace: configNamespace!) else {
            self.logger.error("Configuration set for \(configNamespace!) not found")
            throw ApiOperationError.invalidArgument
        }
        return try self.queue.sync {
            let matchesDefaultConfig = matchesDefaultConfig(configSet: requestedConfig )
            let configNamespaceToUse = matchesDefaultConfig ? Config.Namespace.apiService : configNamespace ?? Config.Namespace.apiService
            guard let configProvider = matchesDefaultConfig ? self.defaultConfigProvider : SudoApiClientConfigProvider(config: requestedConfig) else {
                throw ApiOperationError.invalidArgument
            }
            if let client = self.namespacedClients[configNamespaceToUse] {
                return client
            } else {
                let client = try SudoApiClient(configProvider: configProvider, sudoUserClient: sudoUserClient)
                self.namespacedClients[configNamespaceToUse] = client
                return client
            }
        }
    }

    /// Clears any cached data including queries, subscriptions, pending mutations data and causes all clients to be
    /// re-created on next access.
    public func reset() throws {
        try self.queue.sync {
            try self.namespacedClients.forEach { try $0.value.clearCaches() }
            self.namespacedClients = Dictionary()
        }
    }

    private func matchesDefaultConfig(configSet: [String: Any]?) -> Bool {
        guard let requestedConfigSet = configSet else {
            return true
        }
        let apiUrl = requestedConfigSet[SudoApiClientConfigProvider.Config.apiUrl] as? String
        let region = requestedConfigSet[SudoApiClientConfigProvider.Config.region] as? String

        return (apiUrl == nil || apiUrl == self.defaultConfigSet?[SudoApiClientConfigProvider.Config.apiUrl] as? String) &&
        (region == nil || region == self.defaultConfigSet?[SudoApiClientConfigProvider.Config.region] as? String)
    }

}
