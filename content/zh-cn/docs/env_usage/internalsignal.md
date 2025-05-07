---
title: 内部信号
description: 内部信号示例
categories: [示例项目, 教程] 
tags: [examples, docs]
weight: 7
draft: false
---

内部信号是指未在模块IO端口中暴露，但在模块内部承担控制、数据传输或状态跟踪等功能的信号。通常，picker在将RTL转换为DUT时只会自动暴露IO端口，内部信号不会被主动导出。

但在需要对模块内部逻辑进行更细致验证，或根据已知bug进一步定位问题时，验证人员往往需要访问这些内部信号。除了传统的verilator和VCS等工具，picker还提供了内部信号提取机制，可作为辅助手段。 

## 动机

以上限计数器为例：

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

该部分中的 clk、reset 和 count 是 IO 信号，可以直接暴露访问。而紧接着的 `wire upper;` 则属于内部信号，其取值由模块输入和模块内部逻辑共同决定。本案例中的计数器逻辑较为简单，但对于更大规模的硬件模块，常常会遇到以下难题：

- 当模块输出与预期不符时，问题范围较大，难以及时定位，需要有效手段快速缩小排查范围；
- 模块内部逻辑复杂，理解和分析存在困难，此时也需要借助内部信号作为关键标记，理清模块运行机制。

针对上述问题，访问和分析内部信号是非常有效的手段。传统上，通常借助如 Verilator、VCS 等仿真工具来查看内部信号。**为进一步降低验证门槛，picker 还提供了三种内部信号访问方式：DPI 直接导出、VPI 动态访问和直接内存读写。**

## DPI 直接导出

DPI即Direct Programming Interface，是verilog与其他语言交互的接口，在picker的默认实现中，支持了为待测硬件模块的IO端口提供DPI。在执行picker时，如果添加了\-\-internal
选项，则可同样为待测模块的内部信号提供DPI。此时，picker将会基于预定义的内部信号文件，在将verilog转化为DUT时，同步抽取rtl中的内部信号和IO端口一并暴露出来。

### 编写信号文件

信号文件是我们向picker指定需要提取的内部信号的媒介，它规定了需提取内部信号的模块和该模块需要提取的内部信号。

示例internal\.yaml，内容如下：

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

### 信号访问

picker完成提取之后，内部信号的访问和io信号的访问就没有什么区别了，本质上他们都是dut上的一个XData，使用“dut\.信号名”的方式访问即可。

```python
from UpperCounter import *

def test():
    dut = DUTUpperCounter()
    print(dut.UpperCounter_upper.value)
```

## VPI动态访问

VPI（Verilog Procedural Interface）是Verilog语言的一种标准接口，用于在仿真时让C语言等外部程序与Verilog仿真器进行交互。通过VPI，用户可以在C程序中访问、读取、修改Verilog仿真中的信号、变量、模块实例等信息，还可以注册回调函数，实现对仿真过程的控制和扩展。VPI常用于开发自定义系统任务、实现高级验证功能、动态信号访问和波形处理等。VPI 是 IEEE 1364 标准的一部分。

### 选项支持

```bash
picker export --help
...
--vpi Enable VPI, for flexible internal signal access default is OFF
```
可通过参数`--vpi`开启VPI支持，例如：

```bash
picker export upper_counter.sv --sname UpperCounter --tdir picker_out_upper_counter/ --lang python --vpi
```

### 信号访问
开启`--vpi`后，可通过DUT的接口`dut.GetInternalSignalList(use_vpi=True)`列出所有内部可访问信号，通过`dut.GetInternalSignal(name, use_vpi=True)`动态构建XData进行数据访问。

```python
from UpperCounter import *

def test():
    dut = DUTUpperCounter()
    # 列出所有内部信号
    # 或者通过 dut.VPIInternalSignalList()
    dut.GetInternalSignalList(use_vpi=True)
    # 动态构建 XData
    internal_upper = dut.GetInternalSignal("UpperCounter.upper", use_vpi=True)
    # 读访问
    print(internal_upper.value)
    # 写访问 (虽然能写入，但是dut step后值会被覆盖，不建议对非reg类型进行写操作)
    internal_upper.value = 0x1
```

## 直接内存读写

无论是基于DPI还是VPI进行内部信号访问都有一定的性能开销，为了实现极致性能体验，picker针对verilator/GSIM仿真器实现了内部信号直接访问。

### 选项支持

```bash
picker export --help
...
--rw,--access-mode ENUM:value in {dpi->0,mem_direct->1} OR {0,1}
```
可通过参数`--rw 1`开启针对verilator仿真器内部信号直接读写功能，例如：
```bash
picker export upper_counter.sv --sname UpperCounter --tdir picker_out_upper_counter/ --lang python --rw 1
```

### 信号访问

开启`直接内存读写`后，可通过`dut.GetInternalSignalList(use_vpi=False)`列出所有内部信号，通过`dut.GetInternalSignal(name, use_vpi=False)`动态构建XData实现信号读写。

```python
from UpperCounter import *

def test():
    dut = DUTUpperCounter()
    # 列出所有内部信号
    dut.GetInternalSignalList(use_vpi=False)
    # 动态构建 XData
    internal_upper = dut.GetInternalSignal("UpperCounter_top.UpperCounter.upper", use_vpi=False)
    # 读访问
    print(internal_upper.value)
    # 写访问 (虽然能写入，但是dut step后值会被覆盖，不建议对非reg类型进行写操作)
    internal_upper.value = 0x1
```

## 内部信号访问方法对比

picker提供的每种内部信号访问方法都有各自的优缺点，需要按需要进行选择。

|方法名称|开启参数|优点|缺点|访问接口|支持仿真器|适用场景|
|-|-|-|-|-|-|-|
|DPI 直接导出|--internal=cfg.yaml|速度快|需要提前指定信号<br>信号只读<br>修改后需要重新编译|无（同普通引脚）|verilator、VCS|信号少，不需要写操作|
|VPI动态访问|--vpi|灵活，信号全<br>不需要提前指定信号|速度慢|GetInternalSignalList<br>GetInternalSignal|verilator、VCS|小规模电路或不在意仿真速度
|直接内存读写|--rw 1|速度快<br>灵活<br>不需要提前指定信号|部分信号可能被优化掉|GetInternalSignalList<br>GetInternalSignal|verilator、GSIM|大规模电路，例如整个香山核|

*注： 上述方法彼此独立，可以混用
