---
title: "Case: 1 Adder"
date: 2017-01-05
description: Demonstrates the principles and usage of the tool based on a simple adder verification. This adder is implemented using simple combinational logic.
categories: [Example Projects, Tutorials]
tags: [examples, docs]
weight: 3
---

## RTL Source Code
In this case, we drive a 64-bit adder. The source code is as follows:

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
This adder consists of a 64-bit adder. The inputs are two 64-bit numbers and a carry-in signal, and the outputs are a 64-bit sum and a carry-out signal.

## Testing Process
During the testing process, we will create a folder named Adder, containing an Adder.v file. The content of this file is the RTL source code mentioned above.

### Building the RTL into a Python Module

#### Generating Intermediate Files

Enter the Adder folder and execute the following command:

```bash
picker --autobuild=false Adder.v -w Adder.fst -S Adder -t picker_out_adder -l python -e --sim verilator
```
The meaning of this command is:

1. Use Adder.v as the top file and Adder as the top module. Generate a dynamic library using the Verilator simulator, with the target language being Python.
2. Enable waveform output with the target waveform file as Adder.fst.
3. Include files to drive the example project (-e) and do not auto-compile after code generation (-autobuild=false).
4. The final file output path is picker_out_adder.

Some command-line parameters are not used in this command; these will be introduced in subsequent sections.

The output directory structure is as follows. Note that these are all intermediate files and cannot be used directly:

```bash
picker_out_adder
|-- Adder.v # Original RTL source code
|-- Adder_top.sv # Generated Adder_top top-level wrapper, using DPI to drive Adder module inputs and outputs
|-- Adder_top.v # Generated Adder_top top-level wrapper, a Verilog version because Verdi does not support importing SV source code
|-- CMakeLists.txt # Used to call the simulator to compile basic cpp class and package it into a binary dynamic library with bare DPI functions (libDPIAdder.so)
|-- Makefile # Generated Makefile, used to call CMakeLists.txt, allowing users to compile libAdder.so via the make command and manually adjust Makefile configuration parameters. Or compile the example project
|-- cmake # Generated cmake folder, used to call different simulators to compile RTL code
|   |-- vcs.cmake
|   `-- verilator.cmake
|-- cpp # CPP example directory, containing example code
|   |-- CMakeLists.txt # Used to encapsulate libDPIAdder.so into a directly operable class (libUTAdder.so) with basic data types, rather than bare DPI functions.
|   |-- Makefile
|   |-- cmake
|   |   |-- vcs.cmake
|   |   `-- verilator.cmake
|   |-- dut.cpp # Generated cpp UT encapsulation, containing the call to libDPIAdder.so and the declaration and implementation of the UTAdder class
|   |-- dut.hpp # Header file
|   `-- example.cpp # Example code calling the UTAdder class
|-- dut_base.cpp # Base class used to call and drive different simulator compilation results, encapsulated into a unified class to hide all simulator-related code details.
|-- dut_base.hpp
|-- filelist.f # Other file lists used for multi-file projects, see the introduction of the -f parameter. Empty in this case
|-- mk
|   |-- cpp.mk # Used to control the Makefile when the target language is cpp, including the logic to compile example projects (-e, example)
|   `-- python.mk # Same as above, target language is python
`-- python
    |-- CMakeLists.txt
    |-- Makefile
    |-- cmake
    |   |-- vcs.cmake
    |   `-- verilator.cmake
    |-- dut.i # SWIG configuration file, used to export the base class and function declarations of libDPIAdder.so to Python, providing Python calling capability
    `-- dut.py # Generated python UT encapsulation, containing the call to libDPIAdder.so and the declaration and implementation of the UTAdder class, equivalent to libUTAdder.so
