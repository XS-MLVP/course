---
title: 多时钟
description: 多时钟示例
categories: [示例项目, 教程] 
tags: [examples, docs]
weight: 5
draft: true
---


部分电路有多个时钟，XClock类提供了分频功能，可以通过它实现对多时钟电路的驱动。

## XClock 中的FreqDivWith接口

XClock函数提供如下分频接口
```c++
void XClock::FreqDivWith(int div,   // 分频数，，即绑定的XClock的频率为原时钟频率的div分之1
                     XClock &clk,   // 绑定的XClock
                     int shift=0)   // 对波形进行 shift 个半周期的移位
```

## XClock的一般驱动流程

1. 创建XClock，绑定DUT的驱动函数
1. 绑定关联clk引脚
1. 通过XPort绑定与clk关联的引脚
1. 根据需要设置回调
1. 根据需要设置分频


## 多时钟案例

例如多时钟电路有6个clock，每个clock都有一个对应的计数器，设计代码如下：
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

可以通过如下Python进行多时钟驱动：
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

上述代码输出的波形如下：TBD
