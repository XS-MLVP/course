---
title: 多时钟
description: 多时钟示例
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 5
draft: true
---

部分电路有多个时钟，XClock 类提供了分频功能，可以通过它实现对多时钟电路的驱动。

## XClock 中的 FreqDivWith 接口

XClock 函数提供如下分频接口

```c++
void XClock::FreqDivWith(int div,   // 分频数，，即绑定的XClock的频率为原时钟频率的div分之1
                     XClock &clk,   // 绑定的XClock
                     int shift=0)   // 对波形进行 shift 个半周期的移位
```

## XClock 的一般驱动流程

1. 创建 XClock，绑定 DUT 的驱动函数

```python
# 假设已经创建了DUT，并将其命名为dut
# 创建XClock
xclock = XClock(dut.dut.simStep)
```

2. 绑定关联 clk 引脚

```python
# clk是dut的时钟引脚
xclock.Add(dut.clk)
# Add方法具有别名：AddPin
```

3. 通过 XPort 绑定与 clk 关联的引脚

因为在我们的工具中，对于端口的读写是通过 xclock 来驱动的，所以如果不将与 clk 关联的引脚绑定到 XClock 上，那么在驱动时，相关的引脚数值不会发生变化。  
比如，我们要进行复位操作，那么可以将 reset 绑定到 xclock 上。

方法：

```python
class XClock:
    def Add(xport)       #将Clock和XData进行绑定
```

举例：

```python
# xclock.Add(dut.xport.Add(pin_name, XData))
xclock.Add(dut.xport.Add("reset", dut.reset))
```

---

在经过了前面的绑定之后，接下来可以使用了。  
我们根据需要来设置回调、设置分频。当然，时序电路肯定也要驱动时钟。  
这些方法都可以参照[工具介绍](https://xs-mlvp.github.io/mlvp/docs/env_usage/picker_usage/#xclock-%E7%B1%BB)。

下面是举例：

```python
# func为回调函数，args为自定义参数
#设置上升沿回调函数
dut.StepRis(func, args=(), kwargs={})
#设置下降沿回调函数
dut.StepFal(func, args=(), kwargs={})
# 假设xclock是XClock的实例
xclock.FreqDivWith(2, half_clock)           # 将xclock的频率分频为原来的一半
xclock.FreqDivWith(1, left_clock， -2)      # 将xclock的频率不变，对波形进行一个周期的左移
dut.Step(10) #推进10个时钟周期
```

## 多时钟案例

例如多时钟电路有 6 个 clock，每个 clock 都有一个对应的计数器，设计代码如下：

```verilog
module multi_clock (
    input wire clk1,
    input wire clk2,
    input wire clk3,
    input wire clk4,
    input wire clk5,
    input wire clk6,
    output reg [31:0] reg1,
    output reg [31:0] reg2,
    output reg [31:0] reg3,
    output reg [31:0] reg4,
    output reg [31:0] reg5,
    output reg [31:0] reg6
);
    initial begin
        reg1 = 32'b0;
        reg2 = 32'b0;
        reg3 = 32'b0;
        reg4 = 32'b0;
        reg5 = 32'b0;
        reg6 = 32'b0;
    end
    always @(posedge clk1) begin
        reg1 <= reg1 + 1;
    end
    always @(posedge clk2) begin
        reg2 <= reg2 + 1;
    end
    always @(posedge clk3) begin
        reg3 <= reg3 + 1;
    end
    always @(posedge clk4) begin
        reg4 <= reg4 + 1;
    end
    always @(posedge clk5) begin
        reg5 <= reg5 + 1;
    end
    always @(posedge clk6) begin
        reg6 <= reg6 + 1;
    end
endmodule
```

可以通过如下 Python 进行多时钟驱动：

```python

from MultiClock import *
from xspcomm import XClock

def test_multi_clock():
    # 创建DUT
    dut = DUTmulti_clock()
    # 创建主时钟
    main_clock = XClock(dut.dut.simStep)
    # 创建子时钟
    clk1, clk2, clk3 = XClock(lambda x: 0), XClock(lambda x: 0), XClock(lambda x: 0)
    clk4, clk5, clk6 = XClock(lambda x: 0), XClock(lambda x: 0), XClock(lambda x: 0)
    # 给子时钟添加相关的clock引脚及关联端口
    clk1.Add(dut.xport.SelectPins(["reg1"])).AddPin(dut.clk1.xdata)
    clk2.Add(dut.xport.SelectPins(["reg2"])).AddPin(dut.clk2.xdata)
    clk3.Add(dut.xport.SelectPins(["reg3"])).AddPin(dut.clk3.xdata)
    clk4.Add(dut.xport.SelectPins(["reg4"])).AddPin(dut.clk4.xdata)
    clk5.Add(dut.xport.SelectPins(["reg5"])).AddPin(dut.clk5.xdata)
    clk6.Add(dut.xport.SelectPins(["reg6"])).AddPin(dut.clk6.xdata)
    # 将主时钟频率分频到子时钟
    main_clock.FreqDivWith(1, clk1)
    main_clock.FreqDivWith(2, clk2)
    main_clock.FreqDivWith(3, clk3)
    main_clock.FreqDivWith(1, clk4, -1)
    main_clock.FreqDivWith(2, clk5, 1)
    main_clock.FreqDivWith(3, clk6, 2)
    # 驱动时钟
    main_clock.Step(100)
    dut.Finish()

if __name__ == "__main__":
    test_multi_clock()
```

上述代码输出的波形如下：

![multi_clock](multiclock.png)

可以看到：

- clk2 的周期是 clk1 的 2 倍
- clk3 的周期是 clk1 的 3 倍，
- clk4 的周期和 clk1 相同，但是进行了半个周期的右移
- clk5 的周期和 clk2 相同，但是进行了半个周期的左移
- clk6 的周期和 clk3 相同，但是进行了一个周期的左移
