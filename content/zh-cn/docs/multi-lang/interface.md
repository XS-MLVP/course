---
title: 验证接口
description: DUT文件与编程语言都支持的验证接口
categories: [教程]
tags: [docs]
weight: 1
---

## 生成库文件

picker可以通过参数`--lang`指定转换的对应语言（参数已支持cpp、python、java、lua、scala、golang），由于不同编程语言对应的“库”不同，因此生成的库文件有所区别，例如java生成的是jar包，python生成的为文件夹。picker导出对应编程语言的库，需要xcomm的支持，可以通过`picker --check`查看支持情况：

```bash
$picker --check
[OK ] Version: 0.9.0-feat_performance_improve-b7001a6-2025-04-11-dirty
[OK ] Exec path: /usr/local/share/lib/python3.11/site-packages/picker/bin/picker
[OK ] Template path: /usr/local/share/lib/python3.11/site-packages/picker/share/picker/template
[OK ] Support    Cpp (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/lib' success)
[OK ] Support Golang (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/golang' success)
[OK ] Support   Java (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/java/xspcomm-java.jar' success)
[OK ] Support    Lua (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/lua/luaxspcomm.so' success)
[OK ] Support Python (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/python' success)
[OK ] Support  Scala (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/scala/xspcomm-scala.jar' success)
```

输出显示success表示支持，fail表示不支持。

### C++

以下为如何使用Picker将RTL代码编译为C++ Class，并编译为动态库。

1. 首先，Picker工具会解析RTL代码，根据指定的 Top Module ，创建一个新的 Module 封装该模块的**输入输出端口**，并导出`DPI/API`以操作输入端口、读取输出端口。
    > *工具通过指定Top Module所在的文件和 Module Name来确定需要封装的模块。此时可以将 Top 理解为软件编程中的main。*

2. 其次，Picker工具会使用指定的 **仿真器** 编译RTL代码，并生成一个**DPI库文件**。该库文件内包含模拟运行RTL代码所需要的逻辑（即为**硬件模拟器**）。
    > *对于VCS，该库文件为.so（动态库）文件，对于Verilator，该库文件为.a（静态库）文件。*
    > *DPI的含义是 [Direct Programming Interface](https://www.chipverify.com/systemverilog/systemverilog-dpi)，可以理解为一种API规范。*

3. 接下来，Picker工具会根据配置参数，渲染源代码中定义的基类，生成用于对接仿真器并**隐藏仿真器细节**的基类（wrapper）。然后链接基类与DPI库文件，生成一个 **UT动态库文件**。
    > - *此时，该**UT库文件**使用了Picker工具模板中提供的统一API，相比于**DPI库文件**中与仿真器强相关的API，UT库文件为仿真器生成的硬件模拟器，提供了**统一的API接口**。*
    > - *截至这一步生成**UT库文件**在不同语言中是**通用**的！如果没有另行说明，其他高级语言均会通过**调用UT动态库**以实现对硬件模拟器的操作。*

4. 最后，Picker工具会根据配置参数和解析的RTL代码，生成一段 **C++ Class** 的源码。这段源码即是 RTL 硬件模块在软件中的**定义 (.hpp)** 及**实现 (.cpp)** 。实例化该类即相当于创建了一个硬件模块。
    > *该类继承自**基类**，并实现了基类中的纯虚函数，以用软件方式实例化硬件。*
    > *不将**类的实现**这一步也封装进动态库的原因有两点：*
    >   1. *由于**UT库文件**需要在不同语言中**通用**，而不同语言实现类的方式不同。为了通用性，不将`类的实现`封装进动态库。*
    >   2. *为了**便于调试**，提升代码可读性，方便用户进行二次封装和修改。*

对于C++语言，picker生成的为so动态链接库，和对应的头文件。例如：

```bash
UT_Adder/
├── UT_Adder.cpp       # DUT 文件
├── UT_Adder.hpp       # DUT 头文件
├── UT_Adder_dpi.hpp   # DPI 头文件
├── dut_base.hpp       # DUT base 头文件
├── libDPIAdder.a      # DPI 静态库
└── libUTAdder.so      # DUT 动态库
```

在使用时，设置好LD路径，然后再测试代码中`#include UT_Adder.hpp`

### Python

Python语言生成的为目录（Python module以目录的方式表示）

```bash
UT_Adder/
├── _UT_Adder.so
├── __init__.py
├── libUTAdder.so
└── libUT_Adder.py
```

设置PYTHONPATH后，可以在test中`import UT_Adder`

### Java/scala

对于Java和scala基于JVM的编程语言，picker生成的为对应的jar包。

```bash
UT_Adder/
├── UT_Adder-scala.jar
└── UT_Adder-java.jar
```

### go

go语言生成的为目录（类似python）。

```bash
UT_Adder/
└── golang
    └── src
        └── UT_Adder
            ├── UT_Adder.go
            ├── UT_Adder.so
            ├── UT_Adder_Wrapper.go
            ├── go.mod
            └── libUTAdder.so
```

设置GOPATH后，可直接进行import

## 验证接口


DUT验证接口可以参考连接：[https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md](https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md)


xspcomm库接口请参考连接：[https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md](https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md)
