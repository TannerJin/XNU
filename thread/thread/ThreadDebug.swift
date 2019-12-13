//
//  debugThread.swift
//  thread
//
//  Created by jintao on 2019/12/13.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

#if arch(arm)
public struct DBG {
    static let debug_flag: thread_state_flavor_t = 14
    static let state_count: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<DBG>.size / MemoryLayout<UInt32>.size)
       
    typealias DBG32 = (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32,
                           UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)
       
    var bvr: DBG32
    var bcr: DBG32
    var wvr: DBG32
    var wcr: DBG32
    var mdscr_el1: UInt32
}
#elseif arch(arm64)
public struct DBG {
    static let debug_flag: thread_state_flavor_t = 15
    static let state_count: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<DBG>.size / MemoryLayout<UInt32>.size)
    
    typealias DBG64 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
                        UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
    
    var bvr: DBG64
    var bcr: DBG64
    var wvr: DBG64
    var wcr: DBG64
    var mdscr_el1: UInt64
}
#elseif arch(x86_64)
public struct DBG {
    static let debug_flag: thread_state_flavor_t = 11
    static let state_count: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<DBG>.size / MemoryLayout<UInt32>.size)
       
    typealias DBG64 = (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64,
                           UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)
    
    var dr: DBG64
}
#endif

public func getDebugRegister(_ thread: thread_act_t = mach_thread_self()) -> DBG? {
    let _debug_dbg: thread_state_t = malloc(MemoryLayout<DBG>.size).assumingMemoryBound(to: natural_t.self)
    defer {
        free(_debug_dbg)
    }
    var count: mach_msg_type_number_t = mach_msg_type_number_t(DBG.state_count)
    let ret = thread_get_state(thread, DBG.debug_flag, _debug_dbg, &count)
    
    let debug_dbg = _debug_dbg.withMemoryRebound(to: DBG.self, capacity: 1) { return $0 }
    
    if ret == KERN_SUCCESS {
        return debug_dbg.pointee
    } else {
        print("error", ret)
        return nil
    }
}
