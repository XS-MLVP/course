---
title: Verification Report
description:  An overview of the structure and content of the verification report.
categories: [Example Projects, Learning Materials]
tags: [examples, docs]
weight: 6
---

{{% pageinfo %}}
After we complete the DUT verification, writing a verification report is a crucial step. This section will provide an overview of the structure of the verification report and the content that needs to be covered.
{{% /pageinfo %}}

The verification report is a review of the entire verification process and an important supporting document for determining the reasonableness of the verification. Generally, the verification report should include the following content:

>1. Basic document information (author, log, version, etc.)
>1. Verification object (verification target)
>1. Introduction to functional points
>1. Verification plan
>1. Breakdown of test points
>1. Test cases
>1. Test environment
>1. Result analysis
>1. Defect analysis
>1. Verification conclusion


The following content provides further explanation of the list, with specific examples available in[nutshell_cache_report_demo.pdf](nutshell_cache_report_demo.pdf)

------------------------------------------------------

### 1. Basic Information
Including author, log, version, date, etc.

### 2. Verification object (verification target)
A necessary introduction to your verification object, which may include its structure, basic functions, interface information, etc.

### 3. Introduction to functional points
By reading the design documents or source code, you need to summarize the target functions of the DUT and break them down into various functional points.

### 4. Verification plan
Including your planned verification process and verification framework. Additionally, you should explain how each part of your framework works together.

### 5. Breakdown of test points
Proposed testing methods for the functional points. Specifically, it can include what signal output should be observed under certain signal inputs.

### 6. Test cases
The specific implementation of the test points. A test case can include multiple test points.

### 7. Test environment
Including hardware information, software version information, etc.

### 8. Result analysis
Result analysis generally refers to coverage analysis. Typically, two types of coverage should be considered:
**1. Line Coverage**： How many RTL lines of code are executed in the test cases. Generally, we require line coverage to be above 98%.  
**2. Functional Coverage**：Determine whether the extracted functional points are covered and correctly triggered based on the relevant signals. We generally require test cases to cover each functional point.

### 9. Defect analysis
Analyze the defects present in the DUT. This can include the specification and detail of the design documents, the correctness of the DUT functions (whether there are bugs), and whether the DUT functions can be triggered.

### 10. Verification conclusion
The final conclusion drawn after completing the chip verification process, summarizing the above content.