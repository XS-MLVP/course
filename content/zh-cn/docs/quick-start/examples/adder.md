---
title: 加法器验证
description: 通过一个简单的加法器验证示例辅助学习，此过程只有组合逻辑，没有时序逻辑与寄存器的概念。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 10
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

### 将RTL构建为C++ Class
进入 Adder 文件夹，执行如下命令：

```bash
mcv Adder.v -w Adder.fst -S Adder -t mcv_out_adder -l cpp -e -v --sim verilator
```

该命令的含义是：

1. 将Adder.v作为 Top 文件，并将Adder作为 Top Module，利用verilator仿真器将其编译为Cpp Class
2. 启用波形输出，目标波形文件为Adder.fst
3. 输出示例项目(-e) 并保留生成时产生的中间文件(-v)
4. 最终的文件输出路径是 mcv_out_adder

在使用该命令时，还有部分命令行参数没有使用，这些命令将在后续的章节中介绍。

输出的目录结构如下，请注意这部分均为中间文件：

```bash
mcv_out_adder
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

### 编译C++ Class为动态库，并构建测试代码
在生成的 `mcv_out_adder` 目录下，替换 `example.cpp` 后执行命令 make 即可编译出 `libUTAdder.so` 动态库及其依赖文件和测试驱动程序。 同时，因为使用了 `-e` 参数， make 命令还会编译出 example 示例项目。

请注意，由于 `libUTAdder.so` 依赖于 `libDPIAdder.so` ，因此在编译 `libUTAdder.so`之前，需要先编译 `libDPIAdder.so` （自动完成）。 并且我们还需要替换 `mcv_out_adder/cpp/example.cpp` 中的内容，以保证 example 示例项目按预期运行。

`example.cpp` 的内容如下：

```cpp
#include "UT_Adder.hpp"

int64_t random_int64()
{
    static std::random_device rd;
    static std::mt19937_64 generator(rd());
    static std::uniform_int_distribution<int64_t> distribution(INT64_MIN,
                                                            INT64_MAX);
    return distribution(generator);
}

int main()
{
#if defined(USE_VCS)
    UTAdder *dut = new UTAdder("libDPIAdder.so");
#elif defined(USE_VERILATOR)
    UTAdder *dut = new UTAdder();
#endif
    // dut->initClock(dut->clock);
    dut->xclk.Step(1);
    printf("Initialized UTAdder\n");

    struct input_t {
        uint64_t a;
        uint64_t b;
        uint64_t cin;
    };

    struct output_t {
        uint64_t sum;
        uint64_t cout;
    };

    for (int c = 0; c < 114514; c++) {
        input_t i;
        output_t o_dut, o_ref;

        i.a   = random_int64();
        i.b   = random_int64();
        i.cin = random_int64() & 1;

        auto dut_cal = [&]() {
            dut->a   = i.a;
            dut->b   = i.b;
            dut->cin = i.cin;
            dut->xclk.Step(1);
            o_dut.sum  = (uint64_t)dut->sum;
            o_dut.cout = (uint64_t)dut->cout;
        };

        auto ref_cal = [&]() {
            uint64_t sum = i.a + i.b;
            bool carry   = sum < i.a;

            sum += i.cin;
            carry = carry || sum < i.cin;

            o_ref.sum  = sum;
            o_ref.cout = carry ;
        };

        dut_cal();
        ref_cal();
        printf("[cycle %llu] a=0x%lx, b=0x%lx, cin=0x%lx\n", dut->xclk.clk, i.a,
            i.b, i.cin);
        printf("DUT: sum=0x%lx, cout=0x%lx\n", o_dut.sum, o_dut.cout);
        printf("REF: sum=0x%lx, cout=0x%lx\n", o_ref.sum, o_ref.cout);
        Assert(o_dut.sum == o_ref.sum, "sum mismatch");
    }

    delete dut;
    printf("Test Passed, destory UTAdder\n");
    return 0;
}
```

成功编译后，我们即可看到 example 示例项目的输出，作为Release内容的输出结果均在 mcv_out_adder/UT_Adder 目录下。

```
[...]
[cycle 114515] a=0xa312f444394e8372, b=0x599aa4228a8b09ff, cin=0x1
DUT: sum=0xfcad9866c3d98d72, cout=0x0
REF: sum=0xfcad9866c3d98d72, cout=0x0
[...]
```
此时目录结构如下图

```bash
~/mcv_out_adder$ tree UT_Adder
UT_Adder
|-- Adder.cmake # 原 mcv_out_adder/cpp/cmake/verilator.cmake
|-- Adder.v # 原 mcv_out_adder/Adder.v
|-- Adder_top.sv
|-- Adder_top.v
|-- CMakeLists.txt # 原 mcv_out_adder/cpp/CMakeLists.txt
|-- Makefile # 原 mcv_out_adder/cpp/Makefile
|-- UTAdder_example # 测试程序
|-- UT_Adder.cpp # 原 mcv_out_adder/cpp/dut.cpp，经过模板渲染，已经被编译到libUTAdder.so中
|-- UT_Adder.hpp # 原 mcv_out_adder/cpp/dut.hpp，经过模板渲染
|-- UT_Adder_dpi.hpp # 仿真器生成的DPI函数声明，用于链接时使用
|-- dut_base.hpp # 原 mcv_out_adder/dut_base.hpp，基类头文件声明，用于链接时使用
|-- example.cpp # 测试程序代码
|-- libDPIAdder.a # 仿真器生成的静态(verilator)/动态库(vcs)，用于链接时使用
`-- libUTAdder.so # 经过封装的动态库，UT_Adder.cpp的实现已经包含在其中。
```

可以发现核心文件包含

1. `libUTAdder.so` 动态库，包含了 `UT_Adder.cpp` 的实现
2. `libDPIAdder.so` 动态库，包含了编译为C++的RTL模块实现，及DPI函数导出。
3. `UT_Adder.hpp`, `UT_Adder_dpi.hpp`, `dut_base.hpp` 三个头文件，用于链接时使用。

辅助文件包含

1. Adder.cmake，用于控制编译二进制文件时的链接参数