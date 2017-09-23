//
//  AppExtension.swift
//  Pics
//
//  Created by Kenta on 6/20/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import WebKit

public struct AppExtension<Base> {
    public let base: Base

    public init(_ base: Base) {
        self.base = base
    }
}

public protocol AppExtensionCompatible {
    associatedtype CompatibleType

    static var app: AppExtension<CompatibleType>.Type { get }
    var app: AppExtension<CompatibleType> { get }
}

public extension AppExtensionCompatible {
    static var app: AppExtension<Self>.Type {
        return AppExtension<Self>.self
    }

    var app: AppExtension<Self> {
        return AppExtension(self)
    }
}

extension NSObject: AppExtensionCompatible { }
