---
title: 事件驱动
description: 利用事件对电路和软件激励进行解耦
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## 1. 概述
> Python中的事件驱动编程是一种常见的编程范式，通常用于处理异步事件和响应用户输入等交互式任务。事件驱动编程的特点是包含一个事件循环，当事件发生时使用回调机制来触发相应的处理，

传统的编程模式是线性的，大致流程为
> 开始 -> 代码块 1-> 代码块 2 -> 代码块 3 -> 结束

使用事件驱动模型后的流程大致为
>开始 -> 初始化 -> 等待                      执行操作 -> 结束
>                          事件发生->


事件驱动编程通常涉及以下几个重要的概念
1. **事件**：事件是系统内部或外部的发生的动作或信号，如用户输入、网络消息、定时器超时等。在事件驱动编程中，程序通常通过监听和响应事件来执行相应的操作。
2. **事件循环**：事件循环是一个在程序执行期间不断运行的主循环，用于接收、分发和处理事件。在 Python 中，`asyncio` 模块提供了一个事件循环框架，用于编写异步事件驱动的程序。
3. **事件处理器**：事件处理器是用于处理特定类型事件的函数或方法。当事件发生时，事件处理器会被调用来执行相应的操作。
4. **回调函数**：回调函数是一种特殊的事件处理器，它在特定事件发生时被异步调用。通常，回调函数被注册到事件处理器中，以便在事件发生时被调用。
## 2. 基本用法 
> 在 Python 中，asyncio. Event 是一个用于协调异步任务之间的状态同步的对象。它可以在多个异步任务之间设置和清除信号，并且可以用于实现等待和通知的模式。

asyncio.Event 的一些常用方法和属性：
- set()：将事件设置为"已发生"状态，唤醒所有正在等待该事件的任务。
- clear()：将事件设置为"未发生"状态，阻止所有后续的等待任务继续。
- is_set()：返回事件的当前状态（已发生或未发生）。
- wait()：等待事件发生。如果事件已经发生，立即返回；否则阻塞当前任务，直到事件被设置为已发生。

在这个示例中，我们创建了两个任务 wait 1 和 wait 2，并且它们都在等待事件 event 的发生。main 函数在执行wait 1 和wait 2 后会在两秒后设置事件 event。当事件被设置后，所有等待它的任务都将被唤醒，继续执行后续的操作。
- main 函数执行wait 1,waiit 2, 打印 `wait 1 waiting for event` 和 `wait2 waiting for event`，
- wait 1,wait 2 等待event 发生
- 2s main 函数设置event 并打印 `setting event `
- wait 1,wait 2 打印 `wait 1 triggered `，` wait 2 triggered `

```
def set_event():
    print('setting event ')
    event.set()
 
async def wait1():
    print('wait1 waiting for event')
    await event.wait()
    print('wait1 triggered')
 
 
async def wait2(event):
    print('wait2 waiting for event')
    await event.wait()
    print('wait2 triggered')
 
async def main(loop):
	event = asyncio.Event()
    asyncio.create_task(wait1())
    asyncio.create_task(wait2())
	await asyncio.sleep(2)
	set_event(event)
```

## 3. picker 中使用事件驱动
在picker 使用事件驱动和上一小节的用法的用法类似，例如在下面这段代码中，定义两个函数 awaited_func 和 set_event，两个事件event 1,event 2，在执行时
- 创建event 1,event 2
- 调用awaited_func, 此时需要等待event 事件的发生
- 调用 set_event，等待 2s 后，set event 发生，打印 `event has been set`, 并等待event 2
- awaited_func 等待event 发生后打印 `event has been waited`，set event 2 发生
- envent 2 发生后set_event 打印 `event2 has been waited` 


```bash hl: title:
async def test_async_event():
    print("test_async_event")
    clk = XClock(lambda a: 0)
    clk.StepRis(lambda c : print("lambda ris: ", c))
    task = create_task(clk.RunStep(30))

    async def awaited_func(event, event2):
        await event.wait()
        print("event has been waited")
        event2.set()
        print("event2 has been set")

    async def set_event(event, event2):
        await clk.AStep(2)
        event.set()
        print("event has been set")
        await event2.wait()
        print("event2 has been waited")


    # Right usage: use Event in xspcomm
    # All set and wait will occur in the same cycle
    events = [Event() for _ in range(2)]
    create_task(awaited_func(events[0], events[1]))
    create_task(set_event(events[0], events[1]))

    await task

```

注：在picker中不能使用asyncio.Event() 创建Event

```
    # Wrong usage: use asyncio.Event
    # set and wait will not occur in the same cycle
    import asyncio
    events = [asyncio.Event() for _ in range(2)]
    create_task(awaited_func(events[0], events[1]))
    create_task(set_event(events[0], events[1]))

    await clk.AStep(5)
```