---
title: 案例一：简单加法器
date: 2017-01-05
description: 基于一个简单的加法器验证展示工具的原理和使用方法，这个加法器内部是简单的组合逻辑。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## RTL源码
在本案例中，我们驱动一个 64 位的加法器（组合电路），其源码如下：

```verilog
// A verilog 64-bit full adder with carry in and carry out

module Adder #(
    parameter WIDTH = 64
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);

assign {cout, sum}  = a + b + cin;

endmodule
```
该加法器包含一个 64 位的加法器，其输入为两个 64 位的数和一个进位信号，输出为一个 64 位的和和一个进位信号。

## 测试过程
在测试过程中，我们将创建一个名为 Adder 的文件夹，其中包含一个 Adder.v 文件。该文件内容即为上述的 RTL 源码。

### 将RTL导出为 Python Module

#### 生成中间文件

进入 Adder 文件夹，执行如下命令：

```bash
picker export --autobuild=false Adder.v -w Adder.fst --sname Adder --tdir picker_out_adder/ --lang python -e --sim verilator
```

*注：--tdir 指定的是目标构建目录，如果该参数值为空或者以“/”结尾，picker则会自动以DUT的目标模块名创建构建目录。例如 `--tdir picker_out_adder`指定了当前目录下的picker_out_adder为构建目录，而参数`--tdir picker_out_adder/`则指定picker在当前目录picker_out_adder中创建Adder目录作为目标构建目录。

该命令的含义是：

1. 将 Adder.v 作为 Top 文件，并将 Adder 作为 Top Module，基于 verilator 仿真器生成动态库，生成目标语言为 Python。
2. 启用波形输出，目标波形文件为Adder.fst。
3. 包含用于驱动示例项目的文件(-e)，同时codegen完成后不自动编译(-autobuild=false)。
4. 最终的文件输出路径是 picker_out_adder

在使用该命令时，还有部分命令行参数没有使用，这些命令将在后续的章节中介绍。

输出的目录结构如下，**请注意这部分均为中间文件**，不能直接使用：

```bash
picker_out_adder/
└── Adder
    |-- Adder.v # 原始的RTL源码
    |-- Adder_top.sv # 生成的Adder_top顶层封装，使用DPI驱动Adder模块的inputs和outputs
    |-- Adder_top.v # 生成的Adder_top顶层封装，因为Verdi不支持导入SV源码使用，因此需要生成一个Verilog版本
    |-- CMakeLists.txt # 用于调用仿真器编译基本的cpp class并将其打包成有裸DPI函数二进制动态库(libDPIAdder.so)
    |-- Makefile # 生成的Makefile，用于调用CMakeLists.txt，并让用户可以通过make命令编译出libAdder.so，并手动调整Makefile的配置参数。或者编译示例项目
    |-- cmake # 生成的cmake文件夹，用于调用不同仿真器编译RTL代码
    |   |-- vcs.cmake
    |   `-- verilator.cmake
    |-- cpp # CPP example目录，包含示例代码
    |   |-- CMakeLists.txt # 用于将libDPIAdder.so使用基础数据类型封装为一个可直接操作的类（libUTAdder.so），而非裸DPI函数。
    |   |-- Makefile
    |   |-- cmake
    |   |   |-- vcs.cmake
    |   |   `-- verilator.cmake
    |   |-- dut.cpp # 生成的cpp UT封装，包含了对libDPIAdder.so的调用，及UTAdder类的声明及实现
    |   |-- dut.hpp # 头文件
    |   `-- example.cpp # 调用UTAdder类的示例代码
    |-- dut_base.cpp # 用于调用与驱动不同仿真器编译结果的基类，通过继承封装为统一的类，用于隐藏所有仿真器相关的代码细节。
    |-- dut_base.hpp
    |-- filelist.f # 多文件项目使用的其他文件列表，请查看 -f 参数的介绍。本案例中为空
    |-- mk
    |   |-- cpp.mk # 用于控制以cpp为目标语言时的Makefile，包含控制编译示例项目（-e，example）的逻辑
    |   `-- python.mk # 同上，目标语言是python
    `-- python
        |-- CMakeLists.txt
        |-- Makefile
        |-- cmake
        |   |-- vcs.cmake
        |   `-- verilator.cmake
        |-- dut.i # SWIG配置文件，用于将libDPIAdder.so的基类与函数声明，依据规则用swig导出到python，提供python调用的能力
        `-- dut.py # 生成的python UT封装，包含了对libDPIAdder.so的调用，及UTAdder类的声明及实现，等价于 libUTAdder.so
