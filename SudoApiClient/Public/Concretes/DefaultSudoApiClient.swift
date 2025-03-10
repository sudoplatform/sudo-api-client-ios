//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoLogging

/// Wrapper class for AppSyncClient to provide rate control and common error handling.
public class DefaultSudoApiClient: SudoApiClient {

    // MARK: - Properties

    /// Serial operation queue used for GraphQL mutations and queries with unsatisfied preconditions.
    public let serialQueue: ApiOperationQueue

    /// Concurrent operation queue used for GraphQL queries with all pre-condiions met.
    public let concurrentQueue: ApiOperationQueue

    // MARK: - Properties: Internal

    var graphQLClient: GraphQLClient

    let sudoUserClient: SudoUserClient

    let logger: Logger

    // MARK: - Lifecycle

    /// Initializes a `SudoApiClient` instance.
    /// - Parameters:
    ///   - config: The client configuration containing the API name, URL and region.
    ///   - sudoUserClient: `SudoUserClient` instance to provide the authentication token.
    ///   - serialQueue: Serial queue to use for mutations and queries with unmet preconditions.
    ///   - concurrentQueue: Concurrent queue to use for queries with preconditions met.
    ///   - logger: `Logger` instance to use for logging.
    public init(
        config: SudoApiClientConfig,
        sudoUserClient: SudoUserClient,
        serialQueue: ApiOperationQueue = SudoApiClientManager.serialOperationQueue,
        concurrentQueue: ApiOperationQueue = SudoApiClientManager.concurrentOperationQueue,
        logger: Logger = Logger.sudoApiClientLogger
    ) throws {
        self.sudoUserClient = sudoUserClient
        self.logger = logger
        self.serialQueue = serialQueue
        self.concurrentQueue = concurrentQueue
        graphQLClient = try DefaultGraphQLClient(apiName: config.apiName, endpoint: config.apiUrl, region: config.region)
    }

    // MARK: - Methods

    public func perform<Mutation: GraphQLMutation>(mutation: Mutation, operationTimeout: Int? = nil) async throws -> Mutation.Data {
        return try await withCheckedThrowingContinuation { continuation in
            let taskId = UUID().uuidString
            let op = MutationOperation(
                graphQLClient: graphQLClient,
                mutation: mutation,
                operationTimeout: operationTimeout,
                logger: logger
            ) { [weak self] result in
                self?.logger.info("Resuming continuation: operation=\(mutation.self), taskId=\(taskId), continuation: \(continuation)")
                continuation.resume(with: result)
            }
            do {
                try serialQueue.addOperation(op)
            } catch let error as ApiOperationError {
                continuation.resume(throwing: error)
            } catch {
                continuation.resume(throwing: ApiOperationError.fatalError(description: "Unexpected error adding query operation to queue"))
            }
        }
    }

    public func fetch<Query: GraphQLQuery>(query: Query) async throws -> Query.Data {
        return try await withCheckedThrowingContinuation { continuation in
            let taskId = UUID().uuidString
            let op = QueryOperation(graphQLClient: graphQLClient, query: query, logger: logger) { [weak self] result in
                self?.logger.info("Resuming continuation: operation=\(query.self), taskId=\(taskId), continuation: \(continuation)")
                continuation.resume(with: result)
            }
            do {
                try concurrentQueue.addOperation(op)
            } catch let error as ApiOperationError {
                continuation.resume(throwing: error)
            } catch {
                continuation.resume(throwing: ApiOperationError.fatalError(description: "Unexpected error adding query operation to queue"))
            }
        }
    }

    public func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        queue: DispatchQueue = DispatchQueue.main,
        statusChangeHandler: ((GraphQLClientConnectionState) -> Void)? = nil,
        completionHandler: ((Result<Void, Error>) -> Void)? = nil,
        resultHandler: @escaping (Result<Subscription.Data, Error>) -> Void
    ) -> GraphQLClientSubscription {
        return graphQLClient.subscribe(
            subscription,
            valueListener: { result in
                queue.async {
                    resultHandler(result)
                }
            },
            connectionListener: { connectionState in
                queue.async {
                    statusChangeHandler?(connectionState)
                }
            },
            completionListener: { completionResult in
                queue.async {
                    completionHandler?(completionResult)
                }
            }
        )
    }

    public func getGraphQLClient() -> GraphQLClient {
        graphQLClient
    }
}
