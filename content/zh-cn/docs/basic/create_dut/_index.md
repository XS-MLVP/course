---
title: 创建DUT
description:  开放验证平台DUT创建的相关知识。
categories: [示例项目, 学习材料]
tags: [examples, docs]
weight: 3
---

{{% pageinfo %}}
本节主要介绍如何基于Picker创建DUT。
{{% /pageinfo %}}

创建DUT（Design Under Test）是指在芯片验证过程中，设计并实现被测对象的电路或系统。DUT是验证的主体，是需要验证的电路设计。在创建DUT时，通常需要考虑被测对象的功能、性能要求和验证目标，然后使用硬件描述语言（HDL）如Verilog或VHDL编写相应的电路描述代码，或通过图形化设计工具生成电路设计。创建DUT是验证过程中的第一步，其质量和准确性直接影响着后续的验证工作。

以[加法器DUT的创建：]("/zh-cn/docs/quick-start/")为例，进行解释：

创建一个名为 Adder 的文件夹，并在其中创建一个名为 Adder.v 的文件。这个文件将包含加法器的 Verilog 代码。下面是一个示例的加法器 Verilog 代码：

```verilog
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

DUT解释：

module Adder ... endmodule: 定义了一个名为 Adder 的模块，该模块实现了加法器的功能。

parameter WIDTH = 64: 使用 parameter 关键字定义了一个名为 WIDTH 的参数，默认值为 64。这个参数可以控制加法器的输入和输出的位宽。

input [WIDTH-1:0] a, input [WIDTH-1:0] b: 定义了两个输入端口 a 和 b，它们的宽度为 WIDTH。这里使用了一个向量（vector）来表示输入端口的多个位。

input cin: 定义了一个输入端口 cin，表示加法器的进位输入。

output [WIDTH-1:0] sum, output cout: 定义了两个输出端口 sum 和 cout，分别表示加法器的和输出和进位输出。

assign: 该关键字用于将一个表达式的值赋给一个信号。

{cout, sum}: 这是一个连续赋值语句，表示将右边表达式的值分别赋给左边的两个信号 cout 和 sum。

a + b + cin: 这是一个表达式，表示将输入端口 a、b 和 cin 的值相加。由于 a、b 和 sum 都是位宽为 WIDTH 的向量，因此这里进行的是位宽为 WIDTH 的加法运算。

通过连续赋值语句，将加法器的输出 sum 和 cout 分别赋值为表达式 a + b + cin 的结果的低 WIDTH 位和高 WIDTH 位。

endmodule: 表示模块定义结束。

这段 Verilog 代码定义了一个参数化的加法器模块，能够根据参数 WIDTH 控制输入输出的位宽。加法器的输入包括两个 WIDTH 位的数 a 和 b，以及一个单独的进位信号 cin。输出包括一个 WIDTH 位的和 sum 和一个单独的进位输出 cout。加法器的实现通过简单的连续赋值语句，将输入的两个数和进位相加，得到输出的和与进位。