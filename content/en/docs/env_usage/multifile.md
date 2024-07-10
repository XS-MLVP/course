---
title: Multi-File Input
description: Handling multiple Verilog source files
categories: [Sample Projects, Tutorials]
tags: [examples, docs]
weight: 3
---

## Multi-File Input and Output

In many cases, a module in one file may instantiate modules in other files. In such cases, you can use the picker tool's `-f` option to process multiple Verilog source files. For example, suppose you have three source files: `Cache.sv`, `CacheStage.sv`, and `CacheMeta.sv`:

### File List

#### Cache.sv

```sv
// In 
module Cache(
    ...
);
    CacheStage s1(
        ...
    );

    CacheStage s2(
        ...
    );

    CacheStage s3(
        ...
    );

    CacheMeta cachemeta(
        ...
    );
endmodule
```

#### CacheStage.sv
```sv
// In CacheStage.sv
module CacheStage(
    ...
);
    ...
endmodule
```

#### CacheMeta.sv
```sv
// In CacheMeta.sv
module CacheMeta(
    ...
);
    ...
endmodule
```
### Usage

In this case, the module under test is Cache, which is in `Cache.sv`. You can generate the DUT using the following command:

#### Command Line Specification

```bash
picker export Cache.sv --fs CacheStage.sv,CacheMeta.sv --sname Cache
```

#### Specification through a File List File

You can also use a .txt file to specify multiple input files:

```bash
picker export Cache.sv --fs src.txt --sname Cache
```

Where the contents of `src.txt` are:

```
CacheStage.sv
CacheMeta.sv
```

### Notes

1. It is important to note that even when using multiple file inputs, you still need to specify the file containing the top-level module under test, as shown in the example above with `Cache.sv`.
2. When using multiple file inputs, Picker will pass all files to the simulator, which will compile them simultaneously. Therefore, it is necessary to ensure that the module names in all files are unique.
