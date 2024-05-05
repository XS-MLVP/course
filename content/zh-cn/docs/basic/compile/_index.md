---
title: DUT编译
description:  开放验证平台DUT的编译相关知识。
categories: [示例项目, 学习材料]
tags: [examples, docs]
weight: 4
---

{{% pageinfo %}}
本节主要介绍如何基于Picker编译DUT。
{{% /pageinfo %}}

通常来讲，编译DUT是指将被测设计（Design Under Test，即DUT）的硬件描述语言（HDL）代码转换为可供仿真和验证使用的逻辑网表的过程。而在Picker工具的环境下，则是将RLT代码转换成软件的动态链接库，后续验证工作中可以直接调用，达到“软件模拟硬件行为”的效果。

同样以**简单加法器**为例进行解释：

在 Adder 文件夹中，执行以下命令将 Verilog 文件编译为 C++ Class：

```verilog
picker Adder.v -w Adder.fst -S Adder -t picker_out_adder -l cpp -e -v --sim verilator
```

这个命令会将 Adder.v 文件作为 Top 文件，并将其编译为 C++ Class，使用 verilator 仿真器。编译过程会生成一系列中间文件，其中包括 Verilog 文件、C++ 源代码等。
