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

编译DUT是指将被测设计（Design Under Test，即DUT）的硬件描述语言（HDL）代码转换为可供仿真和验证使用的逻辑网表的过程。这个过程通常包括综合、优化、映射和布线等步骤，其主要目的是将抽象的HDL代码转换为实际的电路网表，以便进行后续的仿真和验证工作。

以[加法器DUT的编译：]({{< ref "/content/zh-cn/docs/quick-start/_index.md" >}})为例进行解释：

在 Adder 文件夹中，执行以下命令将 Verilog 文件编译为 C++ Class：

```verilog
picker Adder.v -w Adder.fst -S Adder -t picker_out_adder -l cpp -e -v --sim verilator
```

这个命令会将 Adder.v 文件作为 Top 文件，并将其编译为 C++ Class，使用 verilator 仿真器。编译过程会生成一系列中间文件，其中包括 Verilog 文件、C++ 源代码等。
