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
        return withUnsafeBytes { (pointer) -> UnsafeRawBufferPointer in
            return pointer
        }
    }
}
