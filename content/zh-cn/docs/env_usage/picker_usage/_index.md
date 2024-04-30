---
title: 基础使用
description: 验证工具的基本使用。
categories: [教程]
tags: [docs]
weight: 1
---

{{% pageinfo %}}
为满足开放验证的环境要求，我们开发了 Picker 工具，用于将 RTL 设计转换为多语言接口，并在此基础上进行验证，我们将会使用 Picker 工具生成的环境作为基础的验证环境。接下来我们将介绍 Picker 工具，及其基础的使用方法。
{{% /pageinfo %}}

## Picker 简介
> `picker`是一个芯片验证辅助工具，其目标是将RTL设计验证模块(.v/.scala/.sv)进行封装，并使用其他编程语言暴露`Pin-Level`的操作，未来计划支持自动化的`Transaction-Level`原语生成。其他编程语言包括 c++ (原生支持), python(已支持), java(待完善), golang(待完善) 等编程语言接口。该辅助工具让用户可以基于现有的软件测试框架，例如pytest, junit，TestNG, go test等，进行芯片UT验证。

基于picker进行验证具有如下**优点**：  
 - 1.**不泄露RTL设计**。经过Picker转换后，原始的设计文件(.v)被转化成了二进制文件(.so)，脱离原始设计文件后，依旧可进行验证，且验证者无法获取RTL源代码。  
 - 2.**减少编译时间**。当DUT(Design Under Test)稳定时，只需要编译一次（打包成so）。  
 - 3.**用户面广**。提供的编程接口多，可覆盖不同语言的开发者（传统IC验证，只用System Verilog）。  
 - 4.**可使用软件生态丰富**。能使用python3, java, golang等生态。  

>目前picker支持以下模拟器：
`verilator`、`synopsys vcs`

**Picker的工作原理**  
`Picker`的主要功能就是将`Verilog`代码转换为C++或者Python代码，以处理器的仿真为例:

![Picker的工作原理](Picker_working_principle.svg)

## Python 模块生成

### 生成模块的过程

在本章节中，我们将介绍如何使用Picker将RTL代码最终导出为Python Module。

