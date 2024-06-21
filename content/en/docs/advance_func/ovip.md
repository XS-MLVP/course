---
title: Verification IP
description: VIP， verification IP
categories: [Example Projects, Tutorials]
tags: [examples, docs]
weight: 4
draft: true
---

## Overview
> **The verification environment is not entirely written by the verifier. Many highly reusable verification templates can be used, such as certain agents, and these templates are VIP.**
>VIP (Verification IP) code confirms the verification technology, which is pre-verified built-in verification structures, providing a complete and flexible application mechanism that can be easily inserted into simulation-based verification tests, greatly improving verification reusability and efficiency.

VIP provides a comprehensive testing environment to help designers and verifiers confirm the correctness of their design functions, and can be used for simulation verification at various levels. Typically, VIP is based on standard protocols such as AMBA, PCIE, USB, Ethernet, etc. VIP includes many verification component IPs, which strictly adhere to these standard protocols and have been verified. It usually includes basic components required to generate the testbench, driver, and sequence according to the protocol, as well as corresponding coverage models, DUT software models, and documentation.

In large projects involving numerous protocols and standards, many VIPs will be involved, as well as cross-platform co-simulation involving languages like C++.


### Use Cases

**● Verification of Design IPs**
IC designers will use stable VIPs to verify their designs.
Of course, you can also develop VIPs yourself.

**● Integration of Design IPs**
Design IPs have many parameters, and different parameter configurations will result in different performance and functions.
Therefore, integration personnel need to connect, configure, and schedule multiple design IPs, and corresponding VIPs also need to be inherited.

**● Subsystem, SoC System Developers**
When the designed IP is integrated into upper-layer systems, the use and integration of VIPs are also involved, such as using what kind of sequence for targeted testing.

### Advantages and Features of VIP

**● Constantly Updated Standards**
Various protocols such as PCIe, DDR, USB, AMBA, etc., are often updated.
In order to make hardware compatible with each other, the design IP needs to be continuously revised and improved to make its IP compatible with new standards, and the corresponding verification IP also needs to be continuously iterated and updated.
With VIP, integration and verification personnel do not need to spend effort on protocol compatibility but can focus on functionality.

**● Virtual DUT**
That is to say, if hardware model simulation is used, it may take a huge amount of time. Some hardware models simulated by software such as SystemC, SystemVerilog provided by VIP can speed up the simulation.

**● Built-in Protocol Conflict Checker**
A VIP monitor is integrated on the interface between the design and VIP. It can be used to monitor trans on the bus and to automatically verify protocol rules. Any trans sent or received from the DUT may violate the protocol rules in the built-in protocol checker developed in VIP, which may lead to protocol violation errors.

**● Provides Various Detailed Error Reports**

### VIP Integration
- **Module Level**：The module-level verification is actually the verification framework mentioned before. It just replaces the content of the verification framework with VIP.

- **Subsystem Level**： For subsystems integrated with multiple modules, VIP can be embedded in the system, replacing some control modules or response modules in the subsystem to conduct UVM_ACTIVE tests containing drivers and sequencers. If the driver test is correct, the real hardware module can be connected, and then **the corresponding agent in the VIP is set to UVM_PASSIVE**, only the monitor is retained.

- **Chip Level**：System-level, higher integration level, involves system-level VIP, some hardware in the system such as Process, Memory, etc., are not real hardware but provided by VIP. This is a virtual processor implemented through SystemC, SystemVerilog to accelerate simulation.

> [openVIP](https://gitee.com/XS-MLVP/open-vip) is a set of C++ implementation verification IP libraries provided by Picker, and provides programming interfaces for other languages ​​(Python, Java, etc.).
Currently, this library is still under development and only provides some simple interfaces.