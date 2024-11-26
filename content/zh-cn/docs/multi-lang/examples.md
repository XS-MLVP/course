---
title: 验证案例
description: 多语言案例介绍
categories: [教程]
tags: [docs]
weight: 3
---

## 加法器

以Adder为例，各语言的验证代码和注释如下：

{{<lang-group languages="cpp,java,scala,python,go">}}

{{<lang lang="cpp" show="true">}}
#include "UT_Adder.hpp"

int64_t random_int64()
{
    static std::random_device rd;
    static std::mt19937_64 generator(rd());
    static std::uniform_int_distribution<int64_t> distribution(INT64_MIN,
                                                               INT64_MAX);
    return distribution(generator);
}

int main()
{
    UTAdder *dut = new UTAdder();
    dut->Step(1);
    printf("Initialized UTAdder\n");

    struct input_t {
        uint64_t a;
        uint64_t b;
        uint64_t cin;
    };

    struct output_t {
        uint64_t sum;
        uint64_t cout;
    };

    for (int c = 0; c < 114514; c++) {
        input_t i;
        output_t o_dut, o_ref;

        i.a   = random_int64();
        i.b   = random_int64();
        i.cin = random_int64() & 1;

        auto dut_cal = [&]() {
            dut->a   = i.a;
            dut->b   = i.b;
            dut->cin = i.cin;
            dut->Step(1);
            o_dut.sum  = (uint64_t)dut->sum;
            o_dut.cout = (uint64_t)dut->cout;
        };

        auto ref_cal = [&]() {
            uint64_t sum = i.a + i.b;
            bool carry   = sum < i.a;

            sum += i.cin;
            carry = carry || sum < i.cin;

            o_ref.sum  = sum;
            o_ref.cout = carry ;
        };

        dut_cal();
        ref_cal();
        printf("[cycle %lu] a=0x%lx, b=0x%lx, cin=0x%lx\n", dut->xclock.clk, i.a,
               i.b, i.cin);
        printf("DUT: sum=0x%lx, cout=0x%lx\n", o_dut.sum, o_dut.cout);
        printf("REF: sum=0x%lx, cout=0x%lx\n", o_ref.sum, o_ref.cout);
        Assert(o_dut.sum == o_ref.sum, "sum mismatch");
    }

    dut->Finish();
    printf("Test Passed, destory UTAdder\n");
    return 0;
}
{{</lang>}}

{{<lang lang="java">}}
package com.ut;

import java.math.BigInteger;

// import the generated UT class
import com.ut.UT_Adder;

public class example {
    static public void main(String[] args){
        UT_Adder adder = new UT_Adder();
        for(int i=0; i<10000; i++){
            int N = 1000000;
            long a = (long) (Math.random() * N);
            long b = (long) (Math.random() * N);
            long c = (long) (Math.random() * N) > 50 ? 1 : 0;
            // set inputs
            adder.a.Set(a);
            adder.b.Set(b);
            adder.cin.Set(c);
            // step
            adder.Step();
            // reference model
            long sum = a + b;
            boolean carry = sum < a ? true : false;
            sum += c;
            carry = carry || sum < c;
            // assert
            assert adder.sum.U().longValue() == sum : "sum mismatch: " + adder.sum.U() + " != " + sum;
            assert adder.cout.U().intValue() == (carry ? 1 : 0) : "carry mismatch: " + adder.cout.U() + " != " + carry;
        }
        System.out.println("Java tests passed");
        adder.Finish();
    }
}
{{</lang>}}

{{<lang lang="scala">}}
package com.ut

import java.lang.Math
import com.ut.UT_Adder

