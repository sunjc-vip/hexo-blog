---
title: JavaScript 中的作用域与作用域链详解
index_img: https://sunjc.vip/oss/2026/03/bb.webp
date: 2024-04-09 15:32:18
tags: JavaScript
comments: true
---

# JavaScript 中的作用域与作用域链详解

理解作用域（Scope）和作用域链（Scope Chain），是掌握 JavaScript 变量查找、闭包、模块化等高级特性的基础。很多“变量找不到”“值被意外覆盖”的问题，最终都可以归结到对作用域理解不清。

本文从基础概念到常见坑，系统讲清楚：

- 什么是作用域？全局作用域、函数作用域、块级作用域分别是什么？
- 作用域链是如何工作的？变量查找的顺序如何？
- var / let / const 在作用域上的区别？
- 提升（Hoisting）、暂时性死区（TDZ）究竟是怎么回事？

---

## 一、作用域是什么？

**定义：**

> 作用域是变量（包括函数、类等标识符）在代码中的“可见范围”和“可访问区域”。

简单说：**在哪些代码位置可以访问到某个变量**，取决于该变量所在的作用域。

在 JavaScript 中，主要有三类作用域：

1. 全局作用域（Global Scope）
2. 函数作用域（Function Scope）
3. 块级作用域（Block Scope，ES6 新增）

---

## 二、全局作用域

在最外层（非函数、非块级代码中）声明的变量，属于全局作用域：

```js
var a = 1;
let b = 2;
const c = 3;

function foo() {
  console.log(a, b, c);
}
```

特征：

- 在整个脚本中都可以访问。
- 浏览器环境中，`var` 声明的全局变量会挂在 `window` 上，而 `let` / `const` 不会：

```js
var x = 1;
let y = 2;

console.log(window.x); // 1
console.log(window.y); // undefined
```

> 建议：日常开发中尽量减少全局变量的使用，避免命名冲突与污染。

---

## 三、函数作用域

每个函数调用都会创建一个独立的“函数作用域”：

```js
function foo() {
  var x = 1;
  let y = 2;
  const z = 3;
}

console.log(typeof x); // "undefined"
```

特征：

- 函数内部声明的变量，外部无法直接访问。
- `var/let/const` 在函数内部声明时，都是函数作用域内的局部变量。

---

## 四、块级作用域（let / const）

ES6 以后，使用 `let` / `const` 可以引入块级作用域：

```js
{
  let x = 1;
  const y = 2;
}

console.log(typeof x); // "undefined"
```

任何一对 `{}`（如 if、for、while、普通代码块）都会形成块级作用域：

```js
if (true) {
  let a = 1;
}

for (let i = 0; i < 3; i++) {
  // i 只在 for 块内部可见
}
```

而 `var` **没有块级作用域** 概念，只受函数作用域影响：

```js
if (true) {
  var a = 1;
}

console.log(a); // 1
```

---

## 五、作用域链：变量是如何被查找到的？

当你在某一行代码中使用变量时，JavaScript 引擎会按照“由内到外”的顺序查找：

1. 当前作用域是否有这个标识符？
2. 如果没有，去它的**上级作用域**找（词法上最近的外层）
3. 再没有，就继续往外，直到全局作用域
4. 找不到则抛出 `ReferenceError`

这条“由内向外的链路”，就是 **作用域链**。

```js
const a = 1;

function foo() {
  const b = 2;

  function bar() {
    const c = 3;
    console.log(a, b, c);
  }

  bar();
}

foo(); // 1 2 3
```

在 `bar` 内部访问变量时，引擎的查找顺序：

- 先看 `bar` 内部 → 找到 `c`
- 没有 `b`，向外找到 `foo` 的作用域 → 找到 `b`
- 再向外找到全局作用域 → 找到 `a`

这也是闭包能够“记住”外层变量的基础。

---

## 六、var / let / const 在作用域上的区别

### 1. var

- 函数作用域，没有块级作用域
- 存在**变量提升**：声明会被提升到当前作用域顶部
- 可以重复声明同名变量（不推荐）

```js
console.log(x); // undefined（声明被提升，赋值未提升）
var x = 1;

if (true) {
  var y = 2;
}
console.log(y); // 2
```

### 2. let / const

- 具有块级作用域
- 也会“提升”，但在声明前无法访问（暂时性死区，TDZ）
- 不允许在同一作用域内重复声明同名变量

```js
console.log(a); // ReferenceError: Cannot access 'a' before initialization
let a = 1;
```

**const 额外特性：**

- 只能赋值一次（对引用类型来说，常量的是“引用地址”，不是内容）

```js
const obj = { x: 1 };
obj.x = 2;      // OK
// obj = {}    // TypeError
```

---

## 七、变量提升与暂时性死区（TDZ）

### 1. 变量提升（Hoisting）

在 JavaScript 中，**变量声明会在代码执行前被处理**，这就是“提升”：

```js
console.log(a); // undefined
var a = 1;
```

等价于：

```js
var a;
console.log(a);
a = 1;
```

函数声明也会被提升，并且优先级高于变量声明：

```js
foo(); // 正常调用

function foo() {}
```

### 2. 暂时性死区（TDZ）

`let` / `const` 也会被“提升”，但在实际初始化之前访问会抛错，这段从“作用域开始到变量声明完成”的区域称为 **暂时性死区**。

```js
{
  // TDZ 开始
  // console.log(x); // ReferenceError
  let x = 1; // 声明+初始化，TDZ 结束
}
```

好处：

- 避免“先访问、再声明”的隐式 bug，更容易发现错误

---

## 八、常见坑与面试题

### 1. for 循环与闭包

```js
var btns = document.querySelectorAll("button");

for (var i = 0; i < btns.length; i++) {
  btns[i].onclick = function () {
    console.log(i);
  };
}
```

点击任意按钮，输出的都是最后的 `i` 值。

原因：

- `var` 没有块级作用域，所有回调共享同一个 `i`（循环结束时 i 已为 `btns.length`）

解决：

- 使用 `let`：

```js
for (let i = 0; i < btns.length; i++) {
  btns[i].onclick = function () {
    console.log(i);
  };
}
```

或使用立即执行函数（IIFE）创建额外作用域：

```js
for (var i = 0; i < btns.length; i++) {
  (function (i) {
    btns[i].onclick = function () {
      console.log(i);
    };
  })(i);
}
```

### 2. 块级作用域与函数声明

在某些旧浏览器/环境中，块级中的 `function` 声明行为不一致，建议：

- 避免在块级作用域内使用裸 `function foo(){}` 声明
- 可以使用 `const foo = function () {}` 替代

---

## 九、总结

本文从三个层面梳理了 JavaScript 中的作用域体系：

- **类型**：全局作用域、函数作用域、块级作用域
- **查找机制**：作用域链，自内向外逐级查找
- **关键差异**：`var` 只有函数作用域，存在变量提升；`let/const` 有块级作用域，存在 TDZ

理解这些之后，再配合闭包、模块、事件循环等知识，就能更自信地阅读和编写复杂的 JavaScript 代码。
