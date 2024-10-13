---
title: Writing Test Cases
weight: 4
---

Writing test cases requires utilizing the interfaces defined in the verification environment. However, it is often necessary to drive multiple interfaces simultaneously in the test case, and there are often different synchronization needs with reference simulations. This section will provide a detailed explanation of how to better use the interfaces in the verification environment for writing test cases.
Once the verification environment is set up, test cases are written to verify whether the design functions as expected. Two important aspects of hardware verification are **functional coverage**  and **line coverage** . Functional coverage means whether the test cases cover all the functions of the design, while line coverage means whether the test cases trigger all lines of the design’s code. In mlvp, not only is support provided for both types of coverage, but after each run, the tool automatically calculates the results for both and generates a verification report. mlvp uses pytest to manage test cases, which provides powerful test case management capabilities.
In this section, we will cover how to write test cases to take advantage of the powerful features provided by mlvp in the following areas:

1. How to use test environment interfaces for driving

2. How to manage test cases with pytest

3. How to add functional test points