```

#### Building Intermediate Files

Enter the `picker_out_adder` directory and execute the `make` command to generate the final files.

> The automatic compilation process flow defined by Makefile is as follows:

> 1. Call the simulator through `cmake/*.cmake` defined scripts to compile `Adder_top.sv` and related files into the dynamic library `libDPIAdder.so`.
> 2. Use the compilation scripts defined in `CMakelists.txt` to encapsulate `libDPIAdder.so` into the dynamic library `libUTAdder.so` through `dut_base.cpp`. The results of steps 1 and 2 are copied to the `UT_Adder` directory.
> 3. Use header files such as `dut_base.hpp` and `dut.hpp` to generate the encapsulation layer through the `SWIG` tool, and finally build a Python Module in the `UT_Adder` directory.
> 4. If there is a `-e` parameter, the predefined `example.py` will be placed in the parent directory of the `UT_Adder` directory as an example of how to call this Python Module.

The final directory structure is:

```bash
.
|-- Adder.fst # Test waveform file
|-- UT_Adder
|   |-- Adder.fst.hier
|   |-- _UT_Adder.so # Wrapper dynamic library generated by Swig
|   |-- __init__.py # Initialization file of the Python Module, also the library definition file
|   |-- libDPIAdder.a # Library file generated by the simulator
|   |-- libUTAdder.so # Encapsulation of the libDPI dynamic library generated based on dut_base
|   `-- libUT_Adder.py # Python Module generated by Swig
|   `-- xspcomm # Fixed folder, no need to pay attention
`-- example.py # Example code

```

### Configuring Test Code

> Note that the content in `example.py` needs to be replaced to ensure the example project runs as expected.

```python
from UT_Adder import *

import random

class input_t:
    def __init__(self, a, b, cin):
        self.a = a
        self.b = b
        self.cin = cin

class output_t:
    def __init__(self):
        self.sum = 0
        self.cout = 0

def random_int(): # Data needs to be passed into dut as an unsigned number
    return random.randint(-(2**63), 2**63 - 1) & ((1 << 63) - 1)

def as_uint(x, nbits): # Convert data to unsigned number
    return x & ((1 << nbits) - 1)

def main():
    dut = DUTAdder()  # Assuming USE_VERILATOR

    print("Initialized UTAdder")

    for c in range(114514):
        i = input_t(random_int(), random_int(), random_int() & 1)
        o_dut, o_ref = output_t(), output_t()

        def dut_cal():
            # Assign values to DUT inputs, must use .value
            dut.a.value, dut.b.value, dut.cin.value = i.a, i.b, i.cin
            # Drive the circuit for one cycle
            dut.Step(1)
            o_dut.sum = dut.sum.value
            o_dut.cout = dut.cout.value

        def ref_cal():
            sum = as_uint( i.a + i.b, 64 )
            carry = sum < i.a
            sum += i.cin
            carry = carry or sum < i.cin
            o_ref.sum, o_ref.cout = sum, carry

        dut_cal()
        ref_cal()

        print(f"[cycle {dut.xclock.clk}] a=0x{i.a:x}, b=0x{i.b:x}, cin=0x{i.cin:x} ")
        print(f"DUT: sum=0x{o_dut.sum:x}, cout=0x{o_dut.cout:x}")
        print(f"REF: sum=0x{o_ref.sum:x}, cout=0x{o_ref.cout:x}")

    assert o_dut.sum == o_ref.sum, "sum mismatch"
    dut.finalize() # Must explicitly call finalize method to prevent memory leaks and generate waveforms and coverage
    print("Test Passed, destroy UTAdder")

if __name__ == "__main__":
    main()

```

### Running the Test

Execute the `python example.py` command in the `picker_out_adder` directory to run the test. After the test is completed, we can see the output of the example project. The waveform file will be saved in `Adder.fst`.

```
[...]
[cycle 114513] a=0x6defb0918b94495d, b=0x72348b453ae6a7a8, cin=0x0 
DUT: sum=0xe0243bd6c67af105, cout=0x0
REF: sum=0xe0243bd6c67af105, cout=0x0
[cycle 114514] a=0x767fa8cbfd6bbfdc, b=0x4486aa3a9b29719a, cin=0x1 
DUT: sum=0xbb06530698953177, cout=0x0
REF: sum=0xbb06530698953177, cout=0x0
Test Passed, destroy UTAdder
```
