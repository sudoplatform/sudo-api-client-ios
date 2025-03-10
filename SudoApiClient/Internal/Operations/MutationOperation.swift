//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import SudoUser

/// Operation to perform a GraphQL mutation.
class MutationOperation<Mutation: GraphQLMutation>: ApiOperation {

    // MARK: - Types

    typealias ResultHandler = (Result<Mutation.Data, ApiOperationError>) -> Void

    // MARK: - Properties

    private let graphQLClient: GraphQLClient
    private let mutation: Mutation
    private let resultHandler: ResultHandler
    private let operationTimeout: Int?

    // MARK: - Lifecycle

    /// Initializes an operation to perform a GraphQL mutation.
    /// - Parameters:
    ///   - graphQLClient: GraphQL client to use to interact with Sudo Platform  service.
    ///   - mutation: The mutation to perform.
    ///   - operationTimeout: An optional operation timeout in seconds.
    ///   - logger: Logger to use for logging.
    ///   - resultHandler: A closure that is called when mutation results are available or when an error occurs.
    init(
        graphQLClient: GraphQLClient,
        mutation: Mutation,
        operationTimeout: Int? = nil,
        logger: Logger = Logger.sudoApiClientLogger,
        resultHandler: @escaping ResultHandler
    ) {
        self.graphQLClient = graphQLClient
        self.mutation = mutation
        self.operationTimeout = operationTimeout
        self.resultHandler = resultHandler
        super.init(logger: logger)
    }

    // MARK: - Overrides

    override func execute() {
        graphQLOperation = Task {
            await withTaskGroup(of: Result<Mutation.Data, ApiOperationError>.self) { taskGroup in
                taskGroup.addTask {
                    do {
                        let mutationData = try await self.graphQLClient.mutate(self.mutation)
                        return .success(mutationData)
                    } catch {
                        let operationError = ApiOperationErrorTransformer.transformError(error, type: Mutation.Data.self)
                        return .failure(operationError)
                    }
                }
                if let operationTimeout {
                    taskGroup.addTask {
                        try? await Task.sleep(seconds: TimeInterval(operationTimeout))
                        return .failure(.timedOut)
                    }
                }
                if let firstResult = await taskGroup.next() {
                    resultHandler(firstResult)
                    done()
                }
            }
        }
    }
}
