//
//  main.swift
//  msg
//
//  Created by jintao on 2019/9/20.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

print("Hello, mach msg!")

let pointer = malloc(0x20)
defer {
    free(pointer)
}

guard let localPort = mallocPortWith(context: UInt(bitPattern: pointer!)) else {
    print("allocate port failure")
    exit(0)
}
defer {
    freePort(localPort)
}

print("\nbegin =>:\n")

// Send MSG
Thread.detachNewThread {
    Thread.sleep(forTimeInterval: 1)
    
    // send msg to port at child thread
    let msg_data = "TannerJin Hello Swift!".data(using: .utf8)!
    let ret = sendMessageTo(port: localPort, msg_id: mach_msg_id_t(100), msg: msg_data, timeout: 1)
    if ret != KERN_SUCCESS {
        print("send msg failure", ret)
    }
}

// Receive MSG
// wait receive port msg at main thread
let msgRet = receiveMessageAt(port: localPort, timeout: MACH_MSG_TIMEOUT_NONE)

if msgRet.return != KERN_SUCCESS {
    print("receive msg failure", msgRet)
} else {
    if let msg = msgRet.msg, let strData = msg.data, let recv_str = String(data: strData, encoding: .utf8) {
        print("receive msg success =>:")
        print("msgId: ", msg.msgId)
        print("data: ", recv_str)
    }
}

print("\nend")

