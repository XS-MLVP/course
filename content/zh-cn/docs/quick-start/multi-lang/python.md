---
title: Python
description: 基于Python封装DUT硬件的运行环境，将生成的C++ lib基于Swig导出为Python module。
categories: [教程]
tags: [docs]
weight: 61
---

## 原理介绍

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


## 使用教程

- 参数 `--language cpp` 或 `-l cpp` 用于指定生成C++基础库。
- 参数 `-e` 用于生成包含示例项目的可执行文件。
- 参数 `-v` 用于保留生成项目时的中间文件。

### DUT

### XDATA

### XPORT

### XClock

### Async & Event

