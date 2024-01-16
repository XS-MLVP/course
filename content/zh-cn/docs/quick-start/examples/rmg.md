---
title: 随机数生成器验证
description: 以LFSR随机数生成器作为案例，引入时序逻辑与寄存器的概念。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 20
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

## 测试过程

在测试过程中，我们将创建一个名为 RandomGenerator 的文件夹，其中包含一个 RandomGenerator.v 文件。该文件内容即为上述的 RTL 源码。

### 将RTL构建为C++ Class

进入 RandomGenerator 文件夹，执行如下命令：

```bash
mcv RandomGenerator.v -w RandomGenerator.fst -S RandomGenerator -t mcv_out_random_generator -l cpp -e -v --sim verilator
```

该命令的含义是：

1. 将RandomGenerator.v作为 Top 文件，并将RandomGenerator作为 Top Module，利用verilator仿真器将其编译为Cpp Class
2. 启用波形输出，目标波形文件为RandomGenerator.fst
3. 输出示例项目(-e) 并保留生成时产生的中间文件(-v)
4. 最终的文件输出路径是 mcv_out_random_generator
