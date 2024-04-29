---
title: 消息驱动
description: 利用消息对电路和软件激励进行解耦
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## 1. 概述
> 消息驱动编程是一种常见的编程范式，基于异步消息传递来实现组件间的通信和协作。在消息驱动编程中，系统中的组件通过发送和接收消息来进行通信。而不是直接调用彼此的函数或方法。在picker中我们可以通过消息驱动对电路和软件激励进行解耦，来摆脱硬件电路中时序的限制

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
- **队列Queue**：Python 的 queue类提供了一个线程安全的队列，可以在多个线程之间传递消息。通过将消息放入队列，然后从队列中取出消息来实现消息的传递和处理。
- **事件驱动**：事件驱动是一种常见的消息驱动模型，其中程序通过监听和响应事件来进行操作。Python 的 asyncio 模块提供了一个事件驱动的框架，可以用于构建异步、非阻塞的程序。
- **发布-订阅模式**：发布-订阅模式是一种消息传递模型，其中消息的发送者（发布者）不直接发送消息给接收者（订阅者），而是通过一个消息中心（或者称为主题）来发布消息，然后订阅者可以订阅感兴趣的主题来接收消息。在 Python 中，可以使用第三方库如 pika 或者 kafka-python 来实现发布-订阅模式。
- **回调函数**：回调函数是一种常见的消息处理方式，其中一个函数被传递给另一个函数，然后在某个特定的事件发生时被调用。在 Python 中，可以使用回调函数来处理异步操作的结果或者事件的发生。

## 使用Pub/Sub模式来实现消息驱动
>发布/订阅模式是一种在软件架构中常见的消息通信方式。在这个模式中，发布者不直接将消息发送给特定的接收者，而是发布（发送）到一个中间层，即消息代理。订阅者通过订阅感兴趣的消息类型或主题，来表明他们希望接收哪些消息。消息代理的职责是确保所有订阅了特定主题的客户端都能收到相应的消息。
这种模式的一个关键特点是发布者和订阅者之间的解耦。他们不需要知道对方的存在，也不需要直接通信。这提高了系统的灵活性和可扩展性，因为可以独立地添加或移除发布者和订阅者，而不会影响系统的其他部分。

1. 使用 Python 的内置队列模块实现的基本发布/订阅模型：  
- 此处 Publisher 类具有消息队列和订阅者列表。使用发布方法发布消息时，会将其添加到队列中，并通过调用其接收方法传递到所有订阅的客户端。Subscriber 类具有一个 receive 方法，该方法仅打印收到的消息。  
    ```python
    import queue
    # 发布者类
    class Publisher:
        def __init__(self):
            # 初始化消息队列和订阅者列表
            self.message_queue = queue.Queue()
            self.subscribers = []

        def subscribe(self, subscriber):
            # 添加一个新的订阅者到订阅者列表
            self.subscribers.append(subscriber)

        def publish(self, message):
            # 将消息放入队列并通知所有订阅者
            self.message_queue.put(message)
            for subscriber in self.subscribers:
                # 调用订阅者的接收方法
                subscriber.receive(message)

    # 订阅者类
    class Subscriber:
        def __init__(self, name):
            # 初始化订阅者的名称
            self.name = name

        def receive(self, message):
            # 打印接收到的消息
            print(f"{self.name} received message: {message}")

    # 创建一个发布者实例
    publisher = Publisher()

    # 创建两个订阅者实例
    subscriber_1 = Subscriber("Subscriber 1")
    subscriber_2 = Subscriber("Subscriber 2")

    # 将订阅者添加到发布者的订阅者列表中
    publisher.subscribe(subscriber_1)
    publisher.subscribe(subscriber_2)

    # 发布者发布一条消息
    publisher.publish("Hello World") 
    ``` 
