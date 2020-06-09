//
//  main.swift
//  vm
//
//  Created by jintao on 2019/9/20.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

print("Hello, mach vm!")

lookAllVMRegions()

// add one vm_region
var addr = UnsafeMutableRawPointer(bitPattern: 0x00000001002dd000)
if let pointer = mmap(addr, 128, PROT_READ|PROT_EXEC,  MAP_ANON | MAP_PRIVATE, -1, 0) {
    print("new mmap: =>", pointer)
    lookAllVMRegions()
}

var _addr: mach_vm_address_t = 0
let ret = mach_vm_map(mach_task_self_, &_addr, 4096, (1 << 21) - 1, VM_FLAGS_ANYWHERE, MEMORY_OBJECT_NULL, 0, 0, VM_PROT_DEFAULT, VM_PROT_READ|VM_PROT_WRITE, VM_INHERIT_DEFAULT)

if ret == KERN_SUCCESS {
    print(_addr)
}
