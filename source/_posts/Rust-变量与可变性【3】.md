---
title: Rust-变量与可变性【3】
index_img: https://sunjc.vip/oss/2025/07/eQeiIp.png
date: 2025-07-24 19:11:33
tags: Rust
---

## 变量

> 1. 变量默认是不可改变的
> 2. 可以在变量名前添加 `mut` 来使其可变

```rust
fn main() {
    let mut x = 5;
    println!("The value of x is: {x}"); // 5
    x = 6;
    println!("The value of x is: {x}"); // 6
}
```

## 常量

> 1. 不允许改变的值
> 2. 不能 用 `mut` 修饰 总是不可变
> 3. 常量只能被设置为常量表达式，而不可以是其他任何只能在运行时计算出的值

```rust
fn main() {
    const THREE_HOURS_IN_SECONDS: u32 = 60 * 60 * 3;
    println!("Three hours in seconds is: {THREE_HOURS_IN_SECONDS}"); // 10800
}
```

## 遮蔽

> 我们可以定义一个与之前变量同名的新变量, 编译器看的是最后一个变量 前面定义的同名变量被遮蔽了
>
> **遮蔽与 `mut` 的区别**
>
> 1. 遮蔽 其实是创建了一个新变量 只是名字的复用
> 2. 遮蔽 可以改变变量的类型 mut 不能改变变量的类型

```rust
fn main() {
    let x = 5;
    let x = x + 1;
    {
        let x = x * 2;
        println!("The value of x in the inner scope is: {x}"); // 12
    }
    println!("The value of x is: {x}"); // 6
}
```
