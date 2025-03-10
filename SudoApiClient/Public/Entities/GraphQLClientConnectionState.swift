//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents the connection state of a GraphQL subscription.
public enum GraphQLClientConnectionState: Equatable {

    /// The subscription is in the process of connecting.
    case connecting

    /// The subscription is connected and actively receiving updates.
    case connected

    /// The subscription has been disconnected.
    case disconnected
}
