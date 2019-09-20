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

print("end")
