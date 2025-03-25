---
title: 验证框架
description: 搭建硬件验证环境所需的框架——Toffee
weight: 3
---

**Toffee** 是使用 Python 语言编写的一套硬件验证框架，它依赖于多语言转换工具 [Picker](https://github.com/XS-MLVP/picker)，该工具能够将硬件设计的 Verilog 代码转换为 Python Package，使得用户可以使用 Python 来驱动并验证硬件设计。

其吸收了部分 UVM 验证方法学，以保证验证环境的规范性和可复用性，并重新设计了整套验证环境的搭建方式，使其更符合软件领域开发者的使用习惯，从而使软件开发者可以轻易地上手硬件验证工作。

在 [Toffee Documentation](https://pytoffee.readthedocs.io/zh-cn/latest/) 中查看 Toffee 的详细使用说明。
