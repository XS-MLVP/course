---
title: 异步编程
description: 利用异步模式简化回调
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 2
---

# 异步编程
### 1.1. 概述  
#### 为什么要引入异步编程？
理想情况下，我们希望我们写的每行代码可以立即执行，没有延迟，然而由于cpu执行指令的时间，以及等待io的时间两个因素，导致我们实际上代码运行的速度要慢的多

> 异步编程通过将某些任务异步执行，程序可以在等待结果时继续执行其他任务，从而减少了阻塞和等待的时间。
> 传统的同步编程方式中，代码会按照顺序依次执行，直到前一个任务完成后才能执行下一个任务，异步编程通过将任务分解为更小的子任务，并且不需要等待前一个任务完成，从而实现并行执行多个任务的效果。

### 1.2. 实现原理
> 在python的asyncio中异步编程的实现基于以下三个核心概念，我们会在下一小节进行更详细的介绍
1. 回调函数（Callback）
回调函数预先注册的回是异步编程的基础。当一个任务完成时，系统会调用调函数来处理任务的结果。通过回调函数的方式，程序可以在等待任务完成的同时继续执行其他任务，提高了程序的并发性。
2. 事件循环（Event Loop）
事件循环是异步编程的核心机制之一。它负责监听各种事件（如用户输入、I/O 操作等），当事件发生时，触发相应的回调函数进行处理。事件循环通过不断地轮询事件队列，实现了非阻塞式的任务处理。
3. 协程
其中协程就是用户自己定义的任务

### 1.3. 常见的异步编程框架和工具
>为了方便开发者进行异步编程，有许多优秀的框架和工具可供选择。以下是一些常见的异步编程框架和工具：

1. Asyncio
Asyncio 是 Python 的一个强大的异步编程框架，提供了高效的协程（Coroutine）支持。它可以用于编写并发性能优秀的网络应用、爬虫程序等。
2. Node. Js
Node. Js 是基于 Chrome V 8 引擎构建的 JavaScript 运行时环境，天生支持非阻塞 I/O 操作。它在 Web 开发领域广泛应用，尤其擅长处理高并发的实时应用。
3. RxJava
RxJava 是一个基于观察者模式和迭代器模式的异步编程库。它为 Java 开发者提供了丰富的操作符和组合方式，简化了异步编程的复杂性。

在python中使用异步，需要使用async和await两个关键字
- **async**：用于定义异步函数，在异步函数中，通常需要包含异步操作
- **await**：用于在异步函数中等待异步操作的完成

下面是一个简单的python代码，来演示async和await关键字的用法
```python
async def my_async_function():
    print("Start async_function and wait some funcion ")
    await some_other_async_function()
    print("End of my_async_function")

```
在python中要想实现异步，通常使用asyncio模块，在下面的例子中，我们定义了一个greet函数，分别打印Hello+name和Goodbye+name,两次打印中间间隔2s.使用asyncio.create创建两个异步任务，并收集执行结果
- asyncio.create_task()：用于创建一个协程任务，并安排其立即执行
- asyncio.gather()：等待多个协程任务的全部完成，并且可以收集执行结果
- asyncio.sleep()：在异步操作中等待一段实际


```python
import asyncio
# 定义一个异步函数
async def greet(name):
    print("Hello, " + name)
    await asyncio.sleep(2)  # 使用异步的sleep函数
    print("Goodbye, " + name)

# 执行异步函数
async def main():
    # 创建任务并发执行
    task1 = asyncio.create_task(greet("verify chip"))
    task2 = asyncio.create_task(greet("picker"))

    # 等待所有任务完成
    await asyncio.gather(task1, task2)

# 运行主函数
if __name__ == "__main__":
    asyncio.run(main())


```
- 首先执行greet("verify chip")，打印Hello,verify chip
- 当遇到await时，转去执行greet("picker"), 打印Hello,picker
- 当要等待的操作执行完以后两个task分别输出Goodbye,verify chip，Goodbye,picker

### 1.4. 异步编程的优势
异步编程具有以下几个显著的优势：
1. 提高响应速度
通过异步编程，程序能够在等待某个任务完成时继续执行其他任务，避免了任务阻塞带来的延迟。这样能够大幅度提高程序的响应速度，提升用户体验。
2. 提升并发性能
异步编程允许程序同时处理多个任务，充分利用计算资源，提升了系统的并发能力。特别是在处理大量 I/O 密集型任务时，异步编程能够更好地发挥优势，降低资源消耗。
3. 简化编程逻辑
异步编程可以避免编写复杂的多线程代码，降低了程序的复杂性和出错的概率。通过简化编程逻辑，开发者能够更专注于业务逻辑的实现。

因此异步编程广泛应用于以下几个领域：
1. Web 开发
在 Web 开发中，异步编程常用于处理网络请求、数据库操作等耗时任务。通过异步方式处理这些任务，可以避免阻塞主线程，保证 Web 服务器的并发性能。
2. 并行计算
异步编程可以帮助实现并行计算，将一个大任务拆分成多个小任务并发执行，提高计算效率。这在科学计算、数据处理等领域非常常见。
3. 消息队列
消息队列是异步编程的经典应用之一。异步消息队列可以实现不同系统之间的解耦和异步通信，提高系统的可扩展性和稳定性。

