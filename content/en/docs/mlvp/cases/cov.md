---
title: How to Write Test Points
weight: 3
---

## Test Points in Verification 
In mlvp, a **test point (Cover Point)**  refers to the smallest unit of verification for a specific function of the design, while a **test group (Cover Group)**  is a collection of related test points.
To define a test point, you need to specify the name of the test point and its trigger condition. For example, you can define a test point such as, "When the result of the adder operation is non-zero, the result is correct." In this case, the trigger condition for the test point could be "the sum signal of the adder is non-zero."

When the trigger condition of the test point is met, the test point is triggered. At this moment, the verification report will record the triggering of the test point and increase the functional coverage of the verification. When all test points are triggered, the functional coverage of the verification reaches 100%.

## How to Write Test Points 

Before writing test points, you first need to create a test group and specify the name of the test group:


```python
from mlvp.reporter import CovGroup

g = CovGroup("Adder addition function")
```

Next, you need to add test points to this test group:


```python
# import mlvp.funcov as fc

# g.add_watch_point(adder.io_cout, {"io_cout is 0": fc.Eq(0)}, name="Cout is 0")
```

TBD (To Be Determined)





