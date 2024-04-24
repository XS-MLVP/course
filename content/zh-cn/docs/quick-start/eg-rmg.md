---
title: 驱动随机数
description: 以LFSR随机数生成器作为案例，引入时序逻辑与寄存器的概念。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 4
---

## RTL源码

在本案例中，我们驱动一个随机数生成器，其源码如下：

```verilog
module RandomGenerator (
    input wire clk,
    input wire reset,
    input [15:0] seed,
    output [15:0] random_number
);
    reg [15:0] lfsr;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= seed;
        end else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14]};
        end
    end

    assign random_number = lfsr;
endmodule
```

该随机数生成器包含一个 16 位的 LFSR，其输入为一个 16 位的种子数，输出为一个 16 位的随机数。
LFSR 的更新规则为：将当前的 LFSR 的最高位与次高位异或，然后将结果放在 LFSR 的最低位，溢出的位被丢弃。


## 测试过程

在测试过程中，我们将创建一个名为 RandomGenerator 的文件夹，其中包含一个 RandomGenerator.v 文件。该文件内容即为上述的 RTL 源码。

### 将RTL构建为C++ Class

进入 RandomGenerator 文件夹，执行如下命令：

```bash
picker RandomGenerator.v -w RandomGenerator.fst -S RandomGenerator -t picker_out_random_generator -l cpp -e -v --sim verilator
```

该命令的含义是：

1. 将RandomGenerator.v作为 Top 文件，并将RandomGenerator作为 Top Module，利用verilator仿真器将其编译为Cpp Class
2. 启用波形输出，目标波形文件为RandomGenerator.fst
3. 输出示例项目(-e) 并保留生成时产生的中间文件(-v)
4. 最终的文件输出路径是 picker_out_random_generator


输出的目录类似[加法器验证-目录结构](/docs/quick-start/examples/adder/#将rtl构建为c-class)，这里不再赘述。

### 编译C++ Class为动态库

在生成的 `picker_out_random_generator` 目录下，替换 `cpp/example.cpp` 后执行命令 make 即可编译出 `libUTRandomGenerator.so` 动态库及其依赖文件和测试驱动程序。

> 备注：其编译过程类似于 [加法器验证-编译流程](/docs/quick-start/examples/adder/#编译c-class为动态库)，这里不再赘述。

### 配置测试驱动程序

> 注意只有替换 `cpp/example.cpp` 中的内容，才能保证 example 示例项目按预期运行。

```cpp
#include "UT_RandomGenerator.hpp"

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
    UTRandomGenerator *dut = new UTRandomGenerator("libDPIAdder.so");
#elif defined(USE_VERILATOR)
    UTRandomGenerator *dut = new UTRandomGenerator();
#endif
    unsigned short seed = random_int64() & 0xffff;
    printf("seed = 0x%x\n", seed);
    dut->initClock(dut->clk);
    dut->xclk.Step(10);
    dut->reset = 1;
    dut->seed = seed;
    dut->xclk.Step(1);
    dut->reset = 0;
    dut->xclk.Step(1);
    printf("Initialized UTRandomGenerator\n");

    struct output_t {
        uint64_t cout;
    };

    for (int c = 0; c < 114514; c++) {
        
        output_t o_dut, o_ref;

        auto dut_cal = [&]() {
            dut->xclk.Step(1);
            o_dut.cout = (unsigned short)dut->random_number;
        };

        // as lfsr
        auto ref_cal = [&]() { 
            seed = (seed << 1) | ((seed >> 15) ^ (seed >> 14) & 1);
            o_ref.cout = seed;
        };

        dut_cal();
        ref_cal();
        printf("[cycle %llu] ", dut->xclk.clk);
        printf("DUT: cout=0x%x , ", o_dut.cout);
        printf("REF: cout=0x%x\n", o_ref.cout);
        Assert(o_dut.cout == o_ref.cout, "sum mismatch");
    }

    delete dut;
    printf("Test Passed, destory UTRandomGenerator\n");
    return 0;
}
```

### 运行测试程序

在 `picker_out_random_generator` 目录下执行 `./example` 即可运行测试程序。

输出示例为：

```bash
...
[cycle 114510] DUT: cout=0x7e8d , REF: cout=0x7e8d
[cycle 114511] DUT: cout=0xfd1b , REF: cout=0xfd1b
[cycle 114512] DUT: cout=0xfa36 , REF: cout=0xfa36
[cycle 114513] DUT: cout=0xf46c , REF: cout=0xf46c
[cycle 114514] DUT: cout=0xe8d8 , REF: cout=0xe8d8
[cycle 114515] DUT: cout=0xd1b0 , REF: cout=0xd1b0
[cycle 114516] DUT: cout=0xa360 , REF: cout=0xa360
[cycle 114517] DUT: cout=0x46c1 , REF: cout=0x46c1
[cycle 114518] DUT: cout=0x8d83 , REF: cout=0x8d83
[cycle 114519] DUT: cout=0x1b07 , REF: cout=0x1b07
[cycle 114520] DUT: cout=0x360e , REF: cout=0x360e
[cycle 114521] DUT: cout=0x6c1c , REF: cout=0x6c1c
[cycle 114522] DUT: cout=0xd839 , REF: cout=0xd839
[cycle 114523] DUT: cout=0xb072 , REF: cout=0xb072
[cycle 114524] DUT: cout=0x60e5 , REF: cout=0x60e5
[cycle 114525] DUT: cout=0xc1cb , REF: cout=0xc1cb
[cycle 114526] DUT: cout=0x8396 , REF: cout=0x8396
Test Passed, destory UTRandomGenerator
...
```

此时目录结构及核心文件也和[加法器验证-运行测试](/docs/quick-start/examples/adder/#运行测试)类似，这里不再赘述。
