---
title: 案例三：双端口栈——基于回调的驱动
description: 双端口栈是一个拥有两个端口的栈，每个端口都支持push和pop操作。本案例以双端口栈为例，展示如何使用回调函数驱动DUT
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 5
---

## 双端口栈简介

双端口栈是一种数据结构，支持两个端口同时进行操作。与传统单端口栈相比，双端口栈允许同时进行数据的读写操作，在例如多线程并发读写等场景下，双端口栈能够提供更好的性能。本例中，我们提供了一个简易的双端口栈实现，其源码如下：

```verilog
module dual_port_stack (
    input clk,
    input rst,

    // Interface 0
    input in0_valid,
    output in0_ready,
    input [7:0] in0_data,
    input [1:0] in0_cmd,
    output out0_valid,
    input out0_ready,
    output [7:0] out0_data,
    output [1:0] out0_cmd,

    // Interface 1
    input in1_valid,
    output in1_ready,
    input [7:0] in1_data,
    input [1:0] in1_cmd,
    output out1_valid,
    input out1_ready,
    output [7:0] out1_data,
    output [1:0] out1_cmd
);
    // Command definitions
    localparam CMD_PUSH = 2'b00;
    localparam CMD_POP = 2'b01;
    localparam CMD_PUSH_OKAY = 2'b10;
    localparam CMD_POP_OKAY = 2'b11;

    // Stack memory and pointer
    reg [7:0] stack_mem[0:255];
    reg [7:0] sp;
    reg busy;

    reg [7:0] out0_data_reg, out1_data_reg;
    reg [1:0] out0_cmd_reg, out1_cmd_reg;
    reg out0_valid_reg, out1_valid_reg;

    assign out0_data = out0_data_reg;
    assign out0_cmd = out0_cmd_reg;
    assign out0_valid = out0_valid_reg;
    assign out1_data = out1_data_reg;
    assign out1_cmd = out1_cmd_reg;
    assign out1_valid = out1_valid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sp <= 0;
            busy <= 0;
        end else begin
            // Interface 0 Request Handling
            if (!busy && in0_valid && in0_ready) begin
                case (in0_cmd)
                    CMD_PUSH: begin
                        busy <= 1;
                        sp <= sp + 1;
                        out0_valid_reg <= 1;
                        stack_mem[sp] <= in0_data;
                        out0_cmd_reg <= CMD_PUSH_OKAY;
                    end
                    CMD_POP: begin
                        busy <= 1;
                        sp <= sp - 1;
                        out0_valid_reg <= 1;
                        out0_data_reg <= stack_mem[sp - 1];
                        out0_cmd_reg <= CMD_POP_OKAY;
                    end
                    default: begin
                        out0_valid_reg <= 0;
                    end
                endcase
            end

            // Interface 1 Request Handling
            if (!busy && in1_valid && in1_ready) begin
                case (in1_cmd)
                    CMD_PUSH: begin
                        busy <= 1;
                        sp <= sp + 1;
                        out1_valid_reg <= 1;
                        stack_mem[sp] <= in1_data;
                        out1_cmd_reg <= CMD_PUSH_OKAY;
                    end
                    CMD_POP: begin
                        busy <= 1;
                        sp <= sp - 1;
                        out1_valid_reg <= 1;
                        out1_data_reg <= stack_mem[sp - 1];
                        out1_cmd_reg <= CMD_POP_OKAY;
                    end
                    default: begin
                        out1_valid_reg <= 0;
                    end
                endcase
            end

            // Interface 0 Response Handling
            if (busy && out0_ready) begin
                out0_valid_reg <= 0;
                busy <= 0;
            end

            // Interface 1 Response Handling
            if (busy && out1_ready) begin
                out1_valid_reg <= 0;
                busy <= 0;
            end
        end
    end

    assign in0_ready = (in0_cmd == CMD_PUSH && sp < 255|| in0_cmd == CMD_POP && sp > 0) && !busy;
    assign in1_ready = (in1_cmd == CMD_PUSH && sp < 255|| in1_cmd == CMD_POP && sp > 0) && !busy && !(in0_ready && in0_valid);

endmodule
```