object example {
    def main(args: Array[String]): Unit = {
      val adder = new UT_Adder()
      for (i <- 0 until 10000) {
        val N = 1000000
        val a = (Math.random() * N).toLong
        val b = (Math.random() * N).toLong
        val c = if ((Math.random() * N).toLong > 50) 1 else 0

        // set inputs
        adder.a.Set(a)
        adder.b.Set(b)
        adder.cin.Set(c)

        // step
        adder.Step()

        // reference model
        var sum = a + b
        var carry = if (sum < a) true else false
        sum += c
        carry = carry || (sum < c)

        // assert
        assert(adder.sum.U().longValue() == sum, s"sum mismatch: ${adder.sum.U()} != $sum")
        assert(adder.cout.U().intValue() == (if (carry) 1 else 0), s"carry mismatch: ${adder.cout.U()} != $carry")
        println(s"[cycle ${adder.xclock.getClk().intValue()}] a=${adder.a.U64()}, b=${adder.b.U64()}, cin=${adder.cin.U64()}")
      }
      println("Scala tests passed")
      adder.Finish()
    }
}
{{</lang>}}

{{<lang lang="python">}}
from UT_Adder import *

import random

class input_t:
    def __init__(self, a, b, cin):
        self.a = a
        self.b = b
        self.cin = cin

class output_t:
    def __init__(self):
        self.sum = 0
        self.cout = 0

def random_int():
    return random.randint(-(2**127), 2**127 - 1) & ((1 << 128) - 1)

def as_uint(x, nbits):
    return x & ((1 << nbits) - 1)

def main():
    dut = DUTAdder()  # Assuming USE_VERILATOR
    
    print("Initialized UTAdder")
    
    for c in range(11451):
        i = input_t(random_int(), random_int(), random_int() & 1)
        o_dut, o_ref = output_t(), output_t()
        
        def dut_cal():
            dut.a.value, dut.b.value, dut.cin.value = i.a, i.b, i.cin
            dut.Step(1)
            o_dut.sum = dut.sum.value
            o_dut.cout = dut.cout.value
        
        def ref_cal():
            sum = as_uint( i.a + i.b + i.cin, 128+1)
            o_ref.sum = as_uint(sum, 128)
            o_ref.cout = as_uint(sum >> 128, 1)
        
        dut_cal()
        ref_cal()
        
        print(f"[cycle {dut.xclock.clk}] a=0x{i.a:x}, b=0x{i.b:x}, cin=0x{i.cin:x}")
        print(f"DUT: sum=0x{o_dut.sum:x}, cout=0x{o_dut.cout:x}")
        print(f"REF: sum=0x{o_ref.sum:x}, cout=0x{o_ref.cout:x}")
        
        assert o_dut.sum == o_ref.sum, "sum mismatch"

    dut.Finish()
    
    print("Test Passed, destroy UTAdder")

if __name__ == "__main__":
    main()
{{</lang>}}

{{<lang lang="go">}}
package main

import (
	"fmt"
    "time"
    "math/rand"
    ut "UT_Adder"
)

func assert(cond bool, msg string) {
    if !cond {
        panic(msg)
    }
}

func main() {
    adder := ut.NewUT_Adder()
    rand.Seed(time.Now().UnixNano())
    for i := 0; i < 10000; i++ {
        N := 1000000
        a := rand.Int63n(int64(N))
        b := rand.Int63n(int64(N))
        var c int64
        if rand.Int63n(int64(N)) > 50 {
            c = 1
        } else {
            c = 0
        }

        adder.A.Set(a)
        adder.B.Set(b)
        adder.Cin.Set(c)

        adder.Step()

        // reflerence model
        sum := a + b
        carry := sum < a
        sum += c
        carry = carry || sum < c

        // assert
        assert(adder.Sum.U64() == uint64(sum), fmt.Sprintf("sum mismatch: %d != %d\n", adder.Sum.U64(), uint64(sum)))
        
        var carry_bool uint64
        if carry {
            carry_bool = 1
        } else {
            carry_bool = 0
        }
        assert(adder.Cout.U64() == carry_bool, fmt.Sprintf("carry mismatch: %d != %t\n", adder.Cout.U().Int64(), carry))
    }
    adder.Finish();
    fmt.Println("Golang tests passed")
}
{{</lang>}}


{{</lang-group>}}

## CoupledL2

