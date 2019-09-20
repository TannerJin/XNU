//
//  Data.swift
//  Mach_Msg
//
//  Created by jintao on 2019/8/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public extension Data {
    var valuePointer: UnsafeRawBufferPointer {
        mutating get {
            if self.count <= 14 {
                // Buffer count for 64-bit platforms
                let pointer = withUnsafePointer(to: &self) { UnsafeRawPointer($0) }
                return UnsafeRawBufferPointer(start: pointer, count: self.count)
            } else {
                return self.withUnsafeBytes{ $0 }
            }
        }
    }
}
