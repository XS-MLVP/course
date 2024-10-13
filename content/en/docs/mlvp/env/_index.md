---
title: Setting Up a Verification Environment
weight: 3
---

**mlvp**  provides the methods and tools needed for the complete process of setting up a verification environment. This chapter will explain in detail how to use **mlvp**  to build a complete verification environment.Before proceeding, please ensure you have read [How to Write a Canonical Verification Environment](https://chatgpt.com/docs/mlvp/canonical_env)  and are familiar with the basic structure of mlvp's canonical verification environment.
For a completely new verification task, following the environment setup steps, the process of building a verification environment can be divided into the following steps:

1. Partition the DUT interface based on logical functions and define Bundles.

2. Write an Agent for each Bundle, completing the high-level encapsulation of the Bundle.

3. Encapsulate multiple Agents into an Env, completing the high-level encapsulation of the entire DUT.

4. Write the reference model according to the interface specifications of the Env and bind it to the Env.

This chapter will introduce how to use mlvp tools to meet the requirements for setting up the environment in each step.
