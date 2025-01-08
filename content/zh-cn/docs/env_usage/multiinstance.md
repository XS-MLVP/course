---
title: 多实例
description: 多实例示例
categories: [示例项目, 教程] 
tags: [examples, docs]
weight: 6
draft: false
---

在Verilog中，一个module只有一个实例，但很多测试场景下需要实现多个module，为此picker提供了动态多实例和静态多实例的支持。

## 动态多实例

动态多实例相当于类的实例化，在创建dut的同时实例化对应的module，所以用户无感知。支持最大16个实例同时运行。

例子：

以Adder为例，我们可以在测试时根据需要在合适的位置创建多个dut，来动态创建多个Adder实例。
当需要销毁一个dut时，也不会影响后续创建新的dut。

创建一个名为 picker_out_adder 的文件夹，其中包含一个 Adder.v 文件。该文件的源码参考[案例一：简单加法器](https://xs-mlvp.github.io/mlvp/docs/quick-start/eg-adder/)。

运行下述命令将RTL导出为 Python Module：

```bash
picker export Adder.v --autobuild true -w Adder.fst --sname Adder
```

在picker_out_adder中添加 `example.py`，动态创建多个Adder实例：

```python
from Adder import *

import random

def random_int():
    return random.randint(-(2**127), 2**127 - 1) & ((1 << 127) - 1)

def main():
    dut=[]
    # 可以通过创建多个dut，实例化多个Adder，理论上支持最大16个实例同时运行
    for i in range(7):
        # 这里通过循环创建了7个dut
        dut.append(DUTAdder(waveform_filename=f"{i}.fst"))
    for d in dut:
        d.a.value = random_int()
        d.b.value = random_int()
        d.cin.value = random_int() & 1
        d.Step(1)
        print(f"DUT: sum={d.sum.value}, cout={d.cout.value}")
        # 通过Finish()函数在合适的时机撤销某个dut，也即销毁某个实例
        d.Finish()
    # 可以根据需要在合适的时机创建新的Adder实例
    # 下面创建了一个新的dut，旨在说明可以在程序结束前的任何时机创建新的dut
    dut_new = DUTAdder(waveform_filename=f"new.fst")
    dut_new.a.value = random_int()
    dut_new.b.value = random_int()
    dut_new.cin.value = random_int() & 1
    dut_new.Step(1)
    print(f"DUT: sum={dut_new.sum.value}, cout={dut_new.cout.value}")
    dut_new.Finish()

if __name__ == "__main__":
    main()
```
注：目前仅支持 verilator模拟器


## 静态多实例
静态多实例的使用不如动态多实例灵活，相当于在进行dut封装时就创建了n个目标模块。
需要在使用 picker 生成 dut_top.sv/v 的封装时，通过--sname参数指定多个模块名称和对应的数量。

### 单个模块需要多实例

同样以Adder为例，在使用picker对dut进行封装时执行如下命令：

```bash
picker export Adder.v --autobuild true -w Adder.fst --sname Adder,3
```
通过--sname参数指定在dut中创建3个Adder，封装后dut的引脚定义为：
```python
# init.py 
# 这里仅放置了部分代码
class DUTAdder(object):
        ...
        # all Pins
        # 静态多实例
        self.Adder_0_a = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_0_b = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_0_cin = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.Adder_0_sum = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.Adder_0_cout = xsp.XPin(xsp.XData(0, xsp.XData.Out), self.event)
        self.Adder_1_a = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_1_b = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_1_cin = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.Adder_1_sum = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.Adder_1_cout = xsp.XPin(xsp.XData(0, xsp.XData.Out), self.event)
        self.Adder_2_a = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_2_b = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_2_cin = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.Adder_2_sum = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.Adder_2_cout = xsp.XPin(xsp.XData(0, xsp.XData.Out), self.event)
        ...
```
可以看到在 picker 生成 dut 时，就在 DUTAdder 内创建了多个Adder实例。

下面是简单的多实例代码举例：
```python
from Adder import *

import random

def random_int():
    return random.randint(-(2**127), 2**127 - 1) & ((1 << 127) - 1)

def main():
    # 在dut内部实例化了多个Adder
    dut = DUTAdder(waveform_filename = "1.fst")
    dut.Adder_0_a.value = random_int()
    dut.Adder_0_b.value = random_int()
    dut.Adder_0_cin.value = random_int() & 1
    dut.Adder_1_a.value = random_int()
    dut.Adder_1_b.value = random_int()
    dut.Adder_1_cin.value = random_int() & 1
    dut.Adder_2_a.value = random_int()
    dut.Adder_2_b.value = random_int()
    dut.Adder_2_cin.value = random_int() & 1
    dut.Step(1)
    print(f"Adder_0: sum={dut.Adder_0_sum.value}, cout={dut.Adder_0_cout.value}")
    print(f"Adder_1: sum={dut.Adder_1_sum.value}, cout={dut.Adder_1_cout.value}")
    print(f"Adder_2: sum={dut.Adder_2_sum.value}, cout={dut.Adder_2_cout.value}")
    # 静态多实例不可以根据需要动态的创建新的Adder实例，三个Adder实例的周期与dut的生存周期相同
    dut.Finish()

if __name__ == "__main__":
    main()
```

### 多个模块需要多实例

例如在 Adder.v 和 RandomGenerator.v 设计文件中分别有模块 Adder 和 RandomGenerator，RandomGenerator.v文件的源码为：

```verilog
module RandomGenerator (
    input wire clk,
    input wire reset,
    input [127:0] seed,
    output [127:0] random_number
);
    reg [127:0] lfsr;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= seed;
        end else begin
            lfsr <= {lfsr[126:0], lfsr[127] ^ lfsr[126]};
        end
    end

    assign random_number = lfsr;
endmodule
```

需要 DUT 中有 2 个 Adder，3 个 RandomGenerator，生成的模块名称为 RandomAdder（若不指定，默认名称为 Adder_Random），则可执行如下命令：

```bash
picker export Adder.v,RandomGenerator.v --sname Adder,2,RandomGenerator,3 --tname RandomAdder -w randomadder.fst
```

得到封装后的dut为`DUTRandomAdder`，包含2个Adder实例和3个RandomGenerator实例。

封装后dut的引脚定义为：

```python
# init.py 
# 这里仅放置了部分代码
class DUTRandomAdder(object):
        ...
        # all Pins
        # 静态多实例
        self.Adder_0_a = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_0_b = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_0_cin = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.Adder_0_sum = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.Adder_0_cout = xsp.XPin(xsp.XData(0, xsp.XData.Out), self.event)
        self.Adder_1_a = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_1_b = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.Adder_1_cin = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.Adder_1_sum = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.Adder_1_cout = xsp.XPin(xsp.XData(0, xsp.XData.Out), self.event)
        self.RandomGenerator_0_clk = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_0_reset = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_0_seed = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.RandomGenerator_0_random_number = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.RandomGenerator_1_clk = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_1_reset = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_1_seed = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.RandomGenerator_1_random_number = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        self.RandomGenerator_2_clk = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_2_reset = xsp.XPin(xsp.XData(0, xsp.XData.In), self.event)
        self.RandomGenerator_2_seed = xsp.XPin(xsp.XData(128, xsp.XData.In), self.event)
        self.RandomGenerator_2_random_number = xsp.XPin(xsp.XData(128, xsp.XData.Out), self.event)
        ...
```

可以看到在 picker 生成 dut 时，就在 DUTAdder 内创建了多个Adder实例。

对应的测试代码举例为：

```python
from RandomAdder import *

import random

def random_int():
    return random.randint(-(2**127), 2**127 - 1) & ((1 << 127) - 1)

def main():
    # 在dut内部实例化了多个Adder
    dut = DUTRandomAdder()
    dut.InitClock("RandomGenerator_0_clk")
    dut.InitClock("RandomGenerator_1_clk")
    dut.InitClock("RandomGenerator_2_clk")
    dut.Adder_0_a.value = random_int()
    dut.Adder_0_b.value = random_int()
    dut.Adder_0_cin.value = random_int() & 1
    dut.Adder_1_a.value = random_int()
    dut.Adder_1_b.value = random_int()
    dut.Adder_1_cin.value = random_int() & 1
    
    # 在dut内部实例化了多个RandomGenerator
    seed = random.randint(0, 2**128 - 1)
    dut.RandomGenerator_0_seed.value = seed
    dut.RandomGenerator_0_reset.value = 1
    dut.Step(1)
    for i in range(10):
        print(f"Cycle {i}, DUT: {dut.RandomGenerator_0_random_number.value:x}")
        dut.Step(1)
    dut.RandomGenerator_1_seed.value = seed
    dut.RandomGenerator_1_reset.value = 1
    dut.Step(1)
    for i in range(10):
        print(f"Cycle {i}, DUT: {dut.RandomGenerator_1_random_number.value:x}")
        dut.Step(1)
    dut.RandomGenerator_2_seed.value = seed
    dut.RandomGenerator_2_reset.value = 1
    dut.Step(1)
    for i in range(10):
        print(f"Cycle {i}, DUT: {dut.RandomGenerator_2_random_number.value:x}")
        dut.Step(1)
    print(f"Adder_0: sum={dut.Adder_0_sum.value}, cout={dut.Adder_0_cout.value}")
    print(f"Adder_1: sum={dut.Adder_1_sum.value}, cout={dut.Adder_1_cout.value}")
    # 静态多实例各个模块多个实例的生命周期与dut的生命周期相同
    dut.Finish()

if __name__ == "__main__":
    main()
```
