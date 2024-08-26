---
title: "Case 3: Dual-Port Stack (Callback)"
description: A dual-port stack is a stack with two ports, each supporting push and pop operations. This case study uses a dual-port stack as an example to demonstrate how to use callback functions to drive the DUT.
categories: [Example Projects, Tutorials]
tags: [examples, docs]
weight: 5 
---
## Introduction to the Dual-Port Stack 

A dual-port stack is a data structure that supports simultaneous operations on two ports. Compared to a traditional single-port stack, a dual-port stack allows simultaneous read and write operations. In scenarios such as multithreaded concurrent read and write operations, the dual-port stack can provide better performance. In this example, we provide a simple dual-port stack implementation, with the source code as follows:


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

    assign in0_ready = (in0_cmd == CMD_PUSH && sp < 255 || in0_cmd == CMD_POP && sp > 0) && !busy;
    assign in1_ready = (in1_cmd == CMD_PUSH && sp < 255 || in1_cmd == CMD_POP && sp > 0) && !busy && !(in0_ready && in0_valid);

endmodule
```
In this implementation, aside from the clock signal (`clk`) and reset signal (`rst`), there are also input and output signals for the two ports, which have the same interface definition. The meaning of each signal for the ports is as follows: 
- Request Port (in) 
  - `in_valid`: Input data valid signal
 
  - `in_ready`: Input data ready signal
 
  - `in_data`: Input data
 
  - `in_cmd`: Input command (0: PUSH, 1: POP)
 
- Response Port (out) 
  - `out_valid`: Output data valid signal
 
  - `out_ready`: Output data ready signal
 
  - `out_data`: Output data
 
  - `out_cmd`: Output command (2: PUSH_OKAY, 3: POP_OKAY)

When we want to perform an operation on the stack through a port, we first need to write the required data and command to the input port, and then wait for the output port to return the result.
Specifically, if we want to perform a PUSH operation on the stack, we should first write the data to be pushed into `in_data`, then set `in_cmd` to 0, indicating a PUSH operation, and set `in_valid` to 1, indicating that the input data is valid. Next, we need to wait for `in_ready` to be 1, ensuring that the data has been correctly received, at which point the PUSH request has been correctly sent.After the command is successfully sent, we need to wait for the stack's response information on the response port. When `out_valid` is 1, it indicates that the stack has completed the corresponding operation. At this point, we can read the stack's returned data from `out_data` (the returned data of the POP operation will be placed here) and read the stack's returned command from `out_cmd`. After reading the data, we need to set `out_ready` to 1 to notify the stack that the returned information has been correctly received.
If requests from both ports are valid simultaneously, the stack will prioritize processing requests from port 0.

## Setting Up the Driver Environment 

Similar to Case Study 1 and Case Study 2, before testing the dual-port stack, we first need to use the Picker tool to build the RTL code into a Python Module. After the build is complete, we will use a Python script to drive the RTL code for testing.
First, create a file named `dual_port_stack.v` and copy the above RTL code into this file. Then, execute the following command in the same folder:

```bash
picker export --autobuild=true dual_port_stack.v -w dual_port_stack.fst --sname dual_port_stack --tdir picker_out_dual_port_stack --lang python -e --sim verilator
```
The generated driver environment is located in the `picker_out_dual_port_stack` folder. Inside, `UT_dual_port_stack` is the generated Python Module, and `example.py` is the test script.
You can run the test script with the following commands:


```bash
cd picker_out_dual_port_stack
python3 example.py
```

If no errors occur during the run, it means the environment has been set up correctly.

## Driving the DUT with Coroutines






## Driving the DUT with Callback Functions 

In this case, we need to drive a dual-port stack to test its functionality. However, you may quickly realize that the methods used in Cases 1 and 2 are insufficient for driving a dual-port stack. In the previous tests, the DUT had a single execution logic where you input data into the DUT and wait for the output.

However, a dual-port stack is different because its two ports operate with independent execution logic. During the drive process, these two ports might be in entirely different states. For example, while port 0 is waiting for data from the DUT, port 1 might be sending a new request. In such situations, simple sequential execution logic will struggle to drive the DUT effectively.

Therefore, in this case, we will use the dual-port stack as an example to introduce a callback function-based driving method to handle such DUTs.

### Introduction to Callback Functions 
A callback function is a common programming technique that allows us to pass a function as an argument, which is then called when a certain condition is met. In the generated Python Module, we provide an interface `StepRis` for registering callback functions with the internal execution environment. Here's how it works:

```python
from UT_dual_port_stack import DUTdual_port_stack

