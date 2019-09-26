//
//  vm_region.swift
//  Mach_VM
//
//  Created by jintao on 2019/8/13.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public func lookAllVMRegions() {
    
    let vm_address = UnsafeMutablePointer<mach_vm_address_t>.allocate(capacity: 1)
    let vm_info = UnsafeMutablePointer<Int32>.allocate(capacity: MemoryLayout<vm_region_basic_info_64>.size/4)
    
    defer {
        vm_address.deinitialize(count: 1)
        vm_address.deallocate()
        
        vm_info.deinitialize(count: MemoryLayout<vm_region_basic_info_64>.size/4)
        vm_info.deallocate()
    }
    var regionCount = 0
    
    while vm_address.pointee <= MACH_VM_MAX_ADDRESS {
        var vm_size: mach_vm_size_t = 0
        var msg_count = mach_msg_type_number_t(VM_REGION_BASIC_INFO_64)
        var mach_port: mach_port_t = 0
        
        let ret = mach_vm_region(mach_task_self_, vm_address, &vm_size, VM_REGION_BASIC_INFO_64, vm_info, &msg_count, &mach_port)
        if ret != KERN_SUCCESS {
            break
        }
        
        print("\n===============vm_region \(regionCount)====================")
        print("vm_address =>:", UnsafeRawPointer(bitPattern: Int(vm_address.pointee))!)
        print("vm_size =>:", vm_size)
        print("vm_pages =>:", UInt(vm_size)/vm_page_size)
        
        let info = UnsafeMutablePointer<vm_region_basic_info_64>(OpaquePointer(vm_info))
        let pro_r = (info.pointee.protection & VM_PROT_READ) == VM_PROT_READ
        let pro_w = (info.pointee.protection & VM_PROT_WRITE) == VM_PROT_WRITE
        let pro_x = (info.pointee.protection & VM_PROT_EXECUTE) == VM_PROT_EXECUTE
        
        var pro_str = pro_r ? "r-" : "*-"
        pro_str += pro_w ? "w-" : "*-"
        pro_str += pro_x ? "x" : "*"
        print("vm_pro =>", pro_str)
        
        vm_address.initialize(to: vm_address.pointee+vm_size)
        regionCount += 1
    }
}

