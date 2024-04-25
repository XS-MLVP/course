---
title: 基础使用
description: Picker 工具的基础使用方法。
categories: [教程]
tags: [docs]
weight: 1
---

{{% pageinfo %}}
为满足开放验证的环境要求，我们开发了 Picker 工具，用于将 RTL 设计转换为多语言接口，并在此基础上进行验证，我们将会使用 Picker 工具生成的环境作为基础的验证环境。接下来我们将介绍 Picker 工具，及其基础的使用方法。
{{% /pageinfo %}}

## Picker 简介
> picker是一个芯片验证辅助工具，其目标是将RTL设计验证模块(.v/.scala/.sv)进行封装，并使用其他编程语言暴露Pin-Level的操作，未来计划支持自动化的Transaction-Level原语生成。其他编程语言包括 c++ (原生支持), python(已支持), java(todo), golang(todo) 等编程语言接口。该辅助工具让用户可以基于现有的软件测试框架，例如pytest, junit，TestNG, go test等，进行芯片UT验证。

基于picker进行验证具有如下**优点**：

1.**不泄露RTL设计**。经过Picker转换后，原始的设计文件(.v)被转化成了二进制文件(.so)，脱离原始设计文件后，依旧可进行验证，且验证者无法获取RTL源代码。

2.**减少编译时间**。当DUT(Design Under Test)稳定时，只需要编译一次（打包成so）。

3.**用户面广**。提供的编程接口多，可覆盖不同语言的开发者（传统IC验证，只用System Verilog）。

4.**可使用软件生态丰富**。能使用python3, java, golang等生态。

>目前picker支持以下模拟器：
verilator
synopsys vcs
### 1.Picker的工作原理
Picker的主要功能就是将Verilog代码转换为C++或者Python代码，以处理器的仿真为例:

![Picker的工作原理](Picker_working_principle.svg)
### 2.使用Python访问Verilog信号

>Picker的使用xspcomm来为公用数据定义与操作接口，包括接口读/写、时钟、协程、SWIG回调函数定义等。xspcomm以基础组件的方式被 DUT、MLVP、OVIP等上层应用或者库使用。xspcomm需要用到C++20的特征，建议使用g++ 11 以上版本， cmake 版本大于等于3.11。当通过SWIG导出Python接口时，需要 swig 版本大于等于 4.2.0。

>在 Picker 生成的 Python 代码中，顶层模块会被转化为一个类，通常命名为 UT<top-module>。其输入/输出信号会被定义为公有的成员变量，因此我们可以直接访问这些信号。对于顶层的输入信号，我们可以对其进行赋值；对于顶层的输出信号，我们可以直接读取其值。
例如，对于如下的Verilog顶层代码：
```
module top (
        input clk
    );

endmodule
```

Picker会生成如下的Python代码：
```
class DUTtop(DutUnifiedBase):

	## 初始化
	def __init__(self, *a, **kw):
		super().__init__(*a, **kw)
		self.xclock = xsp.XClock(self.step)
		self.port  = xsp.XPort()
		self.xclock.Add(self.port)
		self.event = self.xclock.getEvent()

		## all Pins
		self.clk = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)


		## BindDPI
		self.clk.BindDPIRW(DPIRclk, DPIWclk)

		## Add2Port
		self.port.Add("clk", self.clk.xdata)


	def __del__(self):
		super().__del__()
		self.finalize()

	def init_clock(self,name:str):
		self.xclock.Add(self.port[name])

	def Step(self,i: int):
		return self.xclock.Step(i)

	def __getitem__(self, key):
		return xsp.XPin(self.port[key], self.event)

	async def astep(self,i: int):
		return self.xclock.AStep(i)

	async def acondition(self,fc_cheker):
		return self.xclock.ACondition(fc_cheker)

	async def runstep(self,i: int):
		return self.xclock.RunSetp(i)
```
在导入DUT类之后我们可以直接通过对象的.value属性给信号赋值,以及.Step()方法来驱动，还可以调用finalize()函数来生成波形图和测试覆盖率，**但是要注意finalize函数会把对象销毁，不要重复调用**，下面是一个给信号赋值的简单例子：

```
from UT_Top import *
dut=DUTTop("libDPITop.so")
dut.clk.value = 1
dut.Step(1)
## 模拟时钟信号
dut.clk.value = ~clk
dut.Step(1)
dut.finalize()
```
关于信号访问的高级教程具体可以参考[xcomm文档](https://github.com/XS-MLVP/xcomm)，详细讲解了 Picker 的公用数据定义与操作接口，包括接口读/写、时钟、协程、SWIG回调函数定义等。


## Python 模块生成

### 生成模块的过程

在本章节中，我们将介绍如何使用Picker将RTL代码最终导出为Python Module。

1. Picker 导出 Python Module 的方式是基于 C++ 的。
    - **Picker 是 codegen 工具，它会先生成项目文件，再利用 make 编译出二进制文件。**
    - Picker 首先会利用仿真器将 RTL 代码编译为 C++ Class，并编译为动态库。（见C++步骤详情）
    - 再基于 Swig 工具，利用上一步生成的 C++ 的头文件定义，将动态库导出为 Python Module。
    - 最终将生成的模块导出到目录，并按照需求清理或保留其他中间文件。
    > Swig 是一个用于将 C/C++ 导出为其他高级语言的工具。该工具会解析 C++ 头文件，并生成对应的中间代码。
    > 如果希望详细了解生成过程，请参阅 [Swig 官方文档](http://www.swig.org/Doc4.2/SWIGDocumentation.html)。
    > 如果希望知道 Picker 如何生成 C++ Class，请参阅 [C++](docs/quick-start/multi-lang/cpp)。

2. 该这个模块和标准的 Python 模块一样，可以被其他 Python 程序导入并调用，文件结构也与普通 Python 模块无异。

### 使用该模块

在本章节中，我们将介绍如何基于上一章节生成的 Python Module，编写测试用例，并导入该模块，以实现对硬件模块的操作。

1. 以前述的加法器为例，用户需要编写测试用例，即导入上一章节生成的 Python Module，并调用其中的方法，以实现对硬件模块的操作。
目录结构为：
    ```shell
        picker_out_adder
        |-- UT_Adder # Picker 工具生成的项目
        |   |-- Adder.fst.hier
        |   |-- _UT_Adder.so
        |   |-- __init__.py
        |   |-- libDPIAdder.a
        |   |-- libUTAdder.so
        |   `-- libUT_Adder.py
        `-- example.py # 用户需要编写的代码
    ```
2. 用户使用 Python 编写测试用例，即导入上述生成的 Python Module，并调用其中的方法，以实现对硬件模块的操作。

    ```python
    from UT_Adder import * # 从python软件包里导入模块
    import random

    if __name__ == "__main__":
        dut = DUTAdder() # 初始化 DUT
        # dut.init_clock("clk") # 如果模块有时钟，需要初始化时钟，绑定时钟信号到模拟器的时钟，以自动驱动

        dut.finalize() # 清空对象，并完成覆盖率和波形文件的输出工作（写入到文件）
    ```

## Python 模块使用

- 参数 `--language cpp` 或 `-l cpp` 用于指定生成C++基础库。
- 参数 `-e` 用于生成包含示例项目的可执行文件。
- 参数 `-v` 用于保留生成项目时的中间文件。

### DUT

### XDATA

### XPORT

### XClock

### Async & Event

```
---
title: 使用 Python
description: 基于Python封装DUT硬件的运行环境，将生成的C++ lib基于Swig导出为Python module。
categories: [教程]
tags: [docs]
weight: 2
---
```
