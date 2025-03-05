---
title: 加法器
description: 使用C++、Java、Python和Golang验证加法器的案例
categories: [教程]
tags: [docs]
weight: 1
---

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
from Adder import *

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
