---
title: Digital Circuits
weight: 2
description: >
  Basic concepts of digital circuits
---

{{% pageinfo %}}
This page introduces the basics of digital circuits. Digital circuits use digital signals and are the foundation of most modern computers.
{{% /pageinfo %}}

## What Are Digital Circuits ##

---

Digital circuits are electronic circuits that use two discrete voltage levels to represent information. Typically, digital circuits use two power supply voltages to indicate high (H) and low (L) levels, representing the digits 1 and 0 respectively. This representation uses binary signals to transmit and process information.

Most digital circuits are built using field-effect transistors, with MOSFETs (Metal-Oxide-Semiconductor Field-Effect Transistors) being the most common. MOSFETs are semiconductor devices that control current flow using an electric field, enabling digital signal processing.

In digital circuits, MOSFETs are combined to form various logic gates like AND, OR, and NOT gates. These logic gates are combined in different ways to create the various functions and operations in digital circuits. Here are some key features of digital circuits:

**(1) Voltage Representation：** Digital circuits use two voltage levels, high and low, to represent digital information. Typically, a high level represents the digit 1, and a low level represents the digit 0.

**(2) MOSFET Implementation：** MOSFETs are one of the most commonly used components in digital circuits. By controlling the on and off states of MOSFETs, digital signal processing and logic operations can be achieved.

**(3) Logic Gate Combinations：** Logic gates, composed of MOSFETs, are the basic building blocks of digital circuits. By combining different logic gates, complex digital circuits can be built to perform various logical functions.

**(4) Binary Representation：** Information in digital circuits is typically represented using the binary system. Each digit can be made up of a series of binary bits, which can be processed and operated on within digital circuits.

**(5) Signal Processing：** Digital circuits convert and process signals through changes in voltage and logic operations. This discrete processing method makes digital circuits well-suited for computing and information processing tasks.


## Why Learn Digital Circuits ##

---

Learning digital circuits is fundamental and necessary for the chip verification process, primarily for the following reasons:

**(1) Understanding Design Principles：** Digital circuits are the foundation of chip design. Knowing the basic principles and design methods of digital circuits is crucial for understanding the structure and function of chips. The goal of chip verification is to ensure that the designed digital circuits work according to specifications in actual hardware, and understanding digital circuits is key to comprehending the design.

**(2) Design Standards：** Chip verification typically involves checking whether the design meets specific standards and functional requirements. Learning digital circuits helps in understanding these standards, thus building better test cases and verification processes to ensure thorough and accurate verification.

**(3) Timing and Clocks：** Timing issues are common challenges in digital circuit design and verification. Learning digital circuits helps in understanding concepts of timing and clocks, ensuring that timing issues are correctly handled during verification, avoiding timing delays and conflicts in the circuit.

**(4) Logical Analysis：** Chip verification often involves logical analysis to ensure circuit correctness. Learning digital circuits fosters a deep understanding of logic, aiding in logical analysis and troubleshooting.

**(5) Writing Test Cases：** In chip verification, various test cases need to be written to ensure design correctness. Understanding digital circuits helps in designing comprehensive and targeted test cases, covering all aspects of the circuit.

**(6) Signal Integrity：** Learning digital circuits helps in understanding signal propagation and integrity issues within circuits. Ensuring proper signal transmission under different conditions is crucial, especially in high-speed designs.


Overall, learning digital circuits provides foundational knowledge and tools for chip verification, enabling verification engineers to better understand designs, write effective test cases, analyze verification results, and troubleshoot issues. Theoretical and practical experience with digital circuits is indispensable for chip verification engineers.


## Digital Circuits Basics ##

You can learn digital circuits through the following online resources：

- [Tsinghua University's Digital Circuits Basics](https://www.xuetangx.com/course/THU08081000386/19317632)
- [USTC Digital Circuit Lab](https://soc.ustc.edu.cn/Digital/)
- [Digital Design and Computer Architecture](https://github.com/apachecn/huazhang-cs-books/blob/master/%E6%95%B0%E5%AD%97%E8%AE%BE%E8%AE%A1%E5%92%8C%E8%AE%A1%E7%AE%97%E6%9C%BA%E4%BD%93%E7%B3%BB%E7%BB%93%E6%9E%84%E5%8E%9F%E4%B9%A6%E7%AC%AC2%E7%89%88.pdf)
- [MIT Analysis and Design of Digital Integrated Circuits](https://ocw.mit.edu/courses/6-374-analysis-and-design-of-digital-integrated-circuits-fall-2003/download/)

## Hardware Description Language Chisel ##

---


### Traditional Description Languages
Hardware Description Languages (HDL) are languages used to describe digital circuits, systems, and hardware. They allow engineers to describe hardware structure, function, and behavior through text files, enabling abstraction and modeling of hardware designs.

HDL is commonly used for designing and simulating digital circuits such as processors, memory, controllers, etc. It provides a formal method to describe the behavior and structure of hardware circuits, making it easier for design engineers to perform hardware design, verification, and simulation.

Common hardware description languages include:

- Verilog：One of the most used HDLs, Verilog is an event-driven language widely used for digital circuit design, verification, and simulation.
- VHDL：Another common HDL, VHDL is an object-oriented language offering richer abstraction and modular design methods.
- SystemVerilog：An extension of Verilog, SystemVerilog introduces advanced features like object-oriented programming and randomized testing, making Verilog more suitable for complex system design and verification.

### Chisel

Chisel is a modern, advanced hardware description language that differs from traditional Verilog and VHDL. It's a hardware construction language based on Scala. Chisel offers a more modern and flexible way to describe hardware, leveraging Scala’s features to easily implement parameterization, abstraction, and reuse while maintaining hardware-level efficiency and performance.

Chisel’s features include:

- Modern Syntax: Chisel's syntax is more similar to software programming languages like Scala, making hardware description more intuitive and concise.
- Parameterization and Abstraction: Chisel supports parameterization and abstraction, allowing for the creation of configurable and reusable hardware modules.
- Type Safety: Based on Scala, Chisel has type safety features, enabling many errors to be detected at compile-time.
- Generating Performance-Optimized Hardware: Chisel code can be converted to Verilog and then synthesized, placed, routed, and simulated by standard EDA toolchains to generate performance-optimized hardware.
- Strong Simulation Support: Chisel provides simulation support integrated with ScalaTest and Firrtl, making hardware simulation and verification more convenient and flexible.

#### Chisel Example of a Full Adder

The circuit design is shown below:

{{< figure src="fulladder.png" alt="Full Adder Circuit" width="500px" >}}

Complete Chisel code:

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

You can refer to Chisel learning materials from the official documentation: [https://www.chisel-lang.org/docs](https://www.chisel-lang.org/docs)
