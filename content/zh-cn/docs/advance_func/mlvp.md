---
title: 验证框架
description: MLVP 验证框架。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 5
draft: true
---

通过 Picker 工具生成的 Python DUT，已经可以使我们在 Python 环境中进行简单的验证，包括对 DUT 的实例化、信号赋值、时钟驱动等操作。但是在实际的验证工作中，我们通常需要更为高级的验证特性，例如协程支持、覆盖率收集与报告生成等功能。为此，我们提供了 **toffee** 验证框架，用于提供这些高级验证特性。

目前，toffee 验证框架支持的功能包括：

- **协程支持**：toffee 验证框架提供了协程支持，使用户可以方便地编写异步验证代码。
- **覆盖率收集与报告生成**：[toffee-test](https://github.com/XS-MLVP/toffee-test) 验证框架提供了覆盖率收集与报告生成功能，使用户可以方便地收集覆盖率数据，并生成覆盖率报告。
- **日志记录**：toffee 验证框架提供了日志记录功能，使用户可以方便地记录验证过程中的信息。
- **接口** ：toffee 验证框架提供了接口的创建，方便用户定义一组用于完成某个特定功能的接口集合，同时也使得软件模块的编写与 DUT 的具体实现解耦。
- **验证实用模块**： toffee 验证框架提供了一些验证实用模块，方便用户编写软件模块，目前包含 “两比特饱和计数器”， “伪 LRU 算法” 等。

有关 toffee 验证框架的详细使用方法，请参见 [toffee](https://github.com/XS-MLVP/toffee)；如果需要导出覆盖率和报告，可以使用 toffee-test，请参见 [toffee-test](https://github.com/XS-MLVP/toffee-test)。