```

#### 构建中间文件

进入 `picker_out_adder/Adder` 目录并执行 `make` 命令，即可生成最终的文件。

> 由 `Makefile` 定义的自动编译过程流如下：
>
> 1. 通过 `cmake/*.cmake` 定义的仿真器调用脚本，编译 `Adder_top.sv` 及相关文件为 `libDPIAdder.so` 动态库。
> 2. 通过 `CMakelists.txt` 定义的编译脚本，将 `libDPIAdder.so` 通过 `dut_base.cpp` 封装为 `libUTAdder.so` 动态库。并将1、2步产物拷贝到 `UT_Adder` 目录下。
> 3. 通过 `dut_base.hpp` 及 `dut.hpp` 等头文件，利用 `SWIG` 工具生成封装层，并最终在 `UT_Adder` 这一目录中构建一个 Python Module。
> 4. 如果有 `-e` 参数，则将预先定义好的 `example.py` 置于 `UT_Adder` 目录的上级目录，作为如何调用该 Python Module 的示例代码。

最终目录结果为：

```bash
picker_out_adder/
└── Adder
    |-- _UT_Adder.so # Swig生成的wrapper动态库
    |-- __init__.py # Python Module的初始化文件，也是库的定义文件
    |-- libDPIAdder.a # 仿真器生成的库文件
    |-- libUTAdder.so # 基于dut_base生成的libDPI动态库封装
    |-- libUT_Adder.py # Swig生成的Python Module
    `-- xspcomm # xspcomm基础库，固定文件夹，不需要关注
```

### 配置测试代码

> 在picker_out_adder中添加 `example.py`：

```python

from Adder import *
import random

# 生成无符号随机数
def random_int(): 
    return random.randint(-(2**63), 2**63 - 1) & ((1 << 63) - 1)

# 通过python实现的加法器参考模型
def reference_adder(a, b, cin):
    sum = (a + b) & ((1 << 64) - 1)
    carry = sum < a
    sum += cin
    carry = carry or sum < cin
    return sum, 1 if carry else 0

def random_test():
    # 创建DUT
    dut = DUTAdder()
    # 默认情况下，引脚赋值不会立马写入，而是在下一次时钟上升沿写入，这对于时序电路适用，但是Adder为组合电路，所以需要立即写入
    #   因此需要调用AsImmWrite()方法更改引脚赋值行为
    dut.a.AsImmWrite()
    dut.b.AsImmWrite()
    dut.cin.AsImmWrite()
    # 循环测试
    for i in range(114514):
        a, b, cin = random_int(), random_int(), random_int() & 1
        # DUT：对Adder电路引脚赋值，然后驱动组合电路 （对于时序电路，或者需要查看波形，可通过dut.Step()进行驱动）
        dut.a.value, dut.b.value, dut.cin.value = a, b, cin
        dut.RefreshComb()
        # 参考模型：计算结果
        ref_sum, ref_cout = reference_adder(a, b, cin)
        # 检查结果
        assert dut.sum.value == ref_sum, "sum mismatch: 0x{dut.sum.value:x} != 0x{ref_sum:x}"
        assert dut.cout.value == ref_cout, "cout mismatch: 0x{dut.cout.value:x} != 0x{ref_cout:x}"
        print(f"[test {i}] a=0x{a:x}, b=0x{b:x}, cin=0x{cin:x} => sum: 0x{ref_sum}, cout: 0x{ref_cout}")
    # 完成测试
    dut.Finish()
    print("Test Passed")

if __name__ == "__main__":
    random_test()

```


### 运行测试

在 `picker_out_adder` 目录下执行 `python3 example.py` 命令，即可运行测试。在测试完成后我们即可看到 example 示例项目的输出。

```
[...]
[test 114507] a=0x7adc43f36682cffe, b=0x30a718d8cf3cc3b1, cin=0x0 => sum: 0x12358823834579604399, cout: 0x0
[test 114508] a=0x3eb778d6097e3a72, b=0x1ce6af17b4e9128, cin=0x0 => sum: 0x4649372636395916186, cout: 0x0
[test 114509] a=0x42d6f3290b18d4e9, b=0x23e4926ef419b4aa, cin=0x1 => sum: 0x7402657300381600148, cout: 0x0
[test 114510] a=0x505046adecabcc, b=0x6d1d4998ed457b06, cin=0x0 => sum: 0x7885127708256118482, cout: 0x0
[test 114511] a=0x16bb10f22bd0af50, b=0x5813373e1759387, cin=0x1 => sum: 0x2034576336764682968, cout: 0x0
[test 114512] a=0xc46c9f4aa798106, b=0x4d8f52637f0417c4, cin=0x0 => sum: 0x6473392679370463434, cout: 0x0
[test 114513] a=0x3b5387ba95a7ac39, b=0x1a378f2d11b38412, cin=0x0 => sum: 0x6164045699187683403, cout: 0x0
Test Passed
```
