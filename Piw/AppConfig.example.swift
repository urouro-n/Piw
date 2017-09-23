//
//  AppConfig.swift
//  Pics
//
//  Created by Kenta on 9/6/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation
import GoogleMobileAds

struct AppConfig {

    struct AdMob {
        static let applicationId: String = "<# AdMob Application ID #>"
        static let adUnitId: String = "<# AdMob Ad Unit ID #>"
        private static let testDevices: [String] = []

        static var request: GADRequest {
            let r = GADRequest()
            r.testDevices = testDevices
            return r
        }
    }

    struct Slack {
        static let feedbackURL: String = "<# Slack URL #>"
    }

}
