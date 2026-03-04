---
title: JavaScript 中 this 指向
index_img: https://sunjc.vip/oss/2026/03/iShot_2026-03-04_10.16.33.webp
date: 2024-02-18 10:23:45
tags: JavaScript
comments: true
---

# JavaScript 中 this 指向

`this` 是 JavaScript 中最容易被问、也最容易写错的知识点之一。它既和**函数的调用方式**有关，又受到 **严格模式 / 非严格模式**、箭头函数、事件处理等多种场景的影响。

本文从“规则优先”的视角，系统地梳理 JavaScript 中 `this` 的所有常见指向场景，并配合例子与常见坑，帮助你彻底搞清楚：

- `this` 的绑定规则是什么？
- 箭头函数中的 `this` 为何 “长相随”？
- 构造函数、class、事件、定时器中的 `this` 分别指向哪里？
- 实际开发中如何规避因为 `this` 导致的 bug？

---

## 一、核心原则：this 与“调用方式”绑定，而不是定义位置

很多人一开始容易把 `this` 理解成 “当前文件 / 当前对象”，这是错误的。

**本质规则：**

> `this` 的指向只在函数被调用的“那一刻”确定，与函数的定义位置、函数名本身都无关。

同一个函数，在不同调用方式下，`this` 完全可以不一样：

```js
function foo() {
  console.log(this);
}

foo();              // 非严格模式：window / globalThis；严格模式：undefined
obj.foo();          // this === obj
foo.call(bar);      // this === bar
new foo();          // this === 新创建的实例对象
```

---

## 二、五大绑定规则总览

可以把 `this` 归纳为五大绑定规则（按优先级理解）：

1. **`new` 绑定**：构造调用
2. **显式绑定**：`call` / `apply` / `bind`
3. **隐式绑定**：作为对象方法调用（`obj.fn()`）
4. **默认绑定**：普通函数调用（非严格模式指向全局对象，严格模式下为 `undefined`）
5. **箭头函数绑定**：词法绑定（不是上面四条，而是“外层作用域的 this”）

### 1. new 绑定（构造函数 / class）

当函数通过 `new` 调用时，会发生以下步骤：

1. 创建一个全新的空对象
2. 将这个对象的原型指向构造函数的 prototype
3. 将函数内部的 `this` 绑定到这个新对象上
4. 如果显式 `return` 一个对象，则返回该对象；否则返回步骤 1 创建的新对象

```js
function Person(name) {
  this.name = name;
}

const p = new Person("Sunjc");
console.log(p.name); // "Sunjc"
```

在 class 中本质也是一样：

```js
class Person {
  constructor(name) {
    this.name = name;
  }
}
```

**优先级上**，`new` 绑定高于 `call/apply/bind`：

```js
function Foo() {
  console.log(this);
}

const obj = { x: 1 };
const f = Foo.bind(obj);

new f(); // this 是新创建的实例对象，而不是 obj
```

### 2. 显式绑定：call / apply / bind

通过 `call` / `apply` / `bind` 可以显式指定 `this`：

```js
function foo(a, b) {
  console.log(this, a, b);
}

foo.call({ x: 1 }, 1, 2);      // this = { x: 1 }
foo.apply({ x: 2 }, [3, 4]);   // this = { x: 2 }

const bar = foo.bind({ x: 3 }, 5);
bar(6);                        // this = { x: 3 }，参数为 5, 6
```

`bind` 返回的是一个**新的函数**，其 `this` 永久绑定到指定对象上（除非作为构造函数被 `new` 调用）。

### 3. 隐式绑定：作为对象方法调用

当函数通过 `obj.fn()` 的形式调用时，`this` 指向调用它的对象：

```js
function foo() {
  console.log(this.a);
}

const obj = {
  a: 1,
  foo,
};

obj.foo(); // 1，this === obj
```

#### 隐式丢失（高频坑点）

```js
const obj = {
  a: 1,
  foo() {
    console.log(this.a);
  },
};

const bar = obj.foo;
bar(); // this 不再是 obj，而是默认绑定（window / undefined）
```

解决办法：

- 在定义时 `foo: obj.foo.bind(obj)`
- 或使用箭头函数封装
- 或在调用前使用 `call/apply`

### 4. 默认绑定：普通函数调用

