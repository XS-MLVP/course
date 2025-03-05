---
title: "Case 1: Adder"
date: 2017-01-05
description: Demonstrates the principles and usage of the tool based on a simple adder verification. This adder is implemented using simple combinational logic.
categories: [Example Projects, Tutorials]
tags: [examples, docs]
weight: 3
---

## RTL Source Code

In this case, we drive a 64-bit adder (combinational circuit) with the following source code:


```verilog
// A verilog 64-bit full adder with carry in and carry out

module Adder #(
    parameter WIDTH = 64
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);

assign {cout, sum}  = a + b + cin;

endmodule
```

This adder contains a 64-bit adder with inputs of two 64-bit numbers and a carry-in signal, outputting a 64-bit sum and a carry-out signal.

## Testing Process
During the testing process, we will create a folder named `Adder`, containing a file called `Adder.v`. This file contains the above RTL source code.
### Exporting RTL to Python Module

#### Generating Intermediate Files
Navigate to the `Adder` folder and execute the following command:

```bash
picker export --autobuild=false Adder.v -w Adder.fst --sname Adder --tdir picker_out_adder --lang python -e --sim verilator
```

This command performs the following actions:

1. Uses `Adder.v` as the top file, with `Adder` as the top module, and generates a dynamic library using the Verilator simulator with Python as the target language.

2. Enables waveform output, with the target waveform file as `Adder.fst`.

3. Includes files for driving the example project (-e), and does not automatically compile after code generation (-autobuild=false).

4. The final file output path is `picker_out_adder`.

Some command-line parameters were not used in this command, and they will be introduced in later sections.
The output directory structure is as follows. **Note that these are all intermediate files**  and cannot be used directly:

```bash
picker_out_adder
|-- Adder.v # Original RTL source code
|-- Adder_top.sv # Generated Adder_top top-level wrapper, using DPI to drive Adder module inputs and outputs
|-- Adder_top.v # Generated Adder_top top-level wrapper in Verilog, needed because Verdi does not support importing SV source code
|-- CMakeLists.txt # For invoking the simulator to compile the basic C++ class and package it into a bare DPI function binary dynamic library (libDPIAdder.so)
|-- Makefile # Generated Makefile for invoking CMakeLists.txt, allowing users to compile libAdder.so through the make command, with manual adjustment of Makefile configuration parameters, or to compile the example project
|-- cmake # Generated cmake folder for invoking different simulators to compile RTL code
|   |-- vcs.cmake
|   `-- verilator.cmake
|-- cpp # CPP example directory containing sample code
|   |-- CMakeLists.txt # For wrapping libDPIAdder.so using basic data types into a directly operable class (libUTAdder.so), not just bare DPI functions
|   |-- Makefile
|   |-- cmake
|   |   |-- vcs.cmake
|   |   `-- verilator.cmake
|   |-- dut.cpp # Generated CPP UT wrapper, including calls to libDPIAdder.so, and UTAdder class declaration and implementation
|   |-- dut.hpp # Header file
|   `-- example.cpp # Sample code calling UTAdder class
|-- dut_base.cpp # Base class for invoking and driving simulation results from different simulators, encapsulated into a unified class to hide all simulator-related code details
|-- dut_base.hpp
|-- filelist.f # Additional file list for multi-file projects, check the -f parameter introduction. Empty in this case
|-- mk
|   |-- cpp.mk # Controls Makefile when targeting C++ language, including logic for compiling example projects (-e, example)
|   `-- python.mk # Same as above, but with Python as the target language
`-- python
    |-- CMakeLists.txt
    |-- Makefile
    |-- cmake
    |   |-- vcs.cmake
    |   `-- verilator.cmake
    |-- dut.i # SWIG configuration file for exporting libDPIAdder.so’s base class and function declarations to Python, enabling Python calls
    `-- dut.py # Generated Python UT wrapper, including calls to libDPIAdder.so, and UTAdder class declaration and implementation, equivalent to libUTAdder.so
