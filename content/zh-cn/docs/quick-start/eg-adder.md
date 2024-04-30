---
title: 案例一：加法器
date: 2017-01-05
description: 基于一个简单的加法器验证展示工具的原理和使用方法，这个加法器内部是简单的组合逻辑。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 3
---

## RTL源码
在本案例中，我们驱动一个 64 位的加法器，其源码如下：

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

### 将RTL构建为 Python Module

#### 生成中间文件

进入 Adder 文件夹，执行如下命令：

```bash
picker --autobuild=false Adder.v -w Adder.fst -S Adder -t picker_out_adder -l python -e --sim verilator
```

该命令的含义是：

1. 将 Adder.v 作为 Top 文件，并将 Adder 作为 Top Module，基于 verilator 仿真器生成动态库，生成目标语言为 Python。
2. 启用波形输出，目标波形文件为Adder.fst。
3. 包含用于驱动示例项目的文件(-e)，同时codegen完成后不自动编译(-autobuild=false)。
4. 最终的文件输出路径是 picker_out_adder

在使用该命令时，还有部分命令行参数没有使用，这些命令将在后续的章节中介绍。

输出的目录结构如下，**请注意这部分均为中间文件**，不能直接使用：

```bash
picker_out_adder
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

进入 `picker_out_adder` 目录并执行 `make` 命令，即可生成最终的文件。

> 由 `Makefile` 定义的自动编译过程流如下：
>
> 1. 通过 `cmake/*.cmake` 定义的仿真器调用脚本，编译 `Adder_top.sv` 及相关文件为 `libDPIAdder.so` 动态库。
> 2. 通过 `CMakelists.txt` 定义的编译脚本，将 `libDPIAdder.so` 通过 `dut_base.cpp` 封装为 `libUTAdder.so` 动态库。并将1、2步产物拷贝到 `UT_Adder` 目录下。
> 3. 通过 `dut_base.hpp` 及 `dut.hpp` 等头文件，利用 `SWIG` 工具生成封装层，并最终在 `UT_Adder` 这一目录中构建一个 Python Module。
> 4. 如果有 `-e` 参数，则将预先定义好的 `example.py` 置于 `UT_Adder` 目录的上级目录，作为如何调用该 Python Module 的示例代码。

最终目录结果为：

```bash
.
|-- Adder.fst # 测试的波形文件
|-- UT_Adder
|   |-- Adder.fst.hier
|   |-- _UT_Adder.so # Swig生成的wrapper动态库
|   |-- __init__.py # Python Module的初始化文件，也是库的定义文件
|   |-- libDPIAdder.a # 仿真器生成的库文件
|   |-- libUTAdder.so # 基于dut_base生成的libDPI动态库封装
|   `-- libUT_Adder.py # Swig生成的Python Module
|   `-- xspcomm # xspcomm基础库，固定文件夹，不需要关注
`-- example.py # 示例代码
```

### 配置测试代码

> 注意需要替换 `example.py` 中的内容，才能保证 example 示例项目按预期运行。

```python
from UT_Adder import *

import random

class input_t:
    def __init__(self, a, b, cin):
        self.a = a
        self.b = b
        self.cin = cin

class output_t:
    def __init__(self):
        self.sum = 0
        self.cout = 0

def random_int(): # 需要将数据以无符号数的形式传入dut
    return random.randint(-(2**63), 2**63 - 1) & ((1 << 63) - 1)

def as_uint(x, nbits): # 将数据转换为无符号数
    return x & ((1 << nbits) - 1)

def main():
    dut = DUTAdder()  # Assuming USE_VERILATOR

    print("Initialized UTAdder")

    for c in range(114514):
        i = input_t(random_int(), random_int(), random_int() & 1)
        o_dut, o_ref = output_t(), output_t()

        def dut_cal():
            # 针对 DUT 的输入赋值，必须使用 .value
            dut.a.value, dut.b.value, dut.cin.value = i.a, i.b, i.cin
            # 驱动电路运行一个周期
            dut.Step(1)
            o_dut.sum = dut.sum.value
            o_dut.cout = dut.cout.value

        def ref_cal():
            sum = as_uint( i.a + i.b, 64 )
            carry = sum < i.a
            sum += i.cin
            carry = carry or sum < i.cin
            o_ref.sum, o_ref.cout = sum, carry

        dut_cal()
        ref_cal()

        print(f"[cycle {dut.xclock.clk}] a=0x{i.a:x}, b=0x{i.b:x}, cin=0x{i.cin:x} ")
        print(f"DUT: sum=0x{o_dut.sum:x}, cout=0x{o_dut.cout:x}")
        print(f"REF: sum=0x{o_ref.sum:x}, cout=0x{o_ref.cout:x}")

    assert o_dut.sum == o_ref.sum, "sum mismatch"
    dut.finalize() # 必须显式调用finalize方法，否则会导致内存泄漏，并无法生成波形和覆盖率
    print("Test Passed, destroy UTAdder")

if __name__ == "__main__":
    main()

```

### 运行测试

在 `picker_out_adder` 目录下执行 `python example.py` 命令，即可运行测试。在测试完成后我们即可看到 example 示例项目的输出。波形文件会被保存在 `Adder.fst` 中。

```
[...]
[cycle 114513] a=0x6defb0918b94495d, b=0x72348b453ae6a7a8, cin=0x0 
DUT: sum=0xe0243bd6c67af105, cout=0x0
REF: sum=0xe0243bd6c67af105, cout=0x0
[cycle 114514] a=0x767fa8cbfd6bbfdc, b=0x4486aa3a9b29719a, cin=0x1 
DUT: sum=0xbb06530698953177, cout=0x0
REF: sum=0xbb06530698953177, cout=0x0
Test Passed, destroy UTAdder
```
