//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SudoLogging
import SudoUser

/// Utility for transforming error types to the public `ApiOperationError` defined in this SDK.
enum ApiOperationErrorTransformer {

    // MARK: - Supplementary

    enum SudoPlatformServiceError {
        static let type = "errorType"
        static let accountLockedError = "sudoplatform.AccountLockedError"
        static let conditionalCheckFailedException = "DynamoDB:ConditionalCheckFailedException"
        static let decodingError = "sudoplatform.DecodingError"
        static let insufficientEntitlementsError = "sudoplatform.InsufficientEntitlementsError"
        static let invalidArgumentError = "sudoplatform.InvalidArgumentError"
        static let limitExceededError = "sudoplatform.LimitExceededError"
        static let serviceError = "sudoplatform.ServiceError"
    }

    // MARK: - Methods

    static func transformError<T: Decodable>(_ error: Error, type: T.Type) -> ApiOperationError {
        if let operationError = error as? ApiOperationError {
            return operationError
        }
        if let graphQLResponseError = error as? GraphQLResponseError<T> {
            return transformGraphQLResponseError(graphQLResponseError)
        }
        if let apiError = error as? APIError {
            return transformApiError(apiError)
        }
        return ApiOperationError.graphQLError(cause: error)
    }

    static func transformApiError(_ apiError: APIError) -> ApiOperationError {
        if let authError = apiError.underlyingError as? AuthError {
            return transformAuthError(authError)
        }
        switch apiError {
        case .unknown:
            return .appSyncClientError(cause: apiError)

        case .invalidURL:
            return .invalidArgument

        case .operationError:
            return .serviceError

        case .networkError:
            return .requestFailed(response: nil, cause: apiError.underlyingError)

        case .httpStatusError(let statusCode, let response):
            if statusCode == 401 {
                return .notAuthorized
            }
            return .requestFailed(response: response, cause: nil)

        case .invalidConfiguration(let description, _, _):
            return .fatalError(description: "Invalid configuration: \(description)")

        case .pluginError(let error):
            if error is AuthError {
                return .notAuthorized
            }
            return .fatalError(description: "Amplify plugin error: \(error.errorDescription)")

        }
    }

    static func transformGraphQLResponseError<T: Decodable>(_ error: GraphQLResponseError<T>) -> ApiOperationError {
        switch error {
        case .error(let graphQLErrors), .partial(_, let graphQLErrors):
            for graphQLError in graphQLErrors {
                if let transformedGraphQLError = transformGraphQLError(graphQLError) {
                    return transformedGraphQLError
                }
            }
            return .fatalError(description: "GraphQL operation failed but error type was not found in the response.")

        case .transformationError(_, let apiError):
            return transformApiError(apiError)

        case .unknown(let description, _, _):
            return .fatalError(description: description)
        }
    }

    static func transformGraphQLError(_ graphQLError: GraphQLError) -> ApiOperationError? {
        guard let errorType = graphQLError.extensions?[SudoPlatformServiceError.type]?.stringValue else {
            return nil
        }
        switch errorType {
        case SudoPlatformServiceError.insufficientEntitlementsError:
            return .insufficientEntitlements

        case SudoPlatformServiceError.invalidArgumentError:
            return .invalidArgument

        case SudoPlatformServiceError.limitExceededError:
            return .limitExceeded

        case SudoPlatformServiceError.conditionalCheckFailedException:
            return .versionMismatch

        case SudoPlatformServiceError.accountLockedError:
            return .accountLocked

        case SudoPlatformServiceError.decodingError:
            return .invalidRequest

        case SudoPlatformServiceError.serviceError:
            return .serviceError

        default:
            return .graphQLError(cause: graphQLError)
        }
    }

    static func transformAuthError(_ authError: AuthError) -> ApiOperationError {
        switch authError {
        case .signedOut:
            return ApiOperationError.notSignedIn

        case .notAuthorized, .validation, .configuration, .sessionExpired, .invalidState, .service, .unknown:
            return ApiOperationError.notAuthorized
        }
    }
}
