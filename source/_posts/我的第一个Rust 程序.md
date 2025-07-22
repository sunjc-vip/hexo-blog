---
title: 我的第一个Rust 程序
index_img: https://sunjc.vip/oss/2025/07/eQeiIp.png
date: 2025-07-22 12:00:00
tags: Rust
comments: true
---

## 猜数字游戏

- 游戏规则：猜数字游戏是一个经典的猜数字游戏，玩家需要猜一个 1 到 100 的数字。
- 游戏流程：
  - 游戏开始时，玩家需要输入一个 1 到 100 的数字。
  - 游戏会根据玩家的猜测给出提示，告诉他猜测的数字是太大了还是太小了。
  - 玩家需要根据提示继续猜测，直到猜中正确的数字。
- 游戏结束：
  - 当玩家猜中正确的数字时，游戏结束，玩家会得到恭喜的消息。

```rust
use std::cmp::Ordering;
use std::io;
use rand::Rng;

fn main() {
    println!("猜数字游戏！");

    let secret_number = rand::thread_rng().gen_range(1..=100);

    loop {
        println!("输入你猜的数字（1-100）");

        let mut guess = String::new();

        io::stdin()
            .read_line(&mut guess)
            .expect("请输入一个数字！");

        let guess: u32 = match guess.trim().parse() {
            Ok(num) => num,
            Err(_) => continue,
        };

        println!("你猜的数字是：{guess}");

        match guess.cmp(&secret_number) {
            Ordering::Less => println!("太小了!"),
            Ordering::Greater => println!("太大了!"),
            Ordering::Equal => {
                println!("恭喜你猜对了!");
                break;
            }
        }
    }
}

```
