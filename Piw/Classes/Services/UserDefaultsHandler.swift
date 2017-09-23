//
//  UserDefaultsHandler.swift
//  Pics
//
//  Created by Kenta on 7/21/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation

fileprivate protocol UserDefaultsHandleable {
    associatedtype ValueType

    static var key: String { get }
    static func set(_ value: ValueType)
    static func get() -> ValueType
    static func remove()
}

extension UserDefaultsHandleable {
    static var key: String {
        let name = "\(Self.self)"
        return name
    }
}

class UserDefaultsHandler {

    struct GuidedMobileNetworkDefaultIsDisabled: UserDefaultsHandleable {
        typealias ValueType = Bool

        static func set(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }

        static func get() -> Bool {
            return UserDefaults.standard.bool(forKey: key)
        }

        static func remove() {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    struct EnableMobileNetwork: UserDefaultsHandleable {
        typealias ValueType = Bool

        static func set(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }

        static func get() -> Bool {
            return UserDefaults.standard.bool(forKey: key)
        }

        static func remove() {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }


    struct ShowedStartBrowseTooltip: UserDefaultsHandleable {
        typealias ValueType = Bool

        static func set(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }

        static func get() -> Bool {
            return UserDefaults.standard.bool(forKey: key)
        }

        static func remove() {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    struct ShowedLoadImagesTooltip: UserDefaultsHandleable {
        typealias ValueType = Bool

        static func set(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }

        static func get() -> Bool {
            return UserDefaults.standard.bool(forKey: key)
        }

        static func remove() {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    struct ShowedDownloadImageTooltip: UserDefaultsHandleable {
        typealias ValueType = Bool

        static func set(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        }

        static func get() -> Bool {
            return UserDefaults.standard.bool(forKey: key)
        }

        static func remove() {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

}
