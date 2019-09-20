//
//  ThreadCreate.swift
//  Mach_Schedule
//
//  Created by jintao on 2019/9/9.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public typealias SwiftMethod = @convention(thin) () -> ()

public func ThreadDo(block: @escaping SwiftMethod) {
    
    // --0-- 创建一个内核线程对象(目前没有上下文，没有函数栈，线程在等待队列中)
    var thread: thread_act_t = 0
    let ret0 = thread_create(mach_task_self_, &thread)
    if ret0 != KERN_SUCCESS {
        print("0 ==>: 内核线程创建失败")
        return
    }
    
    // --1-- 创建线程栈
    var stack_size: vm_size_t = vm_page_size * 8
    var stack_address: vm_address_t = 0
    let ret1 = vm_allocate(mach_task_self_, &stack_address, stack_size, VM_MEMORY_STACK | VM_FLAGS_ANYWHERE)
    let ret1_1 = vm_protect(mach_task_self_, stack_address, stack_size, 1, VM_PROT_READ | VM_PROT_WRITE)
    if ret1 != KERN_SUCCESS || ret1_1 != KERN_SUCCESS {
        print("1 ==>: 线程栈创建失败")
        return
    }
    
    // --2-- 上下文(寄存器) 赋值
    // 32位寄存器 natural_t: uint32; 两个natural_t表示一个64位寄存器
    var state_32: thread_state_t = UnsafeMutablePointer<natural_t>.allocate(capacity: Int(THREAD_STATE_MAX))
    defer {
        state_32.deallocate()
    }
    
    // 先将当前线程一些其他的寄存器赋值给新的线程
    var state64_count = mach_msg_type_number_t(THREAD_STATE_MAX)
    let ret2 = thread_get_state(mach_thread_self(), x86_THREAD_STATE64, state_32, &state64_count)
    if ret2 != KERN_SUCCESS {
        print("2.0: ==> 线程上下文获取失败", ret2)
        return
    }
    
    // 设置寄存器(上下文)
    // xnu => _STRUCT_X86_THREAD_STATE64
    let state_64 = UnsafeMutablePointer<UInt64>(OpaquePointer(state_32))
    
                                                                   // 64 (32 bits)
    state_64[0] = 0x0                                              // rax(eax) #函数返回值        (函数内部可用作累加寄存器)
    
    state_64[4] = 0x0                                              // rdi(edi) #参数1
    state_64[5] = 0x0                                              // rsi(esi) #参数2
    state_64[3] = 0x0                                              // rdx(edx) #参数3            (函数内部可用作I/O端口地址寄存器)
    state_64[2] = 0x0                                              // rcx(ecx) #参数4            (函数内部可用作计数寄存器)
    state_64[8] = 0x0                                              // r8(r8d)  #参数5
    state_64[9] = 0x0                                              // r9(r9d)  #参数6
    
    state_64[1] = state_64[1]                                      // rbx(ebx)  #数据
    state_64[10] = 0x0                                             // r10(r10d) #数据
    state_64[11] = 0x0                                             // r11(r11d) #数据
    state_64[12] = 0x0                                             // r12(r12d) #数据
    state_64[13] = 0x0                                             // r13(r13d) #数据
    state_64[14] = 0x0                                             // r14(r14d) #数据
    state_64[15] = 0x0                                             // r15(r15d) #数据

    state_64[6] = UInt64(stack_address+stack_size - 0x8*4)         // rbp(ebp)  #栈帧
    state_64[7] = UInt64(stack_address+stack_size - 0x8*7)         // rsp(esp)  #栈顶
    
    state_64[17] = 0x0                                             // rflags #标志寄存器 (bits)
    
    state_64[18] = state_64[18]                                    // cs #代码段寄存器
    state_64[19] = state_64[19]                                    // fs #数据段寄存器
    state_64[20] = state_64[20]                                    // gs #全局段寄存器      （可以实现栈上金丝雀，内核的tsd功能）
    
    state_64[16] = 0x0                                             // rip #pc
    
    // 设置TSD(线程私有数据) ???
    
    // 设置线程函数开始地址
    let _func_begin: ThreadStart = thread_start
    state_64[16] = UInt64(UInt(bitPattern: unsafeBitCast(_func_begin, to: UnsafeRawPointer.self)))   // rip #pc

    // 设置函数参数
    state_64[4] = UInt64(thread)
    state_64[5] = UInt64(stack_address)
    state_64[3] = UInt64(stack_size)
    state_64[2] = UInt64(UInt(bitPattern: unsafeBitCast(block, to: UnsafeRawPointer.self)))
    
    
    let ret2_1 = thread_set_state(thread, x86_THREAD_STATE64, state_32, state64_count)
    if ret2_1 != KERN_SUCCESS {
        print("2.1: ==> 线程上下文设置失败", ret2_1)
        return
    }
    
    // --3-- 加入到调度队列中，开始获取时间片, 执行thread_start方法
    let ret3 = thread_resume(thread)
    if ret3 != KERN_SUCCESS {
        print("2: ==> 线程加入到调度队列失败")
        return
    }
}


typealias ThreadStart = @convention(thin) (thread_t, vm_address_t, vm_size_t, SwiftMethod)->Void

private func thread_start(thread: thread_t, stack: vm_address_t, size: vm_size_t, _func: SwiftMethod) {
    // 开始执行函数
    _func()
    
    // wait to resolve gs register
    
    // 释放线程栈
    vm_deallocate(mach_task_self_, stack, size)
    
    // 结束线程调度
    thread_terminate(thread)
}


// thread_assign  #将线程绑定到某个多核CPU的某核中调度
