//
//  main.swift
//  thread
//
//  Created by jintao on 2019/9/20.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

print("Hello, thread!")

var a = 1

ThreadDo {
    a += 1
}

Thread.sleep(forTimeInterval: 1)

print(a)
