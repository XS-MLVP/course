---
title:  Quick Start
description: How to use the open verification platform to participate in hardware verification.
categories: [Sample Projects, Tutorials]
tags: [examples, docs]
weight: 1
---

{{% pageinfo %}}
This page will briefly introduce what verification is, as well as concepts used in the examples, such as DUT (Design Under Test) and RM (Reference Model).
{{% /pageinfo %}}

### Chip Verification

Chip verification is a crucial step to ensure the correctness and reliability of chip designs, including functional verification, formal verification, and physical verification. This material only covers functional verification, focusing on simulation-based chip functional verification. The processes and methods of chip functional verification have many similarities with software testing, such as unit testing, system testing, black-box testing, and white-box testing. They also share similar metrics, such as functional coverage and code coverage. In essence, apart from the different tools and programming languages used, their goals and processes are almost identical. **Thus, software test engineers should be able to perform chip verification without considering the tools and programming languages.** However, in practice, software testing and chip verification are two completely separate fields, primarily due to the different verification tools and languages, making it difficult for software test engineers to crossover. In chip verification, hardware description languages (e.g., Verilog or SystemVerilog) and specialized commercial tools for circuit simulation are commonly used. Hardware description languages differ from high-level software programming languages like C++/Python, featuring a unique "clock" characteristic, which poses a high learning curve for software engineers.

**To bridge the gap between chip verification and traditional software testing, allowing more people to participate in chip verification, this project provides the following content:**

<blockquote><p>
Multi-language verification tools (Picker), allowing users to use their preferred programming language for chip verification.

Verification framework (MLVP), enabling functional verification without worrying about the clock.

Introduction to basic circuits and verification knowledge, helping software enthusiasts understand circuit characteristics more easily.

Basic learning materials for fundamental verification knowledge.

Real high-performance chip verification cases, allowing enthusiasts to participate in verification work remotely.

</blockquote></p>


### Basic Terms

**DUT:** Design Under Test, usually referring to the designed RTL code.

**RM:** Reference Model, a standard error-free model corresponding to the unit under test.

**RTL:** Register Transfer Level, typically referring to the Verilog or VHDL code corresponding to the chip design.

**Coverage:** The percentage of the test range relative to the entire requirement range. In chip verification, this typically includes line coverage, function coverage, and functional coverage.

**DV:** Design Verification, referring to the collaboration of design and verification.

**Differential Testing (difftest):** Selecting two (or more) functionally identical units under test, submitting the same test cases that meet the unit's requirements to observe whether there are differences in the execution results.

### Tool Introduction

The core tool used in this material is Picker（[https://github.com/XS-MLVP/picker](https://github.com/XS-MLVP/picker)）. Its purpose is to automatically provide high-level programming language interfaces (Python/C++) for RTL-written design modules. Based on this tool, verification personnel with a software development (testing) background can perform chip verification without learning hardware description languages like Verilog/VHDL.

### System Requirements

Recommended operating system: Ubuntu 22.04 LTS

<blockquote><p>
In the development and research of system architecture, Linux is the most commonly used platform, mainly because Linux has a rich set of software and tool resources. Due to its open-source nature, important tools and software (such as Verilator) can be easily developed for Linux. In this course, multi-language verification tools like Picker and Swig can run stably on Linux.
</blockquote></p>

