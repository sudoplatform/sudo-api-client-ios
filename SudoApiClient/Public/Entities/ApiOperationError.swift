//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The different errors thrown by the `SudoApiClient` and `SudoApiClientManager`.
public enum ApiOperationError: Error {

    /// One of preconditions of the operation was not met.
    case preconditionFailure

    /// Operation failed due to the user not being signed in.
    case notSignedIn

    /// Operation failed due to authorization error. This maybe due to the authentication token being
    /// invalid or other security controls prevent the user from accessing the API.
    case notAuthorized

    /// Operation failed due to it requiring tokens to be refreshed but something else is already in
    /// middle of refreshing the tokens.
    case refreshTokensOperationAlreadyInProgress

    /// Operation failed due to the backend entitlements error. This maybe due to the user not having
    /// sufficient entitlements or exceeding some other service limit.
    case insufficientEntitlements

    /// Operation failed due to it exceeding some limits imposed for the API. For example, this error
    /// can occur if the resource size exceeds the database record size limit.
    case limitExceeded

    /// Operation failed because the user account is locked.
    case accountLocked

    /// Indicates that an operation rejects the request because a provided argument
    /// did not have a valid value
    case invalidArgument

    /// Operation failed due to an invalid request. This maybe due to the version mismatch between the
    /// client and the backend.
    case invalidRequest

    /// Indicates that an internal server error caused the operation to fail. The error is possibly transient
    /// and retrying at a later time may cause the operation to complete successfully
    case serviceError

    /// Indicates that there were too many attempts at sending API requests within a short period of
    /// time.
    case rateLimitExceeded

    /// Indicates the version of the object that is getting updated does not match the current version of the
    /// object in the backend. The caller should retrieve the current version of the object and reconcile the
    /// difference.
    case versionMismatch

    /// Indicates the API operation did not complete within the expected amount of time and has been
    /// cancelled.
    case timedOut

    /// GraphQL endpoint returned an error.
    case graphQLError(cause: Error)

    /// GraphQL request failed due to connectivity, availability or access error.
    case requestFailed(response: HTTPURLResponse?, cause: Error?)

    /// AppSyncClient client returned an unexpected error.
    case appSyncClientError(cause: Error)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory  condition
    /// or other conditions that is beyond control this library.
    case fatalError(description: String)
}
