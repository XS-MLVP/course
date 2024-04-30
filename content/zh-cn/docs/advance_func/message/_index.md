---
title: 消息驱动
description: 利用消息对电路和软件激励进行解耦
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## 1. 概述
消息驱动编程是一种编程范式，它依赖于异步消息传递以促进组件间的通信和协作。在这种模式下，系统的各个组件不是通过直接调用对方的函数或方法，而是通过发送和接收消息来交流。例如，在picker环境中，我们可以利用消息驱动的方法将电路的行为和软件的激励相解耦，这样就可以**避免受到硬件电路时序限制的束缚**。
在硬件电路测试中，硬件时序指的是电路中各个元件操作的顺序和时间间隔，这对于电路的正确运行至关重要。软件激励则是指用软件生成的一系列动作或信号，用以模拟外部事件对电路的影响，以测试电路的反应。将硬件时序与软件激励解耦是必要的，因为这样可以使得测试过程更加灵活和高效。这种解耦还有助于**在不同的环境中重用软件激励**，提高测试资源的利用率。总之，使用消息驱动来解耦硬件时序和软件激励可以**提升测试的质量和可维护性**，同时**降低复杂性**。  

![消息驱动](message.svg)  

消息驱动编程通常涉及以下几个概念和组件：

- **消息**： 消息是在组件之间传递的数据单元。消息可以是简单的数据结构、事件对象，甚至是命令。发送方将消息发送到一个目标，接收方则从目标接收消息。
- **消息队列**： 消息队列是消息传递的中介。它负责存储和管理发送到它的消息，并将消息传递给接收方。消息队列可以基于内存或磁盘，可以是单播（一对一）、多播（一对多）或广播（一对所有）。
- **发布-订阅模式**： 发布-订阅模式是消息驱动编程的一种常见实现方式。在这种模式中，发布者发布消息到一个或多个主题（topic），订阅者订阅感兴趣的主题，并接收相应的消息。
- **消息代理**： 消息代理是处理消息传递的中间件组件。它负责接收和分发消息，管理消息队列，确保消息的可靠传递，以及提供其他消息相关的功能，如消息路由、消息过滤、消息持久化等

## 使用Pub/Sub模式来实现消息驱动
发布/订阅模式是一种在软件架构中常见的消息通信方式。在这个模式中，发布者不直接将消息发送给特定的接收者，而是发布（发送）到一个中间层，即消息代理。订阅者通过订阅感兴趣的消息类型或主题，来表明他们希望接收哪些消息。消息代理的职责是确保所有订阅了特定主题的客户端都能收到相应的消息。
这种模式的一个关键特点是发布者和订阅者之间的解耦。他们不需要知道对方的存在，也不需要直接通信。这提高了系统的灵活性和可扩展性，因为可以独立地添加或移除发布者和订阅者，而不会影响系统的其他部分。

- 使用 Python 的内置队列模块实现的基本发布/订阅模型：  
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

通过上述过程，软件的请求（激励）和硬件的响应（时序）被有效地解耦。软件可以自由地发送请求，而硬件则在适当的时序下处理这些请求，生成响应。这样的分离确保了软件的开发和测试可以与硬件的具体行为相独立，极大提升了开发效率和系统的可扩展性。为了避免每次都手动编写代码，我们提供了一个名为[MLVP框架](https://github.com/XS-MLVP/mlvp)的资源，它包含了一系列现成的消息驱动方法。
