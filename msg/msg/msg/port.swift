//
//  port.swift
//  Mach_Msg
//
//  Created by jintao on 2019/8/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public func mallocPortWith(context: UInt) -> mach_port_t? {
    var port: mach_port_t = 0
    
    var options = mach_port_options_t()
    options.flags = UInt32(MPO_CONTEXT_AS_GUARD | MPO_QLIMIT | MPO_INSERT_SEND_RIGHT | MPO_STRICT)
    options.mpl.mpl_qlimit = 1
    
    let option_ptr = withUnsafePointer(to: &options, {UnsafeMutablePointer(mutating: $0)})
    
    let ret = mach_port_construct(mach_task_self_, option_ptr, mach_port_context_t(context), &port)
    
    if ret != KERN_SUCCESS {
        return nil
    }
    return port
}

public func freePort(_ port: mach_port_t) {
    mach_port_deallocate(mach_task_self_, port)
}
