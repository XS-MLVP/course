---
title: 消息驱动
description: 利用消息对电路和软件激励进行解耦
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## 1. 概述
> 消息驱动编程是一种常见的编程范式，基于异步消息传递来实现组件间的通信和协作。在消息驱动编程中，系统中的组件通过发送和接收消息来进行通信。而不是直接调用彼此的函数或方法，在picker中我们可以通过消息驱动对电路和软件激励进行解耦，来摆脱硬件电路中时序的限制

传统的编程模式是线性的，在执行完一段程序后，紧接着就要去执行下一段程序，大致流程为
> 开始 -> 代码块 1-> 代码块 2 -> 代码块 3 -> 结束

使用消息驱动模型后，我们可以自己定义某段代码开始执行的时间(当接收到某段特定的msg后才开始执行)，的流程大致为
>开始 -> 代码块1 -> 代码块2(等待消息)                代码块2(接受消息) -> 代码块3  -> 结束
>                                     消息发送->
消息驱动编程通常涉及以下几个概念和组件：

- **消息**： 消息是在组件之间传递的数据单元。消息可以是简单的数据结构、事件对象，甚至是命令。发送方将消息发送到一个目标，接收方则从目标接收消息。
- **消息队列**： 消息队列是消息传递的中介。它负责存储和管理发送到它的消息，并将消息传递给接收方。消息队列可以基于内存或磁盘，可以是单播（一对一）、多播（一对多）或广播（一对所有）。
- **发布-订阅模式**： 发布-订阅模式是消息驱动编程的一种常见实现方式。在这种模式中，发布者发布消息到一个或多个主题（topic），订阅者订阅感兴趣的主题，并接收相应的消息。
- **消息代理**： 消息代理是处理消息传递的中间件组件。它负责接收和分发消息，管理消息队列，确保消息的可靠传递，以及提供其他消息相关的功能，如消息路由、消息过滤、消息持久化等

## 在 Python 中，实现消息驱动通常可以使用以下几种方式：
- **队列**：Python 的 queue类提供了一个线程安全的队列，可以在多个线程之间传递消息。通过将消息放入队列，然后从队列中取出消息来实现消息的传递和处理。
- **事件驱动**：事件驱动是一种常见的消息驱动模型，其中程序通过监听和响应事件来进行操作。Python 的 asyncio 模块提供了一个事件驱动的框架，可以用于构建异步、非阻塞的程序。
- **发布-订阅模式**：发布-订阅模式是一种消息传递模型，其中消息的发送者（发布者）不直接发送消息给接收者（订阅者），而是通过一个消息中心（或者称为主题）来发布消息，然后订阅者可以订阅感兴趣的主题来接收消息。在 Python 中，可以使用第三方库如 pika 或者 kafka-python 来实现发布-订阅模式。
- **回调函数**：回调函数是一种常见的消息处理方式，其中一个函数被传递给另一个函数，然后在某个特定的事件发生时被调用。在 Python 中，可以使用回调函数来处理异步操作的结果或者事件的发生。

## 在python中使用消息驱动
在python中，我们可以用队列来实现一个简单的消息驱动示例，
- **队列**的作用类似于简化版的**消息代理**，负责存储发送者产生的消息，并等待订阅者从中取走消息。
- **publisher**将消息产生后就将其放入到消息代理中
- **subscriber**会一直监听消息代理中的消息，当收到消息时就转去执行相应的处理消息的操作

```python
import threading
import queue
import time
def publisher(queue, topics):
    for topic in topics:
        message = "Message for topic {}: {}".format(topic, time.ctime())
        queue.put((topic, message))
        print("Published:", message)
        time.sleep(1)

def subscriber(queue, topic):
    while True:
        message = queue.get()
        if message[0] == topic:
            print("Received:", message[1])
        time.sleep(0.5)

msg_queue = queue.Queue()

# 创建发布者线程
publisher_thread = threading.Thread(target=publisher, args=(msg_queue, ['topic1', 'topic2']))
publisher_thread.start()

# 创建订阅者线程
subscriber_thread1 = threading.Thread(target=subscriber, args=(msg_queue, 'topic1'))
subscriber_thread1.start()

subscriber_thread2 = threading.Thread(target=subscriber, args=(msg_queue, 'topic2'))
subscriber_thread2.start()
```
- 发布者每隔1s就依次产生topic1,topic2消息，并将其放入队列中
- 我们创建了两种订阅者subscriber_thread1，subscriber_thread2分别处理topic1,topic2两种消息
- 每隔0.5s,两种订阅者就分别从队列中取出消息，并判断是否为自己的topic,若是，则将消息打印出来
- 若队列为空，则订阅者什么都不做
## Picker中使用消息驱动



## 事件驱动
> 事件驱动严格上属于异步编程中的概念，不过其目的用法与消息驱动有些许类似，因此我们将其放到这一小节来进行讲解。、

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

```python
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

```python
    # Wrong usage: use asyncio.Event
    # set and wait will not occur in the same cycle
    import asyncio
    events = [asyncio.Event() for _ in range(2)]
    create_task(awaited_func(events[0], events[1]))
    create_task(set_event(events[0], events[1]))

    await clk.AStep(5)
```