在该实现中，除了时钟信号(clk)和复位信号(rst)之外，还包含了两个端口的输入输出信号，它们拥有相同的接口定义。每个端口的信号含义如下：

- 请求端口（in）
  - `in_valid` 输入数据有效信号
  - `in_ready` 输入数据准备好信号
  - `in_data` 输入数据
  - `in_cmd` 输入命令 （0:PUSH, 1:POP）
- 响应端口（out）
  - `out_valid` 输出数据有效信号
  - `out_ready` 输出数据准备好信号
  - `out_data` 输出数据
  - `out_cmd` 输出命令 （2:PUSH_OKAY, 3:POP_OKAY）

当我们想通过一个端口对栈进行一次操作时，首先需要将需要的数据和命令写入到输入端口，然后等待输出端口返回结果。

具体地，如果我们想对栈进行一次 PUSH 操作。首先我们应该将需要 PUSH 的数据写入到 `in_data` 中，然后将 `in_cmd` 设置为 0，表示 PUSH 操作，并将 `in_valid` 置为 1，表示输入数据有效。接着，我们需要等待 `in_ready` 为 1，保证数据已经正确的被接收，此时 PUSH 请求已经被正确发送。

命令发送成功后，我们需要在响应端口等待栈的响应信息。当 `out_valid` 为 1 时，表示栈已经完成了对应的操作，此时我们可以从 `out_data` 中读取栈的返回数据（POP 操作的返回数据将会放置于此），从 `out_cmd` 中读取栈的返回命令。当读取到数据后，需要将 `out_ready` 置为 1，以通知栈正确接收到了返回信息。

如果两个端口的请求同时有效时，栈将会优先处理端口 0 的请求。


## 构建驱动环境

与案例一和案例二类似，在对双端口栈进行测试之前，我们首先需要利用 Picker 工具将 RTL 代码构建为 Python Module。在构建完成后，我们将通过 Python 脚本驱动 RTL 代码进行测试。

首先，创建名为 `dual_port_stack.v` 的文件，并将上述的 RTL 代码复制到该文件中，接着在相同文件夹下执行以下命令：

```bash
picker export --autobuild=true dual_port_stack.v -w dual_port_stack.fst --sname dual_port_stack --tdir picker_out_dual_port_stack --lang python -e --sim verilator
```

生成好的驱动环境位于 `picker_out_dual_port_stack` 文件夹中, 其中 `UT_dual_port_stack` 为生成的 Python Module，`example.py` 为测试脚本。

可以通过以下命令运行测试脚本：

```bash
cd picker_out_dual_port_stack
python3 example.py
```

若运行过程中无错误发生，则代表环境被正确构建。

## 利用回调函数驱动 DUT

在本案例中，为了测试双端口栈的功能，我们需要对其进行驱动。但你可能很快就会发现，仅仅使用案例一和案例二中的方法很难对双端口栈进行驱动。因为在此前的测试中，DUT只有一条执行逻辑，给DUT输入数据后等待DUT输出即可。

但双端口栈却不同，它的两个端口是两个独立的执行逻辑，在驱动中，这两个端口可能处于完全不同的状态，例如端口0在等待DUT返回数据时，端口1有可能正在发送新的请求。这种情况下，使用简单的串行执行逻辑将很难对DUT进行驱动。

因此我们在本案例中我们将以双端口栈为例，介绍一种基于回调函数的驱动方法，来完成此类DUT的驱动。

### 回调函数简介

回调函数是一种常见的编程技术，它允许我们将一个函数传入，并等待某个条件满足后被调用。构建产生的 Python Module 中，我们提供了向内部执行环境注册回调函数的接口 `StepRis`，使用方法如下:

```python
from UT_dual_port_stack import DUTdual_port_stack

def callback(cycles):
    print(f"The current clock cycle is {cycles}")

dut = DUTdual_port_stack()
dut.StepRis(callback)
dut.Step(10)
```

你可以直接运行该代码来查看回调函数的效果。

在上述代码中，我们定义了一个回调函数 `callback` ，它接受一个参数 `cycles` ，并在每次调用时打印当前的时钟周期。接着通过 `StepRis` 将该回调函数注册到 DUT 中。

