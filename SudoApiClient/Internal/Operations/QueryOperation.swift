//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import SudoUser

/// Operation to perform a GraphQL query.
class QueryOperation<Query: GraphQLQuery>: ApiOperation {

    // MARK: - Types

    typealias ResultHandler = (Result<Query.Data, ApiOperationError>) -> Void

    // MARK: - Properties

    private let graphQLClient: GraphQLClient
    private let query: Query
    private let resultHandler: ResultHandler

    // MARK: - Lifecycle

    /// Initializes an operation to perform a GraphQL query.
    /// - Parameters:
    ///   - graphQLClient: GraphQL client to use to interact with Sudo Platform  service.
    ///   - query: The query to fetch.
    ///   - logger: Logger to use for logging.
    ///   - resultHandler: A closure that is called when query results are available or when an error occurs.
    init(
        graphQLClient: GraphQLClient,
        query: Query,
        logger: Logger = Logger.sudoApiClientLogger,
        resultHandler: @escaping ResultHandler
    ) {
        self.graphQLClient = graphQLClient
        self.query = query
        self.resultHandler = resultHandler
        super.init(logger: logger)
    }

    // MARK: - Overrides

    override func execute() {
        graphQLOperation = Task {
            let result: Result<Query.Data, ApiOperationError>
            do {
                let queryData = try await graphQLClient.query(query)
                result = .success(queryData)
            } catch {
                let operationError = ApiOperationErrorTransformer.transformError(error, type: Query.Data.self)
                result = .failure(operationError)
            }
            guard !Task.isCancelled else {
                return
            }
            resultHandler(result)
            done()
        }
    }
}