2. 使用 Python 的线程模块实现的发布/订阅模型：  
- 在此示例中，Publisher 类有一个订阅者字典，其中键是主题，值是订阅者列表。subscribe 方法将订阅服务器添加到指定主题的列表中。publish 方法检查指定主题是否有任何订阅者，如果有，则设置事件并存储每个订阅者的消息。Subscriber 类和 receive 方法与前面的示例相同。
    ```python
    import threading

    # 发布者类
    class Publisher:
        def __init__(self):
            # 初始化订阅者字典，按主题组织
            self.subscribers = {}

        def subscribe(self, subscriber, topic):
            # 订阅方法，将订阅者添加到特定主题
            if topic not in self.subscribers:
                self.subscribers[topic] = []
            self.subscribers[topic].append(subscriber)

        def publish(self, message, topic):
            # 发布方法，向特定主题的所有订阅者发送消息
            if topic in self.subscribers:
                for subscriber in self.subscribers[topic]:
                    # 设置事件标志，通知订阅者有新消息
                    subscriber.event.set()
                    # 将消息传递给订阅者
                    subscriber.message = message

    # 订阅者类
    class Subscriber:
        def __init__(self, name):
            # 初始化订阅者名称和事件标志
            self.name = name
            self.event = threading.Event()
            self.message = None

        def receive(self):
            # 接收方法，等待事件标志被设置
            self.event.wait()
            # 打印接收到的消息
            print(f"{self.name} received message: {self.message}")
            # 清除事件标志，准备接收下一个消息
            self.event.clear()

    # 创建发布者实例
    publisher = Publisher()

    # 创建三个订阅者实例
    subscriber_1 = Subscriber("Subscriber 1")
    subscriber_2 = Subscriber("Subscriber 2")
    subscriber_3 = Subscriber("Subscriber 3")

    # 将订阅者根据主题订阅到发布者
    publisher.subscribe(subscriber_1, "sports")
    publisher.subscribe(subscriber_2, "entertainment")
    publisher.subscribe(subscriber_3, "sports")

    # 发布者发布一条属于'sports'主题的消息
    publisher.publish("Soccer match result", "sports")

    # 订阅者1接收并处理消息
    subscriber_1.receive()
    ``` 

