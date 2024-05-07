---
title: 数字电路
weight: 2
description: >
  关于数字电路的基本概念
---

{{% pageinfo %}}
本页将介绍数字电路的基础知识。数字电路是利用数字信号的电子电路。近年来，绝大多数的计算机都是基于数字电路实现的。
{{% /pageinfo %}}

## 什么是数字电路 ##

---

数字电路是一种利用两种不连续的电位来表示信息的电子电路。在数字电路中，通常使用两个电源电压，分别表示高电平（H）和低电平（L），分别代表数字1和0。这样的表示方式通过离散的电信号，以二进制形式传递和处理信息。

大多数数字电路的实现基于场效应管，其中最常用的是 MOSFET（Metal-Oxide-Semiconductor Field-Effect Transistor，金属氧化物半导体场效应管）。MOSFET 是一种半导体器件，可以在电场的控制下调控电流流动，从而实现数字信号的处理。

在数字电路中，MOSFET 被组合成各种逻辑电路，如与门、或门、非门等。这些逻辑门通过不同的组合方式，构建了数字电路中的各种功能和操作。以下是一些数字电路的基本特征：

**(1) 电位表示信息：** 数字电路使用两种电位，即高电平和低电平，来表示数字信息。通常，高电平代表数字1，低电平代表数字0。

**(2) MOSFET 实现：** MOSFET 是数字电路中最常用的元件之一。通过控制 MOSFET 的导通和截止状态，可以实现数字信号的处理和逻辑运算。

**(3) 逻辑门的组合：** 逻辑门是数字电路的基本构建块，由 MOSFET 组成。通过组合不同的逻辑门，可以构建复杂的数字电路，实现各种逻辑功能。

**(4) 二进制表达：** 数字电路中的信息通常使用二进制系统进行表示。每个数字都可以由一串二进制位组成，这些位可以在数字电路中被处理和操作。

**(5) 电平转换和信号处理：** 数字电路通过电平的变化和逻辑操作，实现信号的转换和处理。这种离散的处理方式使得数字电路非常适用于计算和信息处理任务。


## 为什么要学习数字电路 ##

---

学习数字电路是芯片验证过程中的基础和必要前提，主要体现在以下多个方面：

**(1) 理解设计原理：** 数字电路是芯片设计的基础，了解数字电路的基本原理和设计方法是理解芯片结构和功能的关键。芯片验证的目的是确保设计的数字电路在实际硬件中按照规格正常工作，而理解数字电路原理是理解设计的关键。

**(2) 设计规范：** 芯片验证通常涉及验证设计是否符合特定的规范和功能要求。学习数字电路可以帮助理解这些规范，从而更好地构建测试用例和验证流程，确保验证的全面性和准确性。

**(3) 时序和时钟：** 时序问题是数字电路设计和验证中的常见挑战。学习数字电路可以帮助理解时序和时钟的概念，以确保验证过程中能够正确处理时序问题，避免电路中的时序迟滞和冲突。

**(4) 逻辑分析：** 芯片验证通常涉及对逻辑的分析，确保电路的逻辑正确性。学习数字电路可以培养对逻辑的深刻理解，从而更好地进行逻辑分析和故障排查。

**(5) 测试用例编写：** 在芯片验证中，需要编写各种测试用例来确保设计的正确性。对数字电路的理解可以帮助设计更全面、有针对性的测试用例，涵盖电路的各个方面。

**(6) 信号完整性：** 学习数字电路有助于理解信号在电路中的传播和完整性问题。在芯片验证中，确保信号在不同条件下的正常传递是至关重要的，特别是在高速设计中。


整体而言，学习数字电路为芯片验证提供了基础知识和工具，使验证工程师能够更好地理解设计，编写有效的测试用例，分析验证结果，并解决可能出现的问题。数字电路的理论和实践经验对于芯片验证工程师来说都是不可或缺的。


## 数字电路基础知识 ##

可以通过以下在线资源进行数字电路学习：