注册回调函数后，每运行一次 `Step` 函数，即每个时钟周期，都会在时钟信号上升沿去调用该回调函数，并传入当前的时钟周期。

通过这种方式，我们可以将不同的执行逻辑都写成回调函数的方式，并将多个回调函数注册到 DUT 中，从而实现对 DUT 的并行驱动。

### 基于回调函数驱动的双端口栈

通过回调函数的形式来完成一条完整的执行逻辑，通常我们会使用状态机的模式进行编写。每调用一次回调函数，就会引起状态机内部的状态变化，多次调用回调函数，就会完成一次完整的执行逻辑。

下面是一个基于回调函数驱动的双端口栈的示例代码：

```python
import random
from UT_dual_port_stack import *
from enum import Enum

class StackModel:
    def __init__(self):
        self.stack = []

    def commit_push(self, data):
        self.stack.append(data)
        print("push", data)

    def commit_pop(self, dut_data):
        print("Pop", dut_data)
        model_data = self.stack.pop()
        assert model_data == dut_data, f"The model data {model_data} is not equal to the dut data {dut_data}"
        print(f"Pass: {model_data} == {dut_data}")

class SinglePortDriver:
    class Status(Enum):
        IDLE = 0
        WAIT_REQ_READY = 1
        WAIT_RESP_VALID = 2

    class BusCMD(Enum):
        PUSH = 0
        POP = 1
        PUSH_OKAY = 2
        POP_OKAY = 3

    def __init__(self, dut, model: StackModel, port_dict):
        self.dut = dut
        self.model = model
        self.port_dict = port_dict

        self.status = self.Status.IDLE
        self.operation_num = 0
        self.remaining_delay = 0

    def push(self):
        self.port_dict["in_valid"].value = 1
        self.port_dict["in_cmd"].value = self.BusCMD.PUSH.value
        self.port_dict["in_data"].value = random.randint(0, 2**32-1)

    def pop(self):
        self.port_dict["in_valid"].value = 1
        self.port_dict["in_cmd"].value = self.BusCMD.POP.value

    def step_callback(self, cycle):
        if self.status == self.Status.WAIT_REQ_READY:
            if self.port_dict["in_ready"].value == 1:
                self.port_dict["in_valid"].value = 0
                self.port_dict["out_ready"].value = 1
                self.status = self.Status.WAIT_RESP_VALID

                if self.port_dict["in_cmd"].value == self.BusCMD.PUSH.value:
                    self.model.commit_push(self.port_dict["in_data"].value)

        elif self.status == self.Status.WAIT_RESP_VALID:
            if self.port_dict["out_valid"].value == 1:
                self.port_dict["out_ready"].value = 0
                self.status = self.Status.IDLE
                self.remaining_delay = random.randint(0, 5)

                if self.port_dict["out_cmd"].value == self.BusCMD.POP_OKAY.value:
                    self.model.commit_pop(self.port_dict["out_data"].value)

        if self.status == self.Status.IDLE:
            if self.remaining_delay == 0:
                if self.operation_num < 10:
                    self.push()
                elif self.operation_num < 20:
                    self.pop()
                else:
                    return

                self.operation_num += 1
                self.status = self.Status.WAIT_REQ_READY
            else:
                self.remaining_delay -= 1

def test_stack(stack):
    model = StackModel()

    port0 = SinglePortDriver(stack, model, {
        "in_valid": stack.in0_valid,
        "in_ready": stack.in0_ready,
        "in_data": stack.in0_data,
        "in_cmd": stack.in0_cmd,
        "out_valid": stack.out0_valid,
        "out_ready": stack.out0_ready,
        "out_data": stack.out0_data,
        "out_cmd": stack.out0_cmd,
    })

    port1 = SinglePortDriver(stack, model, {
        "in_valid": stack.in1_valid,
        "in_ready": stack.in1_ready,
        "in_data": stack.in1_data,
        "in_cmd": stack.in1_cmd,
        "out_valid": stack.out1_valid,
        "out_ready": stack.out1_ready,
        "out_data": stack.out1_data,
        "out_cmd": stack.out1_cmd,
    })

    dut.StepRis(port0.step_callback)
    dut.StepRis(port1.step_callback)

    dut.Step(200)


if __name__ == "__main__":
    dut = DUTdual_port_stack()
    dut.init_clock("clk")
    test_stack(dut)
    dut.finalize()
```

