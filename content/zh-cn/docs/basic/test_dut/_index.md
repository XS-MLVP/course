---
title: DUT验证
description:  开放验证平台DUT验证的相关知识。
categories: [示例项目, 学习材料]
tags: [examples, docs]
weight: 5
---

{{% pageinfo %}}
本节主要介绍如何基于Picker验证DUT。
{{% /pageinfo %}}

DUT测试是芯片验证过程中的关键步骤之一，指的是对被测设计（Design Under Test，即DUT）进行验证和测试的过程。在DUT测试中，验证工程师会通过各种测试方法和技术，对DUT的功能、性能和时序等方面进行全面的评估，以确保DUT能够按照设计要求正常工作，并且满足用户的需求和期望。

以[加法器DUT的测试：]({{< ref "/content/zh-cn/docs/quick-start/_index.md" >}})为例进行解释：

在测试过程中，我们将创建一个示例项目，并编写测试代码来验证加法器的功能。

```verilog
#include "UT_Adder.hpp"

int main()
{
    UTAdder *dut = new UTAdder("libDPIAdder.so");

    // 进行测试...
    
    delete dut;
    return 0;
}
```

在这段代码中，我们创建了一个 UTAdder 类的实例，然后进行测试。

接着，编译测试代码。在 Adder 文件夹中，执行 make 命令，编译测试代码并生成可执行文件。

最后，运行测试。执行生成的可执行文件，即可运行测试，并观察输出结果。