```js
function foo() {
  console.log(this);
}

foo(); // 非严格模式：window；严格模式："use strict" 下为 undefined
```

在浏览器中全局执行环境下，非严格模式下 `this` 默认指向 `window`。

在严格模式下（推荐），如果没有明确绑定，`this` 为 `undefined`，有利于早期发现错误。

### 5. 箭头函数：this 来自外层词法作用域

箭头函数本身 **没有自己的 this**：

```js
const obj = {
  a: 1,
  foo() {
    setTimeout(function () {
      console.log(this.a);
    }, 0);
  },
};

obj.foo(); // 浏览器中：undefined 或报错（严格模式），因为 this 指向 window/undefined
```

改写为箭头函数：

```js
const obj = {
  a: 1,
  foo() {
    setTimeout(() => {
      console.log(this.a);
    }, 0);
  },
};

obj.foo(); // 1，箭头函数中的 this 来自 foo 调用时的 this（即 obj）
```

箭头函数常用来解决：

- 在回调/异步中保持外层 this 指向（如 class 方法里调用接口、定时器等）

---

## 三、常见场景下的 this 指向

### 1. DOM 事件回调

原生 DOM 事件中，默认 `this` 指向触发事件的元素：

```js
button.addEventListener("click", function () {
  console.log(this === button); // true
});
```

如果改用箭头函数：

```js
button.addEventListener("click", () => {
  console.log(this); // 外层作用域的 this，通常不是 button
});
```

在框架中（如 Vue/React），通常不会直接依赖原生 `this`，而是用组件实例或 hooks 管理上下文。

### 2. setTimeout / setInterval

```js
setTimeout(function () {
  console.log(this); // 浏览器中：window；严格模式下仍是 window（宿主环境行为）
}, 0);
```

若需要访问外部对象，可以：

- 使用箭头函数（`this` 为外层）
- 先缓存 `const self = this;` 再在回调中使用 `self`

### 3. class 方法

```js
class Counter {
  constructor() {
    this.count = 0;
  }

  add() {
    this.count++;
  }
}

const c = new Counter();
const fn = c.add;
fn(); // 严格模式下：this 为 undefined，会报错
```

解决：

- 在构造函数中手动绑定：`this.add = this.add.bind(this);`
- 或使用类字段 + 箭头函数：

```js
class Counter {
  count = 0;

  add = () => {
    this.count++;
  };
}
```

---

## 四、this 相关的常见面试题与易错点

### 1. 链式调用中的 this

```js
const obj = {
  a: 1,
  foo() {
    console.log(this.a);
    return this;
  },
};

obj.foo().foo(); // 1, 1
```

链式调用的关键：方法返回 `this`。

### 2. 箭头函数不能作为构造函数

```js
const Foo = () => {};
new Foo(); // TypeError: Foo is not a constructor
```

原因：箭头函数没有 `[[Construct]]` 内部方法，也没有 `prototype`。

### 3. 箭头函数的 this 不能通过 call/apply/bind 修改

```js
const arrow = () => {
  console.log(this);
};

arrow.call({ a: 1 }); // this 不会变，仍然是定义时外层作用域的 this
```

---

## 五、工程实践中的建议

1. **在严格模式下开发**：避免默认绑定到全局对象带来的隐式 bug。
2. **在 class/对象方法中优先使用箭头函数保存 this**（尤其在 React/Vue 组件、大量回调中）。
3. **少使用依赖 this 的 API 设计**，更多使用显式传参、闭包等方式传递上下文。
4. **对复杂的 this 逻辑写单元测试**，避免维护过程中因调用方式变化引入隐性 bug。

---

## 六、总结

JavaScript 中的 `this` 并不神秘，它遵循一套相对固定的规则：

- **new 绑定**：构造调用时绑定到新创建的实例对象。
- **显式绑定**：`call/apply/bind` 可以强制指定 this。
- **隐式绑定**：作为对象方法调用时，this 指向该对象。
- **默认绑定**：普通函数调用时，非严格模式下 this 为全局对象，严格模式下为 `undefined`。
- **箭头函数**：没有自己的 this，从外层词法作用域继承。

理解这套规则，并在实际开发中有意识地控制函数的“调用方式”，就能彻底摆脱被 this “反噬” 的困扰。
