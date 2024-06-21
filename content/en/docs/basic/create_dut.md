---
title: Creating DUT
description:  Using Guoke Cache as an example, this document introduces how to create a DUT based on Chisel.
categories: [Sample Projects, Learning Materials]
tags: [examples, docs]
weight: 3
---

{{% pageinfo %}}
Using Guoke Cache as an example, this document introduces how to create a DUT based on Chisel.
{{% /pageinfo %}}

In this document, a DUT (Design Under Test) refers to the circuit or system being verified during the chip verification process. The DUT is the primary subject of verification. When creating a DUT based on the picker tool, it is essential to consider the functionality, performance requirements, and verification goals of the subject under test. These goals may include the need for faster execution speed or more detailed test information. Generally, the DUT, written in RTL, is combined with its surrounding environment to form the verification environment (test_env), where test cases are written. In this project, the DUT is the Python module that needs to be tested and converted through RTL. Traditional RTL languages include Verilog, System Verilog, VHDL, etc. However, as an emerging RTL design language, （[https://www.chisel-lang.org/](https://www.chisel-lang.org/)） is playing an increasingly important role in RTL design due to its object-oriented features and ease of use. This chapter introduces how to create a DUT using the conversion of the cache source code from the [Guoke Processor-NutShell](https://github.com/OSCPU/NutShell) to a Python module as an example.

## Chisel and Guoke
Chisel is a high-level hardware construction language (HCL) based on the Scala language. Traditional HDLs describe circuits, while HCLs generate circuits, making them more abstract and advanced. The Stage package provided in Chisel can convert HCL designs into traditional HDL languages such as Verilog and System Verilog. With tools like Mill and Sbt, automation in development can be achieved.

Guoke is a sequential single-issue processor implementation based on the RISC-V RV64 open instruction set, modularly designed using the Chisel language. For a more detailed introduction to Guoke, please refer to the link: [https://oscpu.github.io/NutShell-doc/](https://oscpu.github.io/NutShell-doc/).

## Guoke cache

The Guoke Cache (Nutshell Cache) is the cache module used in the Guoke processor. It features a three-stage pipeline design. When the third stage pipeline detects that the current request is MMIO or a refill occurs, it will block the pipeline. The Guoke Cache also uses a customizable modular design that can generate different-sized L1 Caches or L2 Caches by changing parameters. Additionally, the Guoke Cache has a coherence interface to handle coherence-related requests.

![nt_cache](nt_cache.png)

## Chisel to Verilog

The stage library in Chisel helps generate traditional HDL code such as Verilog and System Verilog from Chisel code. Below is a brief introduction on how to convert a cache implementation based on Chisel into the corresponding Verilog circuit description.

### Initializing the Guoke Environment
First, download the entire Guoke source code from the source repository and initialize it:

``` bash
mkdir cache-ut
cd cache-ut
git clone https://github.com/OSCPU/NutShell.git
cd NutShell && git checkout 97a025d
make init
```

### Creating Scala Compilation Configuration
Then, create build.sc in the cache-ut directory with the following content:
```scala
import $file.NutShell.build
import mill._, scalalib._
import coursier.maven.MavenRepository
import mill.scalalib.TestModule._

// Specify Nutshell dependencies
object difftest extends NutShell.build.CommonNS {
  override def millSourcePath = os.pwd / "NutShell" / "difftest"
}

// Nutshell configuration
object NtShell extends NutShell.build.CommonNS with NutShell.build.HasChiselTests {
  override def millSourcePath = os.pwd / "NutShell"
  override def moduleDeps = super.moduleDeps ++ Seq(
        difftest,
  )
}

// UT environment configuration
object ut extends NutShell.build.CommonNS with ScalaTest{
    override def millSourcePath = os.pwd
    override def moduleDeps = super.moduleDeps ++ Seq(
        NtShell
    )
}

```


### Instantiating cache
After creating the configuration information, create the src/main/scala source code directory according to the Scala specification. Then, in the source code directory, create nut_cache.scala and use the following code to instantiate the Cache and convert it into Verilog code:

```scala
package ut_nutshell

import chisel3._
import chisel3.util._
import nutcore._
import top._
import chisel3.stage._

object CacheMain extends App {
  (new ChiselStage).execute(args, Seq(
      ChiselGeneratorAnnotation(() => new Cache()(CacheConfig(ro = false, name = "tcache", userBits = 16)))
    ))
}
```

### Generating RTL
After creating all the files (build.sc, src/main/scala/nut_cache.scala), execute the following command in the cache-ut directory:

```bash
mkdir build
mill --no-server -d ut.runMain ut_nutshell.CacheMain --target-dir build --output-file Cache
```

Note: For the Mill environment configuration, please refer to [https://mill-build.com/mill/Intro_to_Mill.html](https://mill-build.com/mill/Intro_to_Mill.html).

After successfully executing the above command, a Verilog file Cache.v will be generated in the build directory. Then, the picker tool can be used to convert Cache.v into a Python module. Besides Chisel, almost all other HCL languages can generate corresponding RTL codes, so the basic process above also applies to other HCLs.


### DUT Compilation

Generally, if you need the DUT to generate waveforms, coverage, etc., it will slow down the DUT's execution speed. Therefore, when generating a Python module through the picker tool, it will be generated according to various configurations: (1) Turn off all debug information; (2) Enable waveforms; (3) Enable code line coverage. The first configuration aims to quickly build the environment for regression testing, etc.; the second is used to analyze specific errors, timing, etc.; the third is used to improve coverage.