`CoupledL2`是一个非阻塞的[L2 Cache](https://github.com/OpenXiangShan/CoupledL2)。

下面的代码会对`CoupledL2`进行简单的验证，并使用数组作为参考模型，验证过程如下：

1. 生成随机的地址`addr`、执行`AcquireBlock`，请求读取`addr`的数据。
2. 执行`GrantData`，接收`DUT`响应的数据。
3. 把接收到的数据和参考模型的内容进行比较，验证行为是否一致。
4. 执行`GrantAck`，响应`DUT`。
5. 执行`ReleaseData`，向`DUT`请求在`addr`写入随机数据`data`。
6. 同步参考模型，把`addr`的数据更新为`data`。
7. 执行`ReleaseAck`，接收`DUT`的写入响应。

上述步骤会重复4000次。

验证代码：

{{<lang-group languages="cpp,java">}}

{{<lang lang="cpp" show="true">}}
#include "UT_CoupledL2.hpp"
using TLDataArray = std::array<uint64_t, 2>;

enum class OpcodeA : uint32_t {
  PutFullData = 0x0,
  PutPartialData = 0x1,
  ArithmeticData = 0x2,
  LogicalData = 0x3,
  Get = 0x4,
  Hint = 0x5,
  AcquireBlock = 0x6,
  AcquirePerm = 0x7,
};

enum class OpcodeB : uint32_t { ProbeBlock = 0x6, ProbePerm = 0x7 };

enum class OpcodeC : uint32_t { ProbeAck = 0x4, ProbeAckData = 0x5, Release = 0x6, ReleaseData = 0x7 };

enum class OpcodeD : uint32_t { AccessAck, AccessAckData, HintAck, Grant = 0x4, GrantData = 0x5, ReleaseAck = 0x6 };

enum class OpcodeE : uint32_t { GrantAck = 0x4 };

static constexpr std::initializer_list<const char *> ARGS = {"+verilator+rand+reset+0"};
static auto dut = UTCoupledL2(ARGS);
static auto &clk = dut.xclock;

inline void sendA(OpcodeA opcode, uint32_t size, uint32_t address) {
  const auto &valid = dut.master_port_0_0_a_valid;
  const auto &ready = dut.master_port_0_0_a_ready;
  while (ready.value == 0x0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_a_bits_opcode.value = opcode;
  dut.master_port_0_0_a_bits_size.value = size;
  dut.master_port_0_0_a_bits_address.value = address;
  clk.Step();
  valid.value = 0;
}

inline void getB() {
  assert(false);
  const auto &valid = dut.master_port_0_0_b_valid;
  const auto &ready = dut.master_port_0_0_b_ready;
  ready.value = 1;
  while (valid.value == 0)
    clk.Step();
  dut.master_port_0_0_b_bits_opcode = 0x0;
  dut.master_port_0_0_b_bits_param = 0x0;
  dut.master_port_0_0_b_bits_size = 0x0;
  dut.master_port_0_0_b_bits_source = 0x0;
  dut.master_port_0_0_b_bits_address = 0x0;
  dut.master_port_0_0_b_bits_mask = 0x0;
  dut.master_port_0_0_b_bits_data = 0x0;
  dut.master_port_0_0_b_bits_corrupt = 0x0;
  clk.Step();
  ready.value = 0;
}

inline void sendC(OpcodeC opcode, uint32_t size, uint32_t address, uint64_t data) {
  const auto &valid = dut.master_port_0_0_c_valid;
  const auto &ready = dut.master_port_0_0_c_ready;

  while (ready.value == 0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_c_bits_opcode.value = opcode;
  dut.master_port_0_0_c_bits_size.value = size;
  dut.master_port_0_0_c_bits_address.value = address;
  dut.master_port_0_0_c_bits_data.value = data;
  clk.Step();
  valid.value = 0;
}

inline void getD() {
  const auto &valid = dut.master_port_0_0_d_valid;
  const auto &ready = dut.master_port_0_0_d_ready;
  ready.value = 1;
  clk.Step();
  while (valid.value == 0) clk.Step();
  ready.value = 0;
}

inline void sendE(uint32_t sink) {
  const auto &valid = dut.master_port_0_0_e_valid;
  const auto &ready = dut.master_port_0_0_e_ready;
  while (ready.value == 0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_e_bits_sink.value = sink;
  clk.Step();
  valid.value = 0;
}

inline void AcquireBlock(uint32_t address) { sendA(OpcodeA::AcquireBlock, 0x6, address); }

inline void GrantData(TLDataArray &r_data) {
  const auto &opcode = dut.master_port_0_0_d_bits_opcode;
  const auto &data = dut.master_port_0_0_d_bits_data;

  for (int i = 0; i < 2; i++) {
    do { getD(); } while (opcode.value != OpcodeD::GrantData);
    r_data[i] = data.value;
  }
}

inline void GrantAck(uint32_t sink) { sendE(sink); }

inline void ReleaseData(uint32_t address, const TLDataArray &data) {
  for (int i = 0; i < 2; i++)
    sendC(OpcodeC::ReleaseData, 0x6, address, data[i]);
}

inline void ReleaseAck() {
  const auto &opcode = dut.master_port_0_0_d_bits_opcode;
  do { getD(); } while (opcode.value != OpcodeD::ReleaseAck);
}

int main() {
  TLDataArray ref_data[16] = {};
  /* Random generator */
  std::random_device rd;
  std::mt19937_64 gen_rand(rd());
  std::uniform_int_distribution<uint32_t> distrib(0, 0xf - 1);

  /* DUT init */
  dut.InitClock("clock");
  dut.reset.SetWriteMode(xspcomm::WriteMode::Imme);
  dut.reset.value = 1;
  clk.Step();
  dut.reset.value = 0;
  for (int i = 0; i < 100; i++) clk.Step();

  /* Test loop */
  for (int test_loop = 0; test_loop < 4000; test_loop++) {
    uint32_t d_sink;
    TLDataArray data{}, r_data{};
    /* Generate random */
    const auto address = distrib(gen_rand) << 6;
    for (auto &i : data)
      i = gen_rand();

    printf("[CoupledL2 Test\t%d]: At address(0x%03x), ", test_loop + 1, address);
    /* Read */
    AcquireBlock(address);
    GrantData(r_data);
    
    // Print read result
    printf("Read: ");
    for (const auto &x : r_data)
      printf("%08lx", x);
    
    d_sink = dut.master_port_0_0_d_bits_sink.value;
    assert ((r_data == ref_data[address >> 6]) && "Read Failed");
    GrantAck(d_sink);
    
    /* Write */
    ReleaseData(address, data);
    ref_data[address >> 6] = data;
    ReleaseAck();
    
    // Print write data
    printf(", Write: ");
    for (const auto &x : data)
      printf("%08lx", x);
    printf(".\n");
  }

  return 0;
}
{{</lang>}}


{{<lang lang="java">}}
import com.ut.UT_CoupledL2;
import com.xspcomm.WriteMode;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.Random;
import java.util.random.RandomGenerator;

class Opcode {
    public enum A {
        PutFullData(0x0),
        PutPartialData(0x1),
        ArithmeticData(0x2),
        LogicalData(0x3),
        Get(0x4),
        Hint(0x5),
        AcquireBlock(0x6),
        AcquirePerm(0x7);

        private final int value;
    
        A(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum B {
        ProbeBlock(0x6), ProbePerm(0x7);
    
        private final int value;
    
        B(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum C {
        ProbeAck(0x4), ProbeAckData(0x5), Release(0x6), ReleaseData(0x7);
    
        private final int value;
    
        C(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum D {
        AccessAck(0x0), AccessAckData(0x1), HintAck(0x2), Grant(0x4), GrantData(0x5), ReleaseAck(0x6);
    
        private final int value;
    
        D(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum E {
        GrantAck(0x4);
    
        private final int value;
    
        E(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
}

public class TestCoupledL2 {
    static PrintWriter pwOut = new PrintWriter(new BufferedWriter(new OutputStreamWriter(System.out)));
    static UT_CoupledL2 dut;

    static void sendA(int opcode, int size, int address) {
        var valid = dut.master_port_0_0_a_valid;
        var ready = dut.master_port_0_0_a_ready;
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_a_bits_opcode.Set(opcode);
        dut.master_port_0_0_a_bits_size.Set(size);
        dut.master_port_0_0_a_bits_address.Set(address);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void getB() {
        var valid = dut.master_port_0_0_b_valid;
        var ready = dut.master_port_0_0_b_ready;
        ready.Set(1);
        while (!valid.B()) dut.xclock.Step();
        ready.Set(0);
    }
    
    static void sendC(int opcode, int size, int address, long data) {
        var valid = dut.master_port_0_0_c_valid;
        var ready = dut.master_port_0_0_c_ready;
    
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_c_bits_opcode.Set(opcode);
        dut.master_port_0_0_c_bits_size.Set(size);
        dut.master_port_0_0_c_bits_address.Set(address);
        dut.master_port_0_0_c_bits_data.Set(data);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void getD() {
        var valid = dut.master_port_0_0_d_valid;
        var ready = dut.master_port_0_0_d_ready;
        ready.Set(1);
        dut.xclock.Step();
        while (!valid.B()) dut.xclock.Step();
        ready.Set(0);
    }
    
    static void sendE(int sink) {
        var valid = dut.master_port_0_0_e_valid;
        var ready = dut.master_port_0_0_e_ready;
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_e_bits_sink.Set(sink);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void AcquireBlock(int address) {
        sendA(Opcode.A.AcquireBlock.getValue(), 0x6, address);
    }
    
    static BigInteger GrantData() {
        var opcode = dut.master_port_0_0_d_bits_opcode;
        var data = dut.master_port_0_0_d_bits_data;
    
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.GrantData.getValue());
        var r_data = data.U64().shiftLeft(64);
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.GrantData.getValue());
        return r_data.or(data.U64());
    }
    
    static void GrantAck(int sink) {
        sendE(sink);
    }
    
    static void ReleaseData(int address, BigInteger data) {
        sendC(Opcode.C.ReleaseData.getValue(), 0x6, address, data.longValue());
        sendC(Opcode.C.ReleaseData.getValue(), 0x6, address, data.shiftRight(64).longValue());
    }
    
    static void ReleaseAck() {
        var opcode = dut.master_port_0_0_d_bits_opcode;
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.ReleaseAck.getValue());
    }
    
    public static void main(String[] args) throws IOException {
        /* Random Generator */
        var gen_rand = RandomGenerator.getDefault();
        /* DUT init */
        final String[] ARGS = {"+verilator+rand+reset+0"};
        dut = new UT_CoupledL2(ARGS);
        dut.InitClock("clock");
        dut.reset.SetWriteMode(WriteMode.Imme);
        dut.reset.Set(1);
        dut.xclock.Step();
        dut.reset.Set(0);
        for (int i = 0; i < 100; i++) dut.xclock.Step();
        dut.xclock.Step();
    
        /* Ref */
        BigInteger[] ref_data = new BigInteger[16];
        Arrays.fill(ref_data, BigInteger.ZERO);
    
        /* Test loop */
        for (int test_loop = 0; test_loop < 4000; test_loop++) {
            var address = gen_rand.nextInt(0xf) << 6;
            var data = new BigInteger(128, Random.from(gen_rand));
    
            pwOut.print("[CoupledL2 Test%d]: At address(%#03x), ".formatted(test_loop + 1, address));
            /* Read */
            AcquireBlock(address);
            var r_data = GrantData();
            assert (r_data.equals(ref_data[address >> 6]));
    
            var sink = dut.master_port_0_0_d_bits_sink.Get().intValue();
            GrantAck(sink);


            /* Write */
            ReleaseData(address, data);
            ref_data[address >> 6] = data;
            ReleaseAck();
    
            pwOut.println("Read: %s, Write: %s".formatted(r_data.toString(), data.toString()));
            pwOut.flush();
        }
    }
}

{{</lang>}}

{{</lang-group>}}