### picker中异步的用法
例如在picker中，我们可以通过如下方法通过周期来控制代码执行的流程
- await clk.AStep(3)：等待时钟 clk 走 3 个时钟周期。await 关键字使得程序在这里暂停执行，直到时钟走完指定的时钟周期后才继续执行下一行代码。
- await clk.ACondition(lambda: clk.clk == 20)：它等待条件 clk.clk == 20 成立。类似地，程序在这里暂停执行，直到条件成立后才继续执行下一行代码。
```python
async def test_async():
    clk = XClock(lambda a: 0)
    clk.StepRis(lambda c : print("lambda ris: ", c))
    task = create_task(clk.RunStep(30))
    print("test      AStep:", clk.clk)
    await clk.AStep(3)
    print("test ACondition:", clk.clk)
    await clk.ACondition(lambda: clk.clk == 20)
    print("test        cpm:", clk.clk)
    await task
```



### 验证加法器时使用异步

这里继续用在上升沿触发的加法器作为例子，我们对[之前的代码](../callback/#test_ris_adder_with_callback)做了一些微小的变动，把时钟信号的产生和等待时钟周期换成了`picker`提供的异步方法:

>  XClock的`Step(i)`方法会推进`i`个时钟周期，具有两个主要功能：
>
>  1. 生成`i`个时钟周期的时钟信号。
>  2. 等待时钟经过`i`个周期。
>
>  在异步编程中，这两个功能对应着 XClock 提供的两种异步方法：
>
>  - `RunStep(i)`：生成`i`个时钟周期的时钟信号。需要通过`asyncio.create_task`创建任务，并在测试代码的最后使用 `await` 等待其完成。
>  - `AStep(i)`：等待时钟经过`i`个周期。
>
>  如果`RunStep(i)`方法在`AStep(i)`之前完成，整个程序将在`AStep(i)`处被阻塞。

#### 使用异步的测试代码

```python
from UT_RisAdder import *
import random
import asyncio

# 控制字体颜色
FONT_GREEN = "\033[0;32m"  # 绿色
FONT_RED = "\033[0;31m"    # 红色
FONT_COLOR_RESET = "\033[0m"  # 重置颜色

class SimpleRisAdder:
    """
    SimpleRisAdder 类是一个作为参考的加法器类，
    它模拟了我们预期的RisAdder的行为 
    """
    def __init__(self, width) -> None:
        self.WIDTH = width  # 加法器的位宽
        # 端口定义
        self.a = 0  # 输入端口a
        self.b = 0  # 输入端口b
        self.cin = 0  # 输入端口cin
        self.cout = 0  # 输出端口cout
        self.sum = 0   # 输出端口sum

    def step(self, a, b, cin):
        """
        模拟上升沿更新输出: 先用上个周期的输入更新输出，之后再更新输入
        """
        sum = self.a + self.b + self.cin
        self.cout = sum >> self.WIDTH  # 计算进位
        self.sum = sum & ((1 << self.WIDTH) - 1)  # 计算和

        self.a = a  # 更新输入a
        self.b = b  # 更新输入b
        self.cin = cin  # 更新输入cin

# 测试函数，验证加法器的输出是否正确
def test_adder(clk: int, dut: DUTRisAdder, ref: SimpleRisAdder) -> None:
    # 获取加法器的输入和输出
    a = dut.a.value
    b = dut.b.value
    cin = dut.cin.value
    cout = dut.cout.value
    sum = dut.sum.value

    # 检查加法器的输出是否与预期一致
    isEqual = (cout, sum) == (ref.cout, ref.sum)

    # 输出测试结果
    print(f"Cycle: {clk}, Input(a, b, cin) = ({a:x}, {b:x}, {cin:x})")
    print(
        FONT_GREEN + "Pass."  # 输出绿色的“Pass.”，如果测试通过
        if isEqual
        else FONT_RED + f"MisMatch! Expect cout: {ref.cout:x}, sum: {ref.sum:x}." +
        FONT_COLOR_RESET + f"Get cout: {cout:x}, sum: {sum:x}."
    )
    assert isEqual  # 如果测试失败，触发断言异常


# 异步函数，用于运行测试
async def run_test():
    WIDTH = 32  # 设置加法器的位宽
    ref = SimpleRisAdder(WIDTH)  # 创建一个参考加法器
    dut = DUTRisAdder()  # 创建被测试的加法器
    # 绑定时钟信号
    dut.init_clock("clk")
    # dut输入信号置0
    dut.a.value = 0
    dut.b.value = 0
    dut.cin.value = 0
    task = asyncio.create_task(
        dut.runstep(114514 + 1) # 创建一个异步任务，用于模拟时钟信号持续(114514+1)个周期
    )
    await dut.astep(1)  # 等待时钟进入下个周期
    dut.StepRis(test_adder, (dut, ref))  # 注册在时钟上升沿触发的函数
    # 启动测试
    for _ in range(114514):
        # 随机生成输入
        a = random.randint(0, (1 << WIDTH) - 1)
        b = random.randint(0, (1 << WIDTH) - 1)
        cin = random.randint(0, 1)
        ref.step(a, b, cin)  # 更新参考加法器的状态
        dut.a.value = a  # 设置被测试加法器的输入a
        dut.b.value = b  # 设置被测试加法器的输入b
        dut.cin.value = cin  # 设置被测试加法器的输入cin
        await dut.astep(1)  # 等待时钟进入下个周期

    await task  # 等待时钟结束
    dut.finalize()


if __name__ == "__main__":
    asyncio.run(run_test()) # 运行测试
    pass
```

