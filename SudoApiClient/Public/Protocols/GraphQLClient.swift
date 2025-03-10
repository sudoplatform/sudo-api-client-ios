//
// Copyright © 2025 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSAPIPlugin
import Foundation
import SudoUser

/// A protocol defining a client for executing GraphQL operations, including queries, mutations, and subscriptions.
public protocol GraphQLClient {

    /// Executes a GraphQL query and returns the result.
    /// - Parameter query: The `GraphQLQuery` to execute.
    /// - Returns: The decoded response data of type `Q.Data`.
    /// - Throws: An error if the request fails or decoding is unsuccessful.
    @discardableResult
    func query<Q: GraphQLQuery>(_ query: Q) async throws -> Q.Data

    /// Executes a GraphQL mutation and returns the result.
    /// - Parameter mutation: The `GraphQLMutation` to execute.
    /// - Returns: The decoded response data of type `M.Data`.
    /// - Throws: An error if the request fails or decoding is unsuccessful.
    @discardableResult
    func mutate<M: GraphQLMutation>(_ mutation: M) async throws -> M.Data

    /// Subscribes to a GraphQL subscription and listens for real-time updates.
    /// - Parameters:
    ///   - subscription: The `GraphQLSubscription` to execute.
    ///   - valueListener: A closure that receives updates with `Result<S.Data, Error>`.
    ///   - connectionListener: A closure that provides updates on the subscription's connection state.
    ///   - completionListener: A closure that is called when the subscription completes, with a success or failure result.
    /// - Returns: A `GraphQLClientSubscription` instance, which can be used to cancel the subscription.
    func subscribe<S: GraphQLSubscription>(
        _ subscription: S,
        valueListener: ((Result<S.Data, Error>) -> Void)?,
        connectionListener: ((GraphQLClientConnectionState) -> Void)?,
        completionListener: ((Result<Void, Error>) -> Void)?
    ) -> GraphQLClientSubscription
}

extension GraphQLSubscriptionOperation: GraphQLClientSubscription {}
