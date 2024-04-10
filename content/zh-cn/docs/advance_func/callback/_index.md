---
title: 回调与Eventloop
description: XXXX。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 1
---
在Python中，回调通常用于异步编程，而Event Loop是异步编程的核心机制之一。在学习回调之前，我们先了解一下evenloop


# Eventloop
> 事件循环中(Event Loop )是管理异步操作的一种机制，它通过轮询注册的事件来处理 I/O 操作。当有异步任务完成时，会触发一个事件。事件循环会从事件队列中获取这个事件，并调用相应的回调函数来处理它。

在 Python 中，可以使用 asyncio 模块来创建和管理事件循环。例如：
```bash hl: title:
import asyncio

async def my_coroutine():
    # do something asynchronously
    await asyncio.sleep(1)
    print('my_coroutine done')

loop = asyncio.get_event_loop()
loop.run_until_complete(my_coroutine())
loop.close()
```

# 回调
> 在Python中，回调是一种常见的编程模式，用于异步或事件驱动编程。回调函数是一个函数对象，它被传递给其他函数作为参数，**以便在完成某个任务时被调用**。

使用回调的例子
- 当使用Python的asyncio库时，可以定义一个回调函数，以便在异步任务完成时执行特定的操作。例如，当异步任务完成时，可以发送一条电子邮件或存储结果
- 在Python的GUI编程中，可以定义回调函数，以便在用户单击按钮或输入文本时执行特定的操作。这些回调函数通常被绑定到GUI元素上，这样当用户与GUI元素交互时，就会自动调用回调函数

在下面的代码中我们定义了一个回调函数 callback，它将在异步任务完成时被调用。我们使用 asyncio. Ensure_future 来创建一个 Future 对象，然后使用 add_done_callback 将回调函数与 Future 对象关联起来。当任务完成时，callback 函数将被调用，并打印任务的返回结果。
```bash hl: title:
import asyncio

def callback(future):
    print("Task completed: {}".format(future.result()))

async def coroutine():
    print("Start coroutine...")
    await asyncio.sleep(1)
    print("Coroutine completed.")
    return "Coroutine result."

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    future = asyncio.ensure_future(coroutine())
    future.add_done_callback(callback)
    loop.run_until_complete(future)
    loop.close()


```