## 使用消息驱动进行验证
下面我们将以果壳cache的验证过程为例，来介绍消息驱动在验证中的使用。
[完整代码](https://github.com/yzcccccccccc/XS-MLVP-NutShellCache/tree/master)参见。  
```python
from util.simplebus import SimpleBusWrapper
from tools.colorprint import Color as cl
import xspcomm as xsp
import queue

# 请求消息类，用于封装通信请求的详细信息
class ReqMsg:
    def __init__(self, addr, cmd, user=0x123, size=7, mask=0, data=0):
        self.user = user
        self.size = size
        self.addr = addr
        self.cmd = cmd
        self.mask = mask
        self.data = data
    
    def display(self):
        print(f"[REQ MSG] user {self.user:x}, size {self.size}, addr 0x{self.addr:x} " 
            f"cmd 0x{self.cmd:x}, mask {self.mask:b}, data {self.data:x}")

# 缓存包装器类，模拟缓存的行为并与外部总线通信
class CacheWrapper:
    def __init__(self, io_bus: SimpleBusWrapper, clk: xsp.XClock, cache_port: xsp.XPort):
        self.xclk = clk
        # 简单总线包装器，用于与外部通信
        self.io_bus = io_bus
        # 缓存端口，可能用于与外部组件交互
        self.cache_port = cache_port

        # 初始化请求队列，用于存储即将处理的请求消息
        self.req_que = queue.Queue()
        # 初始化响应队列，用于存储处理完的响应消息
        self.resp_que = queue.Queue()
        # 注册硬件时钟上升沿的回调方法，用于处理请求和响应
        self.xclk.StepRis(self.__callback)

    # 发起一个读请求
    def trigger_read_req(self, addr):
        # 将读请求消息放入请求队列，不等待队列锁定
        self.req_que.put_nowait(ReqMsg(addr=addr, cmd=self.io_bus.cmd_read))

    # 发起一个写请求
    def trigger_write_req(self, addr, data, mask):
        # 将写请求消息放入请求队列，不等待队列锁定
        self.req_que.put_nowait(ReqMsg(addr=addr, cmd=self.io_bus.cmd_write, mask=mask, data=data))

    # 接收响应
    def recv(self):
        # 等待响应队列非空，然后取出响应
        while self.resp_que.empty():
            self.xclk.Step(1)
        return self.resp_que.get()

    # 读取数据
    def read(self, addr):
        # 发起读请求，然后等待并返回响应
        self.trigger_read_req(addr)
        return self.recv()

    # 写入数据
    def write(self, addr, data, mask):
        # 发起写请求，然后等待并返回响应
        self.trigger_write_req(addr, data, mask)
        return self.recv()

    # 重置缓存
    def reset(self):
        # 设置复位信号，等待一定时钟周期，然后清除复位信号
        self.cache_port["reset"].value = 1
        self.xclk.Step(100)
        self.cache_port["reset"].value = 0
        self.cache_port["io_flush"].value = 0
        # 等待请求准备就绪信号
        while not self.io_bus.IsReqReady():
            self.xclk.Step(1)

    # 硬件时钟上升沿的回调方法
    def __callback(self, *a, **b):
        # 处理请求
        if self.io_bus.IsReqSend():
            # 如果有请求发送，从请求队列取出一个请求
            self.req_que.get()
        # 检查请求队列是否为空
        if self.req_que.empty():
            # 如果请求队列为空，向io_bus发送无效请求信号
            self.io_bus.ReqUnValid()
        else:
            # 如果请求队列不为空，向io_bus发送有效请求信号
            self.io_bus.ReqSetValid()
            # 取出队首的请求消息
            msg: ReqMsg = self.req_que.queue[0]
            # 根据请求命令类型，执行读或写操作
            if msg.cmd == self.io_bus.cmd_read:
                self.io_bus.ReqReadData(msg.addr)
            if msg.cmd == self.io_bus.cmd_write:
                self.io_bus.ReqWriteData(msg.addr, msg.data, msg.mask)

        # 处理接收
        self.io_bus.port["resp_ready"].value = 1
        # 如果响应有效，从io_bus获取响应数据，并放入响应队列
        if self.io_bus.IsRespValid():
            res = self.io_bus.get_resp_rdata()
            self.resp_que.put_nowait(res)
``` 
1. 封装软件激励：  
- 软件激励首先被封装进ReqMsg对象中，这个对象包含了所有必要的信息，如地址、命令、数据等。此处以果壳cache的验证为例。

2. 使用消息队列存储请求：
- 封装后的请求被放入CacheWrapper类的请求队列req_que中。这个队列作为软件激励的缓冲区，允许软件在任何时刻发送请求，而不必等待硬件的即时响应。

3. 解耦的回调机制：
- 在硬件时钟上升沿，CacheWrapper类的__callback方法被触发。这个方法检查请求队列中是否有待处理的请求，并根据当前的硬件状态决定是否处理这些请求。这是解耦过程中的关键步骤，因为它将软件激励的发送与硬件时序的处理分离开来。

4. 模拟硬件响应：
- 封装后的请求被放入CacheWrapper类的请求队列req_que中。这个队列作为软件激励的缓冲区，允许软件在任何时刻发送请求，而不必等待硬件的即时响应。

5. 软件接收响应：
- 软件可以通过CacheWrapper类的recv方法从响应队列中取出响应。这个过程是同步的，但它允许软件在任何时刻检查响应队列，而不是必须在特定的硬件时序点上。

>通过上述过程，软件的请求（激励）和硬件的响应（时序）被有效地解耦。软件可以自由地发送请求，而硬件则在适当的时序下处理这些请求，生成响应。这种解耦使得软件的开发和测试可以独立于硬件的实际行为，从而提高了开发效率和系统的灵活性。

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
 - 下面我将会用一个简单的例子展示如何在picker中使用事件驱动
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
