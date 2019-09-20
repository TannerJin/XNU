//
//  Process.swift
//  cpu
//
//  Created by jintao on 2019/9/20.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// root to do
func closeCPU() {
    var processor: processor_array_t?
    var core_count: mach_msg_type_number_t = 0
    
    let ret = host_processors(mach_host_self(), &processor, &core_count)
    
    if ret == KERN_SUCCESS {
        for i in 0..<Int(core_count) {
            processor_exit(processor!.advanced(by: i).pointee)
        }
    } else {
        print(ret)
    }
}

// root to do
func reboot() {
    let ret2 = host_reboot(mach_host_self(), 0)
    
    if ret2 == KERN_SUCCESS {
        print("reboot cpu core success")
    } else {
        print(ret2)
    }
}
