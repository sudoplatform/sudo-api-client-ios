//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoLogging
import SudoConfigManager

/// Manages a pool of GraphQL client instances, indexed by configuration namespace and unique by (apiUrl, region),
/// shared by multiple platform service clients.
public class SudoApiClientManager {

    // MARK: - Supplementary

    struct Config {

        /// Default configuration namespace.
        struct Namespace {
            static let apiService = "apiService"
        }
    }

    // MARK: - Properties

    /// Singleton instance of `SudoApiClientManager`.
    public static let instance = SudoApiClientManager()

    /// Serial operation queue shared (default) by `SudoApiClient` instances for GraphQL mutations and queries with unsatisfied
    /// preconditions.
    public static let serialOperationQueue: ApiOperationQueue = DefaultApiOperationQueue(
        maxConcurrentOperationCount: 1,
        maxQueueDepth: 10
    )

    /// Concurrent operation queue shared (default) by `SudoApiClient` instances for GraphQL queries with all preconditions met.
    public static let concurrentOperationQueue: ApiOperationQueue = DefaultApiOperationQueue(
        maxConcurrentOperationCount: 3,
        maxQueueDepth: 10
    )

    // MARK: - Properties: Internal

    let clientStoreLock = NSLock()

    var _clientStore: [String: SudoApiClient] = [:]

    var clientStore: [String: SudoApiClient] {
        get { clientStoreLock.withCriticalScope { _clientStore } }
        set { clientStoreLock.withCriticalScope { _clientStore = newValue } }
    }

    let configManager: SudoConfigManager

    let defaultConfig: SudoApiClientConfig

    let logger: Logger

    // MARK: - Lifecycle

    /// Initializes `ApiClientManager`.
    /// - Parameters:
    ///  - configManager: The manage for fetching the platform config file.  Leave `nil` for a default to be provided.
    ///  - logger: Logger used for logging.  Leave `nil` for a default to be provided.
    init?(configManager: SudoConfigManager? = nil, logger: Logger? = nil) {
        self.logger = logger ?? Logger.sudoApiClientLogger
        if let configManager {
            self.configManager = configManager
        } else {
            let configManagerName = SudoConfigManagerFactory.Constants.defaultConfigManagerName
            guard let defaultConfigManager = SudoConfigManagerFactory.instance.getConfigManager(name: configManagerName) else {
                self.logger.error("Unable to initialize default config manager")
                return nil
            }
            self.configManager = defaultConfigManager
        }
        guard
            let configSet = self.configManager.getConfigSet(namespace: Config.Namespace.apiService),
            let apiServiceConfig = SudoApiClientConfig(apiName: Config.Namespace.apiService, configSet: configSet)
        else {
            self.logger.error("Configuration set for \"\(Config.Namespace.apiService)\" not found.")
            return nil
        }
        defaultConfig = apiServiceConfig
    }

    // MARK: - Methods

    /// Returns an appropriately configured GraphQL API client. All configuration namespaces with the same
    /// apiUrl/region value will share the same client.
    /// - Parameters:
    ///   - sudoUserClient: `SudoUserClient` instance used for authenticating the GraphQL API client.
    ///   - configNamespace: The name of the API to fetch the config set for.  Leave `nil` to use the default config.
    public func getClient(sudoUserClient: SudoUserClient, configNamespace: String? = nil) throws -> SudoApiClient {
        var clientConfig: SudoApiClientConfig = defaultConfig
        if let configNamespace {
            guard
                let configSet = configManager.getConfigSet(namespace: configNamespace),
                let config = SudoApiClientConfig(apiName: configNamespace, configSet: configSet)
            else {
                logger.error("Configuration set for \(configNamespace) not found")
                throw ApiOperationError.invalidArgument
            }
            clientConfig = config
        }
        let key = "\(clientConfig.region):\(clientConfig.apiUrl)"
        if let existingClient = clientStore[key] {
            return existingClient
        } else {
            let newClient = try DefaultSudoApiClient(config: clientConfig, sudoUserClient: sudoUserClient)
            clientStore[key] = newClient
            return newClient
        }
    }

    /// Clears any cached clients and causes all clients to be re-created on next access.
    public func reset() {
        clientStore.removeAll()
    }
}
