---
title: 手写Promise
index_img: https://img.sunjc.vip/2026/03/promise.webp
date: 2025-12-21 20:11:04
tags: JavaScript
comments: true
---

# 手写Promise


本文目标是：**写出一个可运行、满足 Promise/A+ 核心行为的手写 Promise**，并补齐 `then/catch/finally` 以及常用静态方法（`resolve/reject/all/race/allSettled/any`）。

---

## 一、Promise 要解决什么问题？

在 Promise 之前，回调地狱（callback hell）通常长这样：

```js
readFile("a.txt", (err, a) => {
  if (err) return handle(err);
  readFile(a.next, (err, b) => {
    if (err) return handle(err);
    readFile(b.next, (err, c) => {
      if (err) return handle(err);
      // ...
    });
  });
});
```

Promise 的价值：

- **把异步结果抽象为一个“未来值”对象**
- **让异步流程可链式表达**（`then` 链）
- **统一错误传播**（throw 或 reject 都走 `catch`）
- **标准化异步调度**（`then` 回调放到 microtask 队列）

---

## 二、Promise 的关键概念

### 1. 三种状态

Promise 只有三种状态：

- `pending`：初始态
- `fulfilled`：已成功（有 value）
- `rejected`：已失败（有 reason）

并且：**状态一旦改变就不可逆**（从 pending 到 fulfilled/rejected，不能再变回去）。

### 2. then 的两个回调

```js
promise.then(onFulfilled, onRejected);
```

- `onFulfilled(value)`：成功回调
- `onRejected(reason)`：失败回调

如果不传某个回调：

- `onFulfilled` 缺省等价于 `value => value`（值穿透）
- `onRejected` 缺省等价于 `reason => { throw reason }`（错误穿透）

这也是为什么你可以写：

```js
doA()
  .then(doB)
  .then(doC)
  .catch(handleError);
```

### 3. then 必须返回一个新 Promise

这是链式调用的基础：

```js
const p2 = p1.then(() => 123);
```

`p2` 的结果，取决于 `then` 回调的返回值：

- 返回普通值 → `p2` fulfilled 且 value 为该值
- 返回 Promise/thenable → `p2` 跟随它的最终状态
- 抛出异常 → `p2` rejected 且 reason 为该异常

### 4. “Promise 解析过程”（最核心的难点）

Promise/A+ 规范最难的部分是：当 `then` 回调返回 `x` 时，如何决定 `p2` 的命运。

伪规则（非常重要）：

1. 如果 `x === p2`，抛错（循环引用）
2. 如果 `x` 是对象或函数，尝试读取 `then = x.then`
3. 如果 `then` 是函数，按 thenable 方式调用：
   - `then.call(x, resolve, reject)`
   - 只允许 resolve/reject 被调用一次（需要 `called` 防重入）
4. 否则 `p2` 直接 `resolve(x)`

---

## 三、microtask：为什么 then 回调要异步执行？

原生 Promise 的 `then` 回调，会进入 **microtask（微任务）队列**：

```js
Promise.resolve().then(() => console.log("then"));
console.log("sync");
// 输出：sync then
```

因此我们手写 Promise 也要保证：

- **无论当前 Promise 是否已完成**，`then` 回调都必须异步执行
- 最好使用 `queueMicrotask`（现代浏览器/Node 都支持）

---

## 四、从 0 到 1：手写 Promise 实现

下面的实现遵循 Promise/A+ 的核心行为（`then` 链、thenable 解析、防循环、异常捕获、异步调度），并补充常用实例/静态方法。

> 说明：为了文章可读性，代码写在一个文件里；实际项目可拆分为模块。