```

#### Building Intermediate Files
Navigate to the `picker_out_adder` directory and execute the `make` command to generate the final files.
> Use the simulator invocation script defined by `cmake/*.cmake` to compile `Adder_top.sv` and related files into the `libDPIAdder.so` dynamic library.Use the compilation script defined by `CMakeLists.txt` to wrap `libDPIAdder.so` into the `libUTAdder.so` dynamic library through `dut_base.cpp`. Both outputs from steps 1 and 2 are copied to the `UT_Adder` directory.Generate the wrapper layer using the `SWIG` tool with `dut_base.hpp` and `dut.hpp` header files, and finally build a Python module in the `UT_Adder` directory.If the `-e` parameter is included, the pre-defined `example.py` is placed in the parent directory of the `UT_Adder` directory as a sample code for calling this Python module.
The final directory structure is:


```bash
.
|-- Adder.fst # Waveform file for testing
|-- UT_Adder
|   |-- Adder.fst.hier
|   |-- _UT_Adder.so # Wrapper dynamic library generated by SWIG
|   |-- __init__.py # Python module initialization file, also the library definition file
|   |-- libDPIAdder.a # Library file generated by the simulator
|   |-- libUTAdder.so # DPI dynamic library wrapper generated based on dut_base
|   `-- libUT_Adder.py # Python module generated by SWIG
|   `-- xspcomm # Base library folder, no need to pay attention to this
`-- example.py # Sample code
```

### Setting Up Test Code

> Replace the content in `example.py` with the following Python test code.

```python
from Adder import *
import random

# Generate unsigned random numbers
def random_int():
    return random.randint(-(2**63), 2**63 - 1) & ((1 << 63) - 1)

# Reference model for the adder implemented in Python
def reference_adder(a, b, cin):
    sum = (a + b) & ((1 << 64) - 1)
    carry = sum < a
    sum += cin
    carry = carry or sum < cin
    return sum, 1 if carry else 0

def random_test():
    # Create DUT
    dut = DUTAdder()
    # By default, pin assignments do not write immediately but write on the next clock rising edge, which is suitable for sequential circuits. However, since the Adder is a combinational circuit, we need to write immediately
    # Therefore, the AsImmWrite() method is called to change pin assignment behavior
    dut.a.AsImmWrite()
    dut.b.AsImmWrite()
    dut.cin.AsImmWrite()
    # Loop test
    for i in range 114514):
        a, b, cin = random_int(), random_int(), random_int() & 1
        # DUT: Assign values to Adder circuit pins, then drive the combinational circuit (for sequential circuits or waveform viewing, use dut.Step() to drive)
        dut.a.value, dut.b.value, dut.cin.value = a, b, cin
        dut.RefreshComb()
        # Reference model: Calculate results
        ref_sum, ref_cout = reference_adder(a, b, cin)
        # Check results
        assert dut.sum.value == ref_sum, "sum mismatch: 0x{dut.sum.value:x} != 0x{ref_sum:x}"
        assert dut.cout.value == ref_cout, "cout mismatch: 0x{dut.cout.value:x} != 0x{ref_cout:x}"
        print(f"[test {i}] a=0x{a:x}, b=0x{b:x}, cin=0x{cin:x} => sum: 0x{ref_sum}, cout: 0x{ref_cout}")
    # Test complete
    dut.Finish()
    print("Test Passed")

if __name__ == "__main__":
    random_test()
```

### Running the Test
In the `picker_out_adder` directory, execute the `python3 example.py` command to run the test. After the test is complete, we can see the output of the example project.

```
[...]
[test 114507] a=0x7adc43f36682cffe, b=0x30a718d8cf3cc3b1, cin=0x0 => sum: 0x12358823834579604399, cout: 0x0
[test 114508] a=0x3eb778d6097e3a72, b=0x1ce6af17b4e9128, cin=0x0 => sum: 0x4649372636395916186, cout: 0x0
[test 114509] a=0x42d6f3290b18d4e9, b=0x23e4926ef419b4aa, cin=0x1 => sum: 0x7402657300381600148, cout: 0x0
[test 114510] a=0x505046adecabcc, b=0x6d1d4998ed457b06, cin=0x0 => sum: 0x7885127708256118482, cout: 0x0
[test 114511] a=0x16bb10f22bd0af50, b=0x5813373e1759387, cin=0x1 => sum: 0x2034576336764682968, cout: 0x0
[test 114512] a=0xc46c9f4aa798106, b=0x4d8f52637f0417c4, cin=0x0 => sum: 0x6473392679370463434, cout: 0x0
[test 114513] a=0x3b5387ba95a7ac39, b=0x1a378f2d11b38412, cin=0x0 => sum: 0x6164045699187683403, cout: 0x0
Test Passed
```