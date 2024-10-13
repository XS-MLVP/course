---
title: Verification Framework
description: mlvp is a Python-based hardware verification framework that helps users establish hardware
weight: 3
---

**mlvp**  is a hardware verification framework written in Python. It relies on a multi-language conversion tool called [picker](https://github.com/XS-MLVP/picker) , which converts Verilog hardware design code into a Python package, allowing users to drive and verify hardware designs using Python.
It incorporates some concepts from the UVM verification methodology to ensure the standardization and reusability of the verification environment. The entire setup of the verification environment has been redesigned to better align with software development practices, making it easier for software developers to get started with hardware verification.