```js
const PENDING = "pending";
const FULFILLED = "fulfilled";
const REJECTED = "rejected";

function isObjectOrFunction(x) {
  return (typeof x === "object" && x !== null) || typeof x === "function";
}

function queueMicrotaskLike(fn) {
  if (typeof queueMicrotask === "function") return queueMicrotask(fn);
  // 兜底：不保证 microtask，但保证异步
  setTimeout(fn, 0);
}

function resolvePromise(promise2, x, resolve, reject) {
  if (promise2 === x) {
    return reject(new TypeError("Chaining cycle detected for promise"));
  }

  if (isObjectOrFunction(x)) {
    let then;
    try {
      then = x.then; // 可能触发 getter 抛错
    } catch (err) {
      return reject(err);
    }

    if (typeof then === "function") {
      let called = false;
      try {
        then.call(
          x,
          (y) => {
            if (called) return;
            called = true;
            resolvePromise(promise2, y, resolve, reject);
          },
          (r) => {
            if (called) return;
            called = true;
            reject(r);
          }
        );
      } catch (err) {
        if (called) return;
        called = true;
        reject(err);
      }
      return;
    }
  }

  resolve(x);
}

export class MyPromise {
  state = PENDING;
  value = undefined;
  reason = undefined;

  onFulfilledCallbacks = [];
  onRejectedCallbacks = [];

  constructor(executor) {
    if (typeof executor !== "function") {
      throw new TypeError("Promise resolver is not a function");
    }

    const resolve = (value) => {
      if (this.state !== PENDING) return;

      // 关键：如果 resolve 的是 Promise，需要“跟随”
      if (value instanceof MyPromise) {
        return value.then(resolve, reject);
      }

      this.state = FULFILLED;
      this.value = value;
      this.onFulfilledCallbacks.forEach((fn) => fn());
      this.onFulfilledCallbacks = [];
      this.onRejectedCallbacks = [];
    };

    const reject = (reason) => {
      if (this.state !== PENDING) return;
      this.state = REJECTED;
      this.reason = reason;
      this.onRejectedCallbacks.forEach((fn) => fn());
      this.onFulfilledCallbacks = [];
      this.onRejectedCallbacks = [];
    };

    try {
      executor(resolve, reject);
    } catch (err) {
      reject(err);
    }
  }

  then(onFulfilled, onRejected) {
    const realOnFulfilled =
      typeof onFulfilled === "function" ? onFulfilled : (v) => v;
    const realOnRejected =
      typeof onRejected === "function"
        ? onRejected
        : (e) => {
            throw e;
          };

    const promise2 = new MyPromise((resolve, reject) => {
      const fulfilledTask = () => {
        queueMicrotaskLike(() => {
          try {
            const x = realOnFulfilled(this.value);
            resolvePromise(promise2, x, resolve, reject);
          } catch (err) {
            reject(err);
          }
        });
      };

      const rejectedTask = () => {
        queueMicrotaskLike(() => {
          try {
            const x = realOnRejected(this.reason);
            resolvePromise(promise2, x, resolve, reject);
          } catch (err) {
            reject(err);
          }
        });
      };

      if (this.state === FULFILLED) {
        fulfilledTask();
      } else if (this.state === REJECTED) {
        rejectedTask();
      } else {
        this.onFulfilledCallbacks.push(fulfilledTask);
        this.onRejectedCallbacks.push(rejectedTask);
      }
    });

    return promise2;
  }

  catch(onRejected) {
    return this.then(null, onRejected);
  }

  finally(onFinally) {
    const cb = typeof onFinally === "function" ? onFinally : () => {};
    return this.then(
      (value) => MyPromise.resolve(cb()).then(() => value),
      (reason) =>
        MyPromise.resolve(cb()).then(() => {
          throw reason;
        })
    );
  }

  // ---- 静态方法 ----
  static resolve(value) {
    if (value instanceof MyPromise) return value;
    return new MyPromise((resolve) => resolve(value));
  }

  static reject(reason) {
    return new MyPromise((_, reject) => reject(reason));
  }

  static all(iterable) {
    return new MyPromise((resolve, reject) => {
      const arr = Array.from(iterable);
      const results = new Array(arr.length);
      let count = 0;

      if (arr.length === 0) return resolve([]);

      arr.forEach((item, index) => {
        MyPromise.resolve(item).then(
          (value) => {
            results[index] = value;
            count++;
            if (count === arr.length) resolve(results);
          },
          (err) => reject(err)
        );
      });
    });
  }

  static race(iterable) {
    return new MyPromise((resolve, reject) => {
      for (const item of iterable) {
        MyPromise.resolve(item).then(resolve, reject);
      }
    });
  }

  static allSettled(iterable) {
    return new MyPromise((resolve) => {
      const arr = Array.from(iterable);
      const results = new Array(arr.length);
      let count = 0;

      if (arr.length === 0) return resolve([]);

      arr.forEach((item, index) => {
        MyPromise.resolve(item).then(
          (value) => {
            results[index] = { status: "fulfilled", value };
            count++;
            if (count === arr.length) resolve(results);
          },
          (reason) => {
            results[index] = { status: "rejected", reason };
            count++;
            if (count === arr.length) resolve(results);
          }
        );
      });
    });
  }

  static any(iterable) {
    return new MyPromise((resolve, reject) => {
      const arr = Array.from(iterable);
      const errors = new Array(arr.length);
      let rejectedCount = 0;

      if (arr.length === 0) {
        // 与原生一致：空数组 any 会 reject AggregateError
        return reject(new AggregateError([], "All promises were rejected"));
      }

      arr.forEach((item, index) => {
        MyPromise.resolve(item).then(
          resolve,
          (err) => {
            errors[index] = err;
            rejectedCount++;
            if (rejectedCount === arr.length) {
              reject(new AggregateError(errors, "All promises were rejected"));
            }
          }
        );
      });
    });
  }
}
```

