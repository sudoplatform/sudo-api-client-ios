//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSAPIPlugin
import enum AWSPluginsCore.AWSAuthorizationType
import Foundation

/// A default implementation of `GraphQLClient` that interacts with AWS GraphQL backend.
/// This class handles authentication, request construction, and execution of GraphQL queries and mutations.
class DefaultGraphQLClient: GraphQLClient {

    // MARK: - Properties

    /// The name of graphQL API being invoked.
    let apiName: String

    /// The GraphQL API endpoint URL.
    let endpoint: String

    /// The AWS region where the API is deployed.
    let region: String

    /// The AWS Amplify API plugin used for making network requests.
    let apiPlugin: AWSAPIPlugin

    // MARK: - Lifecycle

    /// Initializes a `GraphQLClient` conforming instances for making requests to an AWS GraphQL backend..
    /// - Parameters:
    ///   - apiName: The name of graphQL API being invoked.
    ///   - endpoint: The GraphQL API endpoint URL.
    ///   - region: The AWS region where the API is deployed.
    init(apiName: String, endpoint: String, region: String) throws {
        self.apiName = apiName
        self.endpoint = endpoint
        self.region = region
        let authProviderFactory = DefaultAPIAuthProviderFactory()
        apiPlugin = AWSAPIPlugin(apiAuthProviderFactory: authProviderFactory)
        let pluginConfig: [String: String] = [
            "endpointType": "GraphQL",
            "endpoint": endpoint,
            "region": region,
            "authorizationType": AWSAuthorizationType.openIDConnect.rawValue
        ]
        let config = JSONValue.object([
            apiName: JSONValue.object(pluginConfig.mapValues(JSONValue.string))
        ])
        try apiPlugin.configure(using: config)
    }

    // MARK: - Conformance: GraphQLClient

    func query<Q: GraphQLQuery>(_ query: Q) async throws -> Q.Data {
        let request = query.transformToGraphQLRequest(apiName: apiName)
        return try await apiPlugin.query(request: request).get()
    }

    func mutate<M: GraphQLMutation>(_ mutation: M) async throws -> M.Data {
        let request = mutation.transformToGraphQLRequest(apiName: apiName)
        return try await apiPlugin.query(request: request).get()
    }

    func subscribe<S: GraphQLSubscription>(
        _ subscription: S,
        valueListener: ((Result<S.Data, Error>) -> Void)?,
        connectionListener: ((GraphQLClientConnectionState) -> Void)?,
        completionListener: ((Result<Void, Error>) -> Void)?
    ) -> GraphQLClientSubscription {
        let request = subscription.transformToGraphQLRequest(apiName: apiName)
        return apiPlugin.subscribe(
            request: request,
            valueListener: { event in
                switch event {
                case .connection(let connectionState):
                    switch connectionState {
                    case .connecting:
                        connectionListener?(.connecting)
                    case .connected:
                        connectionListener?(.connected)
                    case .disconnected:
                        connectionListener?(.disconnected)
                    }
                case .data(let dataResult):
                    switch dataResult {
                    case .success(let data):
                        valueListener?(.success(data))
                    case .failure(let error):
                        let transformedError = ApiOperationErrorTransformer.transformError(error, type: S.Data.self)
                        valueListener?(.failure(transformedError))
                    }
                }
            },
            completionListener: { result in
                switch result {
                case .success:
                    completionListener?(.success(()))
                case .failure(let error):
                    let transformedError = ApiOperationErrorTransformer.transformError(error, type: S.Data.self)
                    completionListener?(.failure(transformedError))
                }
            }
        )
    }
}
