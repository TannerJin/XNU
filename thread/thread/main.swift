//
//  main.swift
//  thread
//
//  Created by jintao on 2019/9/20.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

print("Hello, thread!")

if let dbg = getDebugRegister() {
    print(dbg.dr.1)
}

var a = 1

ThreadDo {
    a += 1
}

Thread.sleep(forTimeInterval: 5)

print(a)