---

## 五、手写 Promise 的常见坑

### 1. then 回调必须异步

如果你写成同步执行，会导致行为与原生不一致，例如：

```js
const p = MyPromise.resolve(1);
p.then(() => console.log("A"));
console.log("B");
```

正确输出应该是 `B A`。

### 2. 值穿透与错误穿透

不传 `onFulfilled` 时，后续应该拿到上一个 fulfilled 的值；不传 `onRejected` 时，错误应该继续往下抛，直到被 `catch` 捕获。

### 3. thenable 解析与 called 防重入

一些对象长得像 Promise：

```js
const thenable = {
  then(resolve, reject) {
    resolve(1);
    resolve(2); // 必须被忽略
  },
};
```

规范要求只第一次有效，所以要有 `called`。

### 4. 循环引用检测

```js
const p = new MyPromise((r) => r());
const p2 = p.then(() => p2); // 必须 reject TypeError
```

### 5. executor 中抛错应当 reject

```js
new MyPromise(() => {
  throw new Error("boom");
}).catch(console.log);
```

---

## 六、如何验证实现是否符合 Promise/A+？

如果你想把实现跑一遍 Promise/A+ 测试套件，可以使用社区工具 `promises-aplus-tests`（常见做法是导出一个“deferred”适配器）。

### 1. 安装

```bash
npm i -D promises-aplus-tests
```

### 2. 写一个 adapter（示例）

```js
// adapter.js
import { MyPromise } from "./MyPromise.js";

export const resolved = (v) => MyPromise.resolve(v);
export const rejected = (r) => MyPromise.reject(r);

export const deferred = () => {
  let resolve, reject;
  const promise = new MyPromise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
};
```

### 3. 运行测试

```bash
npx promises-aplus-tests adapter.js
```

如果你的 `then` 与 `resolvePromise` 实现正确，这套测试能覆盖大量边界情况。

---

## 七、总结

手写 Promise 是理解 JavaScript 异步机制的绝佳练习。通过实现一个符合 Promise/A+ 规范的版本，你可以深入理解 Promise 的状态管理、链式调用、错误传播以及 thenable 解析等核心概念。

