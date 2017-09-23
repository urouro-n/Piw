//
//  Functions.swift
//  Pics
//
//  Created by Kenta on 7/13/17.
//  Copyright © 2017 UROURO. All rights reserved.
//

import Foundation

func documentDirectoryURL() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}