- [清华大学数字电路基础](https://www.xuetangx.com/course/THU08081000386/19317632)
- [中科大数字电路实验](https://soc.ustc.edu.cn/Digital/)
- [数字设计和计算机体系结构](https://github.com/apachecn/huazhang-cs-books/blob/master/%E6%95%B0%E5%AD%97%E8%AE%BE%E8%AE%A1%E5%92%8C%E8%AE%A1%E7%AE%97%E6%9C%BA%E4%BD%93%E7%B3%BB%E7%BB%93%E6%9E%84%E5%8E%9F%E4%B9%A6%E7%AC%AC2%E7%89%88.pdf)
- [MIT 数字集成电路分析与设计](https://ocw.mit.edu/courses/6-374-analysis-and-design-of-digital-integrated-circuits-fall-2003/download/)

## 硬件描述语言Chisel ##

---


### 传统描述语言
硬件描述语言（Hardware Description Language，简称 HDL）是一种用于描述数字电路、系统和硬件的语言。它允许工程师通过编写文本文件来描述硬件的结构、功能和行为，从而实现对硬件设计的抽象和建模。

HDL 通常被用于设计和仿真数字电路，如处理器、存储器、控制器等。它提供了一种形式化的方法来描述硬件电路的行为和结构，使得设计工程师可以更方便地进行硬件设计、验证和仿真。

常见的硬件描述语言包括：

- Verilog：Verilog 是最常用的 HDL 之一，它是一种基于事件驱动的硬件描述语言，广泛应用于数字电路设计、验证和仿真。
- VHDL：VHDL 是另一种常用的 HDL，它是一种面向对象的硬件描述语言，提供了更丰富的抽象和模块化的设计方法。
- SystemVerilog：SystemVerilog 是 Verilog 的扩展，它引入了一些高级特性，如对象导向编程、随机化测试等，使得 Verilog 更适用于复杂系统的设计和验证。

### Chisel

Chisel 是一种现代化高级的硬件描述语言，与传统的 Verilog 和 VHDL 不同，它是基于 Scala 编程语言的硬件构建语言。Chisel 提供了一种更加现代化和灵活的方法来描述硬件，通过利用 Scala 的特性，可以轻松地实现参数化、抽象化和复用，同时保持硬件级别的效率和性能。

Chisel 的特点包括：

- 现代化的语法：Chisel 的语法更加接近软件编程语言，如 Scala，使得硬件描述更加直观和简洁。
- 参数化和抽象化：Chisel 支持参数化和抽象化，可以轻松地创建可配置和可重用的硬件模块。
- 类型安全：Chisel 是基于 Scala 的，因此具有类型安全的特性，可以在编译时检测到许多错误。
- 生成性能优化的硬件：Chisel 代码可以被转换成 Verilog，然后由标准的 EDA 工具链进行综合、布局布线和仿真，生成性能优化的硬件。
- 强大的仿真支持：Chisel 提供了与 ScalaTest 和 Firrtl 集成的仿真支持，使得对硬件进行仿真和验证更加方便和灵活。

#### Chisel版的全加法器实例

电路设计如下图所示：

{{< figure src="fulladder.png" alt="全加器电路" width="500px" >}}

完整的Chisel代码如下：

```verilog
package examples

import chisel3._

class FullAdder extends Module {
  // Define IO ports
  val io = IO(new Bundle {
    val a = Input(UInt(1.W))    // Input port 'a' of width 1 bit
    val b = Input(UInt(1.W))    // Input port 'b' of width 1 bit
    val cin = Input(UInt(1.W))  // Input port 'cin' (carry-in) of width 1 bit
    val sum = Output(UInt(1.W)) // Output port 'sum' of width 1 bit
    val cout = Output(UInt(1.W))// Output port 'cout' (carry-out) of width 1 bit
  })

  // Calculate sum bit (sum of a, b, and cin)
  val s1 = io.a ^ io.b               // XOR operation between 'a' and 'b'
  io.sum := s1 ^ io.cin              // XOR operation between 's1' and 'cin', result assigned to 'sum'

  // Calculate carry-out bit
  val s3 = io.a & io.b               // AND operation between 'a' and 'b', result assigned to 's3'
  val s2 = s1 & io.cin               // AND operation between 's1' and 'cin', result assigned to 's2'
  io.cout := s2 | s3                 // OR operation between 's2' and 's3', result assigned to 'cout'
}

```

Chisel 学习材料可以参考官方文档：[https://www.chisel-lang.org/docs](https://www.chisel-lang.org/docs)
