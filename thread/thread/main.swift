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

// 由于block执行，编译会生成调用pthread的函数，但目前并没有使用pthread，顾会闪退
// 该线程的gs寄存器加偏移会储存线程的pthread结构地址
// 而pthread结构内部储存tsd数据
ThreadDo {
    a += 1
}

Thread.sleep(forTimeInterval: 1)

print(a)
