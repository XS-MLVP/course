---
title: Starting a New Verification Task
weight: 5
---

With mlvp, you can now set up a complete verification environment and conveniently write test cases. However, in real-world scenarios, it can be challenging to understand how to get started and ultimately complete a verification task. After writing code, common issues may include difficulties in correctly partitioning the Bundle, misunderstanding the high-level semantic encapsulation of the Agent, and not knowing what to do after setting up the environment.

In this section, we will introduce how to complete a new verification task from scratch and how to use mlvp effectively to accomplish it.

## 1. Understanding the Design Under Test (DUT) 

When you first encounter a new design, you may face dozens or even hundreds of input and output signals, which can be overwhelming. At this point, you must trust that these signals are defined by the design engineers, and by understanding the functionality of the design, you can infer the meaning of these signals.

If the design team provides documentation, you can read it to understand the functionality of the design and map the functions to the input and output signals. You should also gain a clear understanding of the signal timing and how to use these signals to drive the design. Generally, you will also need to review the design's source code to uncover more detailed timing issues.

Once you have a basic understanding of the DUT's functionality and how to drive its interface, you can start building the verification environment.

## 2. Partitioning the Bundle 

The first step in setting up the environment is to logically partition the interface into several sets, with each set of interfaces considered as a Bundle. Each Bundle should be driven by an independent Agent.

However, in practice, interfaces may appear like this:


```lua
|---------------------- DUT Bundle -------------------------------|

|------- Bundle 1 ------| |------ Bundle 2 ------| |-- Bundle 3 --|

|-- B1.1 --| |-- B1.2 --| |-- B2.1 --|
```

This raises the question: should B1.1 and B1.2 each have their own Agent, or should a single Agent be created for Bundle 1?

The answer depends on the logic of the interface. If a request requires simultaneous operations on both B1.1 and B1.2, then you should create one Agent for Bundle 1 rather than creating separate Agents for B1.1 and B1.2.

That said, creating individual Agents for B1.1 and B1.2 is also feasible. This increases the granularity of the Agent but sacrifices operational continuity, making the upper-level code and reference model more complex. Therefore, the appropriate granularity depends on the specific use case. In the end, all Agents combined should cover the entire DUT Bundle interface.
In practice, for convenience in connecting the DUT, you can define a `DUT` Bundle that connects all interfaces to this Bundle at once, and then the `Env` can distribute the sub-Bundles to their respective Agents.
## 3. Writing the Agent 

After partitioning the Bundle, you can start writing the Agents to drive them. You need to write an Agent for each Bundle.

First, you can begin by writing the driver methods, which are high-level semantic encapsulations of the Bundle. These high-level semantic details should carry all the information necessary to drive the Bundle. If a signal in the Bundle requires a value but the method parameters don’t provide the corresponding information, then the encapsulation is incomplete. Avoid assuming any signal values within the driver methods; otherwise, the DUT's output will be affected by these assumptions, potentially causing discrepancies between the reference model and the DUT.

This high-level encapsulation also defines the functionality of the reference model, which interacts directly with the high-level semantic information, not with the low-level signals.

If the reference model is written using function-call mode, the DUT’s outputs should be returned through function return values. If the reference model uses a separate execution flow, you should write monitoring methods that convert the DUT’s outputs into high-level semantic information and output them via the monitoring methods.

## 4. Encapsulating into Env 
Once all the Agents are written or selected from existing Agents, you can encapsulate them into the `Env`.`Env` encapsulates the entire verification environment and defines the writing conventions for the reference model.
## 5. Writing the Reference Model 
Writing the reference model doesn’t need to wait until the `Env` is complete—it can be done alongside the Agent development, with some driving code written in real-time to verify correctness. Of course, if the Agent is well-structured, writing the reference model after the complete `Env` is created is also feasible.
The most important part of the reference model is choosing the appropriate mode—both function-call mode and separate execution flow mode are viable, but the selection depends on the specific use case.

## 6. Identifying Functional and Test Points 
After writing the `Env` and reference model, you cannot immediately start writing test cases because there is no direction yet for writing them. Blindly writing test cases won’t ensure complete verification of the design.
First, you need to list the functional and test points. Functional points refer to all the functionalities supported by the design. For example, for an arithmetic logic unit (ALU), functional points could be "supports addition" or "supports multiplication." Each functional point should correspond to one or more test points, which break the function into different test scenarios to verify whether the functional point is correct. For example, for the "supports addition" functional point, test points could include "addition is correct when both inputs are positive."

## 7. Writing Test Cases 

Once the list of functional and test points is determined, you can start writing test cases. Each test case should cover one or more test points to verify whether the functional point is correct. All test cases combined should cover all test points (100% functional coverage) and all lines of code (100% line coverage), ensuring verification completeness.
How can you ensure verification correctness? If the reference model comparison method is used, mlvp will automatically throw an exception when a mismatch occurs, causing the test case to fail. If a direct comparison method is used, you should use `assert` in the test case to write comparison code. When the comparison fails, the test case will also fail. When all test cases pass, the functionality is confirmed as correct.When writing, use the interfaces provided by `Env` to drive the DUT. If interaction between multiple driver methods is needed, you can use the `Executor` to encapsulate higher-level functions. In other words, interactions at the driver method level should be handled during test case development.
## 8. Writing the Verification Report 

Once 100% line and functional coverage is achieved, the verification is complete. A verification report should be written to summarize the results. If issues are found in the DUT, the report should provide detailed descriptions of the causes. If 100% coverage is not achieved, the report should explain why. The format of the report should follow the company's internal standards.