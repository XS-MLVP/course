---
title: 内部信号
description: 内部信号示例
categories: [示例项目, 教程] 
tags: [examples, docs]
weight: 7
draft: true
---

内部信号指的是不在模块的IO端口中暴露，但会在模块内部发挥控制、数据传输、状态跟踪功能的信号。一般来说，在picker将rtl转换成dut的过程中，只有IO端口才会被暴露，这些信号不会被主动暴露。

然而，当验证人员需要寻求对模块内部逻辑更精细的验证，或者需要根据已知的bug进一步定位问题时，就需要接触硬件模块内部的信号，此时除了使用verilator和VCS这些传统工具以外，也可以采用picker提供的内部信号提取机制作为辅助。 

## 动机

以一个自带上限的计数器为例：

```verilog

module UpperCounter (
    input wire clk,           
    input wire reset,         
    output reg [3:0] count   
);
    wire upper;

    assign upper = (count == 4'b1111);

    always @(posedge clk) begin
        if (reset) begin
            count = 4'b0000;
        end else if (!upper) begin
            count = count + 1;
        end
    end
endmodule

```

模块的IO信号指的是直接写在模块定义中的信号，也就是：

```verilog
module UpperCounter (
    input wire clk,           
    input wire reset,         
    output reg [3:0] count   
);
```

该部分中的clk，reset和count即IO信号，是可以暴露出来的。

而紧接着的"wire upper;"也就是内部信号，其值是由模块的输入和模块内部的行为共同决定的。

本案例的计数器逻辑相对简单，然而，对于规模较大的硬件模块，则存在以下痛点：

当模块最终的输出和预期不符，存在问题的代码范围较大，亟需快速缩小问题范围的手段，

模块内部逻辑复杂，理解存在困难，此时也需要一些内部标记理清模块的关键逻辑。

对于以上痛点，都可以考虑诉诸内部信号。传统的查看内部信号的方式包括使用verilator和VCS。为进一步降低验证人员的使用门槛，我们的picker也提供了以下两种导出内部信号的方法：
DPI直接导出和VPI动态导出。

## DPI 直接导出

DPI即Direct Programming Interface，是verilog与其他语言交互的接口，在picker的默认实现中，支持了为待测硬件模块的IO端口提供DPI。在执行picker时，如果添加了\-\-internal
选项，则可同样为待测模块的内部信号提供DPI。此时，picker将会基于预定义的内部信号文件，在将verilog转化为DUT时，同步抽取rtl中的内部信号和IO端口一并暴露出来。

### 编写信号文件

信号文件是我们向picker指定需要提取的内部信号的媒介，它规定了需提取内部信号的模块和该模块需要提取的内部信号。

我们创建一个internal\.yaml，内容如下：

```yaml
UpperCounter:
  - "wire upper"
```

第一行是模块名称，如UpperCounter，第二行开始是需要提取的模块内部信号，以“类型&emsp;信号名”的格式写出。比如，upper的类型为wire，我们就写成“wire&emsp;upper”
（理论上只要信号名符合verilog代码中的变量名就可以匹配到对应的信号，类型随便写都没问题，但还是建议写verilog语法支持的类型，比如wire、log、logic等）

内部信号提取的能力取决于模拟器，譬如，verilator就无法提取下划线\_开头的信号。

注：多位宽的内部信号需要显式写出位宽，所以实际的格式是“类型&emsp;\[宽度\]&emsp;信号名”

```yaml
UpperCounter:
  - "wire upper"
  - "reg [3:0] another_multiples" # 本案例中这个信号不存在，只是用于说明yaml的格式
```

### 选项支持

写好信号文件之后，需要在运行picker时显式指定内部文件，这通过internal选项完成：

```bash
--internal=[internal_signal_file]
```

完整命令如下：

```bash
picker export --autobuild=true upper_counter.sv -w upper_counter.fst --sname UpperCounter \
--tdir picker_out_upper_counter/ --lang python -e --sim verilator --internal=internal.yaml

```

我们可以找到picker为DUT配套生成的signals.json文件：

```json
{
    "UpperCounter_upper": {
        "High": -1,
        "Low": 0,
        "Pin": "wire",
        "_": true
    },
    "clk": {
        "High": -1,
        "Low": 0,
        "Pin": "input",
        "_": true
    },
    "count": {
        "High": 3,
        "Low": 0,
        "Pin": "output",
        "_": true
    },
    "reset": {
        "High": -1,
        "Low": 0,
        "Pin": "input",
        "_": true
    }
}
```

这个文件展示了picker生成的信号接口，可以看到，第一个信号UpperCounter\_upper就是我们需要提取的内部信号，
其中第一个下划线之前的部分是我们在internal\.yaml中的第一行定义的模块名UpperCounter，后面的部分则是内部信号名。

### 访问信号

picker完成提取之后，内部信号的访问和io信号的访问就没有什么区别了，本质上他们都是dut上的一个XData，使用“dut\.信号名”的方式访问即可。

```python

print(dut.UpperCounter_upper.value)

```

### 优点

DPI直接导出在编译dut的过程中完成内部信号的导出，没有引入额外的运行时损耗，运行速度快。

### 局限

1、在编译DUT时，导出的内部信号就已经确定了，如果在测试中需要修改调用的内部信号，则需要重新修改内部信号文件并用picker完成转化。

2、导出的内部信号只可读取，不可写入，如果需要写入，则需要考虑接下来要介绍的VPI动态获取方法。

## VPI 动态获取

TBD

优点：动态获取，能读能写
缺点：速度慢，请谨慎使用