在上述代码中，实现了这样的驱动过程：每个端口独立对DUT进行驱动，并在一个请求完成后添加随机延迟，每个端口分别完成了 10 次 `PUSH` 操作与 10 次 `POP` 操作。

在 `PUSH` 或 `POP` 请求生效时，会调用同一个 `StackModel` 中的 `commit_push` 或 `commit_pop` 函数，以模拟栈的行为，并在每次 `POP` 操作完成后对比 DUT 的返回数据与模型的数据是否一致。

为了实现对单个端口的驱动行为，我们实现了 `SinglePortDriver` 类，其中实现了一个接口进行收发的完整过程，通过 `step_callback` 函数来实现内部的更新逻辑。

在测试函数 `test_stack` 中，我们为双端口栈的每一个端口都创建了一个 `SinglePortDriver` 实例，传入了对应的接口，并通过 `StepRis` 函数将其对应的回到函数其注册到 DUT 中。之后调用 `dut.Step(200)` 时，每个时钟周期中都会自动调用一次回调函数，来完成整个驱动逻辑。

**SinglePortDriver 驱动逻辑**

上面提到，一般使用回调函数的形式需要将执行逻辑实现为状态机，因此在 `SinglePortDriver` 类中，需要记录包含端口所处的状态，它们分别是：

- `IDLE`：空闲状态，等待下一次操作
  - 在空闲状态下，需要查看另一个状态 `remaining_delay` 来判断当前是否已经延时结束，如果延时结束可立即进行下一次操作，否则继续等待。
  - 当需要执行下一次操作时，需要查看状态 `operation_num` （当前已经执行的操作数）来决定下一次操作时 `PUSH` 还是 `POP`。之后调用相关函数对端口进行一次赋值，并将状态切换至 `WAIT_REQ_READY`。
- `WAIT_REQ_READY`：等待请求端口准备好
  - 当请求发出后（`in_valid` 有效），此时需要等待 `in_ready` 信号有效，以确保请求已经被正确接受。
  - 当请求被正确接受后，需要将 `in_valid` 置为 0，同时将 `out_ready` 置为 1，表示请求发送完毕，准备好接收回复。
- `WAIT_RESP_VALID`：等待响应端口返回数据
  - 当请求被正确接受后，需要等待 DUT 的回复，即等待 `out_valid` 信号有效。当 `out_valid` 信号有效时，表示回复已经产生，一次请求完成，于是将 `out_ready` 置为 0，同时将状态切换至 `IDLE`。

### 运行测试

将上述代码复制到 `example.py` 中，然后执行以下命令：

```bash
cd picker_out_dual_port_stack
python3 example.py
```

可直接运行本案例的测试代码，你将会看到类似如下的输出：

```shell
...
push 77
push 140
push 249
push 68
push 104
push 222
...
Pop 43
Pass: 43 == 43
Pop 211
Pass: 211 == 211
Pop 16
Pass: 16 == 16
Pop 255
Pass: 255 == 255
Pop 222
Pass: 222 == 222
Pop 104
...
```

在输出中，你可以看到每次 `PUSH` 和 `POP` 操作的数据，以及每次 `POP` 操作的结果。如果输出中没有错误信息，则表示测试通过。


## 回调函数驱动的优劣

通过使用回调函数，我们能够完成对 DUT 的并行驱动，正如本例所示，我们通过两个回调函数实现了对拥有两个独立执行逻辑的端口的驱动。回调函数在简单的场景下，为我们提供了一种简单的并行驱动方法。

但是通过本例也可以看出，仅仅实现一套简单的“请求-回复”流程，就需要维护大量的内部状态，回调函数将本应完整的执行逻辑拆分为了多次函数调用，为代码的编写和调试增加了诸多复杂性。