def callback(cycles):
    print(f"The current clock cycle is {cycles}")

dut = DUTdual_port_stack()
dut.StepRis(callback)
dut.Step(10)
```

You can run this code directly to see the effect of the callback function.
In the above code, we define a callback function `callback` that takes a `cycles` parameter and prints the current clock cycle each time it is called. We then register this callback function to the DUT via `StepRis`.Once the callback function is registered, each time the `Step` function is run, which corresponds to each clock cycle, the callback function is invoked on the rising edge of the clock signal, with the current clock cycle passed as an argument.
Using this approach, we can write different execution logics as callback functions and register multiple callback functions to the DUT, thereby achieving parallel driving of the DUT.

### Dual-Port Stack Driven by Callback Functions 

To complete a full execution logic using callback functions, we typically write it in the form of a state machine. Each callback function invocation triggers a state change within the state machine, and multiple invocations complete a full execution logic.

Below is an example code for driving a dual-port stack using callback functions:


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
    dut.InitClock("clk")
    test_stack(dut)
    dut.Finish()
```
In the code above, the driving process is implemented such that each port independently drives the DUT, with a random delay added after each request is completed. Each port performs 10 `PUSH` operations and 10 `POP` operations.When a `PUSH` or `POP` request takes effect, the corresponding `commit_push` or `commit_pop` function in the `StackModel` is called to simulate stack behavior. After each `POP` operation, the data returned by the DUT is compared with the model's data to ensure consistency.To implement the driving behavior for a single port, we created the `SinglePortDriver` class, which includes a method for sending and receiving data. The `step_callback` function handles the internal update logic.In the `test_stack` function, we create a `SinglePortDriver` instance for each port of the dual-port stack, pass the corresponding interfaces, and register the callback function to the DUT using the `StepRis` function. When `dut.Step(200)` is called, the callback function is automatically invoked each clock cycle to complete the entire driving logic.**SinglePortDriver Driving Logic** As mentioned earlier, callback functions typically require the execution logic to be implemented as a state machine. Therefore, in the `SinglePortDriver` class, the status of each port is recorded, including: 
- `IDLE`: Idle state, waiting for the next operation. 
  - In the idle state, check the `remaining_delay` status to determine whether the current delay has ended. If the delay has ended, proceed with the next operation; otherwise, continue waiting.
 
  - When the next operation is ready, check the `operation_num` status (the number of operations already performed) to determine whether the next operation should be `PUSH` or `POP`. Then, call the corresponding function to assign values to the port and switch the status to `WAIT_REQ_READY`.
 
- `WAIT_REQ_READY`: Waiting for the request port to be ready. 
  - After the request is sent (`in_valid` is valid), wait for the `in_ready` signal to be valid to ensure the request has been correctly received.
 
  - Once the request is correctly received, set `in_valid` to 0 and `out_ready` to 1, indicating the request is complete and ready to receive a response.
 
- `WAIT_RESP_VALID`: Waiting for the response port to return data. 
  - After the request is correctly received, wait for the DUT's response, i.e., wait for the `out_valid` signal to be valid. When the `out_valid` signal is valid, it indicates that the response has been generated and the request is complete. Set `out_ready` to 0 and switch the status to `IDLE`.

### Running the Test 
Copy the above code into `example.py`, and then run the following command:

```bash
cd picker_out_dual_port_stack
python3 example.py
```

You can run the test code for this case directly, and you will see output similar to the following:


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
In the output, you can see the data for each `PUSH` and `POP` operation, as well as the result of each `POP` operation. If there is no error message in the output, it indicates that the test has passed.
## Pros and Cons of Callback-Driven Design 

By using callbacks, we can achieve parallel driving of the DUT, as demonstrated in this example. We utilized two callbacks to drive two ports with independent execution logic. In simple scenarios, callbacks offer a straightforward method for parallel driving.

However, as shown in this example, even implementing a simple "request-response" flow requires maintaining a significant amount of internal state. Callbacks break down what should be a cohesive execution logic into multiple function calls, adding considerable complexity to both the code writing and debugging processes.

