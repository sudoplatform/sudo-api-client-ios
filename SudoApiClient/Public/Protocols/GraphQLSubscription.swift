//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A protocol representing an active GraphQL subscription.
public protocol GraphQLClientSubscription: AnyObject {

    /// Cancels the active subscription, stopping further updates.
    func cancel()
}