- Picker 导出 Python Module 的方式是基于 C++ 的。
    - **Picker 是 代码生成(codegen)工具，它会先生成项目文件，再利用 make 编译出二进制文件。**
    - Picker 首先会利用仿真器将 RTL 代码编译为 C++ Class，并编译为动态库。（见C++步骤详情）
    - 再基于 Swig 工具，利用上一步生成的 C++ 的头文件定义，将动态库导出为 Python Module。
    - 最终将生成的模块导出到目录，并按照需求清理或保留其他中间文件。
    > Swig 是一个用于将 C/C++ 导出为其他高级语言的工具。该工具会解析 C++ 头文件，并生成对应的中间代码。
    > 如果希望详细了解生成过程，请参阅 [Swig 官方文档](http://www.swig.org/Doc4.2/SWIGDocumentation.html)。
    > 如果希望知道 Picker 如何生成 C++ Class，请参阅 [C++](docs/quick-start/multi-lang/cpp)。

- 该这个模块和标准的 Python 模块一样，可以被其他 Python 程序导入并调用，文件结构也与普通 Python 模块无异。

## Python 模块使用

- 参数 `--language python` 或 `-l python` 用于指定生成Python基础库。
- 参数 `--example, -e` 用于生成包含示例项目的可执行文件。
- 参数 `--verbose, -v` 用于保留生成项目时的中间文件。

### DUT

- 以前述的加法器为例，用户需要编写测试用例，即导入上一章节生成的 Python Module，并调用其中的方法，以实现对硬件模块的操作。
目录结构为：
    ```shell
        picker_out_adder
        |-- UT_Adder                # Picker 工具生成的项目
        |   |-- Adder.fst.hier
        |   |-- _UT_Adder.so
        |   |-- __init__.py
        |   |-- libDPIAdder.a
        |   |-- libUTAdder.so
        |   `-- libUT_Adder.py
        `-- example.py              # 用户需要编写的代码
    ```
- 用户使用 Python 编写测试用例，即导入上述生成的 Python Module，并调用其中的方法，以实现对硬件模块的操作。

    ```python
    from UT_Adder import *          # 从python软件包里导入模块
    import random

    if __name__ == "__main__":
        dut = DUTAdder() # 初始化 DUT
        # dut.init_clock("clk") # 如果模块有时钟，需要初始化时钟，绑定时钟信号到模拟器的时钟，以自动驱动
        # reset
        # dut.reset.value = 1
        # dut.Step(1) # 该步进行了初始化赋值操作
        # dut.reset.value = 0 # 设置完成后需要记得复位原信号！
        # 以加法器为例，对信号的操作
        dut.a.value = 1             #对dut的输入信号赋值，需要用到.value
        dut.b.value = 2
        dut.cin.value = 0
        dut.Step(1)                 #更新信号
        print(f"sum = {dut.sum.value}, cout = {dut.cout.value}") #读取dut的输出信号，需要用到.value
        # 
        dut.finalize()              # 清空对象，并完成覆盖率和波形文件的输出工作（写入到文件）
    ```


> DUT类有三种基本数据类型：XData、XPort、XClock,在下面我们会逐一的讲解他们的使用方法
### XDATA
XData 电路的IO接口数据（与电路引脚绑定），通过 DPI 读写电路的IO接口。支持 0，1，Z，X 四种状态写入与读取。  
**XData 主要方法：** 
- 初始化：
    ```python
    # 初始化的步骤picker会为我们自动完成，此处只是介绍下用法
    # 初始化使用XData，参数为位宽和数据方向(XData.In,XData.Out,XData.InOut)
    a = XData(32,XData.In)
    a.ReInit(16,XData.In)  #ReInit方法可以重新初始化XData实例
    # 绑定DPI，以加法器为例，参数为C函数
    self.a.BindDPIRW(DPIRa, DPIWa)
    self.b.BindDPIRW(DPIRb, DPIWb)
    self.cin.BindDPIRW(DPIRcin, DPIWcin)
    self.sum.BindDPIRW(DPIRsum, DPIWsum)
    self.cout.BindDPIRW(DPIRcout, DPIWcout)
    ``` 
- 访问信号：
    ```python
    # 使用.value可以进行访问，有多种赋值方法
    a.value = 12345             # 十进制赋值
    a.value = 0b11011           # 二进制赋值
    a.value = 0o12345           # 八进制赋值
    a.value = 0x12345           # 十六进制赋值
    a.value = '::ffff'          # 字符串赋值ASCII码
    d = XData(32,XData.In)      # 同类型赋值
    d = a
    a.value = 0xffffffff
    # 配合ctype库使用
    a.W();                      # 转 uint32
    a.U();                      # 转 uint64
    a.S();                      # 转 int64
    a.B();                      # 转 bool
    a.String()                  # 转 string

    #a.value支持使用[]按下标访问，下标从0开始为最低位
    a[31] = 0                   # a.value = 0x7ffffffff
    a.value = "x"               # 赋值高阻态
    # 输出高阻和不定态的时候需要用字符串输出
    # print(f"expected x, actual {a.String()}")
    # a.value = "000000??"
    # 000000??表示不定态和高阻态，出现这种结果的时候电路一般是出问题了
    a.value = "z"               # 赋值不定态
    # a.value = "000000??"

    ``` 

### XPORT
- 我们对少量的XData引脚操作的时候直接使用XData比较清晰直观，但是有多个XData的时候进行批量管理不是很方便，XPort是XData的封装，可对多个XData进行操作，我们也提供了一些批量管理方法

- 初始化与添加引脚：
    ```python
    port = XPort("p") #创建XPort实例
    ``` 
- 主要方法：
    ```python
    # 使用Add方法添加引脚
    port.Add("a",a)             # 添加引脚
    port.Add("b",b)             # 添加引脚

    #使用[]访问引脚
    port["b"]
    # 使用[].value可以访问引脚的值
    port["b"].value = 1

    #返回引脚个数
    port.PortCount()

    # Connect方法连接两个XPort实例
    port_1 = XPort("p1")        # 创建XPort实例
    port_1.Add("a",a)           # 添加引脚
    port_1.Add("b",b)           # 添加引脚
    port.Connect(port_1)

    # Flip方法翻转引脚输入输出方式
    port.Flip()

    # AsBiIo方法将引脚方向转换为双向
    a.AsBiIO()

    # 通过DPI刷入所有上升沿引脚的值
    port.WriteOnRise()
    # 通过DPI刷入所有下降沿引脚的值
    port.WriteOnFall()

    # 使用ReadFresh刷新读取引脚的值
    port.ReadFresh(XData.In)

    # 使用SetZero方法将引脚的值设为0
    port.SetZero() 
    print(f"expected 0, actual {port['a'].value}")
    ``` 
### XClock
- XClock 基于XPort，对电路的时钟封装，用于驱动电路
XClock 主要接口与成员变量：
- 初始化与添加引脚：
    ```python
    clk = XClock(lambda a: 1 if print("lambda stp: ", a) else 0)  #参数stepfunc 为 DUT后端提供的电路推进方法，例如 verilaor 的 step_eval 等
    ``` 
- 主要方法：
    ```python
    # 使用Add方法添加引脚
    clk.Add(XData)              # 添加clk引脚
    clk.Add(XPort)              # 添加Port
    
    # 更新状态
    clk.Step(1)                 # 参数为UInt i，表示前进i步

    #复位
    clk.Reset()

    # 添加上升沿回调，参数为回调函数
    clk.StepRis(lambda c, x, y: print("lambda ris: ", c, x, y), (1, 2))
    # 添加下降沿回调，参数为回调函数
    clk.StepFal(lambda c, x, y: print("lambda fal: ", c, x, y), (3, 4))
    ``` 

虽然在

### Async & Event

**时钟事件 (Event)**

生成的 Python 模块中提供了基础的异步功能，以方便用户编写异步测试用例。

具体地，我们在每一个由 Picker 生成的 Python 模块中设置了一个时钟事件（Event），并围绕这一事件提供了异步的接口。该时钟事件可通过实例化对象的 `event` 属性获取，例如 `dut.event`。

同时，该事件也可以从 dut 的每一个接口中获取。这是因为我们将接口定义为了 `XPin`，其中包含了该接口的 `xdata` 和全局时钟事件 `event`，因此可以通过 `dut.signal_1.event` 这样的方式获取到全局的时钟事件。这有助于我们在仅能访问到一个接口的情况下，获取到该接口对应的全局时钟信号。

**使用异步**

上文介绍的时钟事件是异步功能的核心，在这里我们将介绍如何使用时钟事件来实现异步功能。

首先我们需要创建一个协程(Coroutine)对象，并将其加入到事件循环(EventLoop)中，以实现全局时钟的驱动，方法如下：

```python
asyncio.create_task(dut.xclock.RunStep(10))
```

这将会使得时钟在“后台”被驱动 10 次，而不会阻塞当前正在执行的代码。但是其他的协程如何得知时钟被驱动了一次呢？这就要用到时钟事件了。在 `RunStep` 函数中，每驱动一次时钟，都会对时钟事件进行一次触发，其他协程可以通过监听时钟事件来得知时钟被驱动了。例如：

```python
async def other_task():
	for _ in range(10):
		await dut.xclock.AStep(1)
		print(f"Clock has been ticked")
```

`dut.xclock.AStep` 中封装了对时钟事件的等待，当时钟事件被触发时，程序才会继续向下执行。我们也可以直接使用 `await dut.event.wait()` 来等待直接时钟事件的触发。通过这种异步的方式，我们便可以同时创建多个任务，每个任务中都可以等待时钟事件的触发，从而实现多任务的并发执行。

我们做了相应的工作，以确保在下一次时钟事件到来之前，所有能够执行的任务都将会被执行，并由下一次时钟事件进行阻塞。

以下是一个完整的示例：

```python
import asyncio

dut = UT_mydut()
dut.init_clock("clk")

async def other_task():
	for _ in range(10):
		await dut.xclock.AStep(1)
		print(f"Clock has been ticked")

async def my_test():
	clock_task = asyncio.create_task(dut.xclock.RunStep(10))
	asyncio.create_task(other_task())

	await clock_task

asyncio.run(my_test())
```

除了 `RunStep` 和 `AStep` 之外，我们还提供了一个实用函数 `xclock.ACondition` 来实现更复杂的条件等待，例如 `await dut.xclock.ACondition(lambda: dut.signal_1.value == 1)`。这将会在每次时钟事件触发时检查条件是否满足，如果满足才继续向下执行。



**自定义异步事件**

如果你需要在异步的使用过程中，需要实例化若干 `Event` 或 `Queue` 来实现相应的功能，你需要使用 `xspcomm` 库中提供的 `Event` 和 `Queue` 的实现，而不是使用 Python 标准库中的 `asyncio.Event` 和 `asyncio.Queue`，这会使自定义事件和时钟触发的先后顺序得不到保证。

使用 `xspcomm` 库中的实现可以保证在当前周期所有可被触发的自定义事件都会在下一个周期到来之前被触发。

**更方便的异步使用**

picker 提供的 dut 当中仅提供了最基础的异步功能，如果你需要更加方便的使用异步，可以参考 `mlvp` 库的文档，该库提供了更加丰富的异步接口。

