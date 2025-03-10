//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser

/// Wrapper class for AppSyncClient to provide rate control and common error handling.
public protocol SudoApiClient: AnyObject {

    /// Performs a mutation by sending it to the server. Internally, these mutations are added to a queue and performed
    /// serially, in first-in, first-out order. Clients can inspect the size of the queue with the `queuedMutationCount`
    /// property.
    /// - Parameters:
    ///   - mutation: The mutation to perform.
    ///   - operationTimeout: Optional timeout in seconds for the operation.  Defaults to `nil`.
    /// - Returns: The result of the mutation or error.
    func perform<Mutation: GraphQLMutation>(mutation: Mutation, operationTimeout: Int?) async throws -> Mutation.Data

    /// Fetches a query from the server or from the local cache, depending on the current contents of the cache and the
    /// specified cache policy.
    /// - Parameter query: The query to fetch.
    /// - Returns: The result of the query or error.
    func fetch<Query: GraphQLQuery>(query: Query) async throws -> Query.Data

    /// Subscribes to a GraphQL subscription.
    /// - Parameters:
    ///   - subscription: GraphQL subscription to subscribe to.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - statusChangeHandler: A closure that is called when the subscription status changes.
    ///   - completionHandler: A closure that is called when the subscription completes, with a success or failure result.
    ///   - resultHandler: A closure that is called when subscription results are available or when an error occurs.
    /// - Returns: A `GraphQLClientSubscription` which can be used to cancel the subscription.
    func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        queue: DispatchQueue,
        statusChangeHandler: ((GraphQLClientConnectionState) -> Void)?,
        completionHandler: ((Result<Void, Error>) -> Void)?,
        resultHandler: @escaping (Result<Subscription.Data, Error>) -> Void
    ) -> GraphQLClientSubscription

    /// Returns the underlying `GraphQLClient` instance.
    /// - Returns:`GraphQLClient` instance.
    func getGraphQLClient() -> GraphQLClient
}

public extension SudoApiClient {

    func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        operationTimeout: Int? = nil
    ) async throws -> Mutation.Data {
        try await perform(mutation: mutation, operationTimeout: operationTimeout)
    }

    func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        queue: DispatchQueue = DispatchQueue.main,
        statusChangeHandler: ((GraphQLClientConnectionState) -> Void)? = nil,
        completionHandler: ((Result<Void, Error>) -> Void)? = nil,
        resultHandler: @escaping (Result<Subscription.Data, Error>) -> Void
    ) -> GraphQLClientSubscription {
        subscribe(
            subscription: subscription,
            queue: queue,
            statusChangeHandler: statusChangeHandler,
            completionHandler: completionHandler,
            resultHandler: resultHandler
        )
    }
}
