//
//  message.swift
//  Mach_Msg
//
//  Created by jintao on 2019/8/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

private let mach_port_null = mach_port_t(MACH_PORT_NULL)

public struct message {
    fileprivate var base: mach_msg_base_t
    fileprivate var ool: mach_msg_ool_descriptor_t
    
    public var msgId: Int {
        return Int(base.header.msgh_id)
    }
    
    public var data: Data? {
        guard let baseAddress = ool.address else { return nil }
        let bufferPointer = UnsafeMutableBufferPointer(start: baseAddress.assumingMemoryBound(to: UInt8.self), count: Int(ool.size))
        return Data(buffer: bufferPointer)
    }
}

private func mach_msgh_bits(remote: mach_msg_bits_t, local: mach_msg_bits_t) -> mach_msg_bits_t {
    return ((remote) | ((local) << 8))
}

private func creatMessage(remotePort: mach_port_t, replyPort: mach_port_t, msgId: mach_msg_id_t, data: Data) -> message {
    var msg_header = mach_msg_header_t()
    msg_header.msgh_id = msgId
    msg_header.msgh_size = mach_msg_size_t(MemoryLayout<message>.size)
    msg_header.msgh_remote_port = remotePort
    msg_header.msgh_local_port = replyPort
    let remoteBits = mach_msg_bits_t(MACH_MSG_TYPE_COPY_SEND)
    let localBits = mach_msg_bits_t(replyPort == mach_port_null ? 0:MACH_MSG_TYPE_MAKE_SEND_ONCE)
    msg_header.msgh_bits = mach_msgh_bits(remote: remoteBits, local: localBits)
    msg_header.msgh_bits |= MACH_MSGH_BITS_COMPLEX
    
    var msg_body = mach_msg_body_t()
    msg_body.msgh_descriptor_count = 1
    
    let msg_base = mach_msg_base_t(header: msg_header, body: msg_body)
    
    var msg_ool = mach_msg_ool_descriptor_t()
    let _data = data
    msg_ool.address = UnsafeMutableRawPointer(mutating: _data.valuePointer.baseAddress)
    msg_ool.size = mach_msg_size_t(data.count)
    msg_ool.copy = mach_msg_copy_options_t(MACH_MSG_VIRTUAL_COPY)       // shared vm space(copy on write)
    msg_ool.deallocate = 0
    msg_ool.type = mach_msg_descriptor_type_t(MACH_MSG_OOL_DESCRIPTOR)
    
    return message(base: msg_base, ool: msg_ool)
}

private func sendEmtyMessageTo(port remotePort: mach_port_t, msg_id: mach_msg_id_t, timeout: mach_msg_timeout_t, localPort: mach_port_t) -> mach_msg_return_t {
    var header = mach_msg_header_t()
    header.msgh_bits = mach_msgh_bits(remote: mach_msg_bits_t(MACH_MSG_TYPE_COPY_SEND), local: 0);
    header.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size);
    header.msgh_remote_port = remotePort;
    header.msgh_local_port = localPort;
    header.msgh_id = msg_id;
    let result = mach_msg_send(&header)
    return result;
}

public func sendMessageTo(port remotePort: mach_port_t, msg_id: mach_msg_id_t, msg: Data?, timeout: mach_msg_timeout_t, localPort: mach_port_t? = nil) -> mach_msg_return_t {
    let _localPort = localPort == nil ? mach_port_null:localPort!

    if let msg_data = msg {
        var send_msg = creatMessage(remotePort: remotePort, replyPort: _localPort, msgId: msg_id, data: msg_data)
        let send_msg_addr = withUnsafePointer(to: &send_msg) { (pointer) -> UnsafeMutablePointer<mach_msg_header_t> in
            return UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: mach_msg_header_t.self)
        }
        let ret = mach_msg_send(send_msg_addr)
        return ret
    } else {
        return sendEmtyMessageTo(port: remotePort, msg_id: msg_id, timeout: timeout, localPort: _localPort)
    }
}

public typealias ReceiveMsg = (return: mach_msg_return_t, msg: message?)

public func receiveMessageAt(port replyPort: mach_port_t, from remote_port: mach_port_t? = nil, timeout: mach_msg_timeout_t) -> ReceiveMsg {
    var recv_msg = mach_msg_header_t()
    recv_msg.msgh_remote_port = remote_port == nil ? mach_port_null : remote_port!
    recv_msg.msgh_local_port = replyPort
    recv_msg.msgh_bits = 0
    let msg_size = mach_msg_size_t(MemoryLayout<message>.size) + 8
    recv_msg.msgh_size = msg_size
    
    let msg_body = mach_msg_body_t()
    let msg_base = mach_msg_base_t(header: recv_msg, body: msg_body)
    
    let msg_ool = mach_msg_ool_descriptor_t()
    var emtyMessage = message(base: msg_base, ool: msg_ool)
    
    let recv_msg_addr = withUnsafePointer(to: &emtyMessage) { (pointer) -> UnsafeMutablePointer<mach_msg_header_t> in
        return UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: mach_msg_header_t.self)
    }

    let ret = mach_msg_receive(recv_msg_addr)
    
    var msg: message?
    if ret == KERN_SUCCESS {
        msg = emtyMessage
    }
    
    return (ret, msg)
}
