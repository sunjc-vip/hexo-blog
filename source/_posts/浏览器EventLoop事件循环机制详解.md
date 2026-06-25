---
title: 浏览器 Event Loop 事件循环机制详解
index_img: https://img.sunjc.vip/2026/03/jj.webp
date: 2024-01-29 08:42:56
tags: JavaScript
comments: true
---

# 浏览器 Event Loop 事件循环机制详解

在面试和日常调试中，几乎绕不开这样的问题：

- `setTimeout`、`Promise.then`、`async/await` 谁先执行？
- 为什么有时候 `console.log` 的顺序和直觉不一样？
- “宏任务 / 微任务” 到底是什么？

这些问题背后，都是 **Event Loop（事件循环）** 在发挥作用。

本文从浏览器环境出发，系统讲清楚：

- 同步任务、宏任务、微任务分别是什么？
- 浏览器的 Event Loop 一次循环都做了什么？
- 常见题目与坑点的执行顺序是怎样的？

---

## 一、JavaScript 的单线程与任务队列

JavaScript（在浏览器中）是单线程执行的，即：

- 同一时刻只能有一个任务在主线程上运行
- 其他任务需要排队等待

任务大致分为两大类：

1. **同步任务**：立即在主线程上按顺序执行
2. **异步任务**：交给浏览器其他模块处理，完成后将“回调”放入对应的任务队列中，等待主线程空闲时再执行

---

## 二、宏任务（Macro Task）与微任务（Micro Task）

在浏览器中，常见的任务队列类型包括：

### 1. 宏任务（Macro Task）

常见宏任务来源：

- 整体脚本执行（`script`）
- `setTimeout` / `setInterval`
- `setImmediate`（非标准，IE/Node 环境）
- DOM 事件回调
- XHR 回调

### 2. 微任务（Micro Task）

常见微任务来源：

- `Promise.then/catch/finally`
- `queueMicrotask`
- MutationObserver 回调

**优先级关系**：

> 每次执行完一个宏任务后，都会立即清空当前产生的所有微任务，然后再执行下一个宏任务。

---

## 三、浏览器 Event Loop 的一次循环流程

可以粗略理解为：

1. 从宏任务队列中取出一个任务，执行（如执行完一段 script 或 setTimeout 的回调）
2. 执行过程中如果产生了微任务，加入微任务队列
3. 当前宏任务执行结束后，立刻：
   - 进入微任务检查点
   - 按顺序依次执行所有微任务，直到队列清空
   - 微任务执行期间如果产生新的微任务，继续加入队列并执行，直到完全清空
4. 微任务执行完毕后，进行一次页面渲染（render）
5. 开始下一次事件循环，从宏任务队列中取下一个宏任务

---

## 四、经典例子：宏任务 vs 微任务执行顺序

示例一：

```js
console.log("start");

setTimeout(() => {
  console.log("timeout");
}, 0);

Promise.resolve()
  .then(() => {
    console.log("promise");
  });

console.log("end");
```

执行顺序分析：

1. 整体 script 作为第一个宏任务开始执行
   - `console.log("start")`
   - `setTimeout` 注册回调（放入宏任务队列）
   - `Promise.then` 注册回调（放入微任务队列）
   - `console.log("end")`
2. 当前宏任务（script）执行完成后 → 进入微任务检查点
   - 依次执行微任务队列中的回调：`console.log("promise")`
3. 微任务执行完毕 → 浏览器渲染 → 下一轮循环开始
4. 执行下一个宏任务（`setTimeout` 的回调）：`console.log("timeout")`

最终输出：

```text
start
end
promise
timeout
```

---

## 五、async/await 与 Event Loop

`async/await` 本质上是基于 Promise 的语法糖。

示例二：

```js
async function foo() {
  console.log("foo start");
  await Promise.resolve();
  console.log("foo end");
}

console.log("script start");
foo();
console.log("script end");
```

执行顺序：

1. `script start`
2. 进入 `foo`：
   - 输出 `foo start`
   - `await Promise.resolve()`：
     - `Promise.resolve()` 会立刻返回一个已 resolved 的 Promise
     - `await` 会让后面的代码（`console.log("foo end")`）封装成微任务，挂到这个 Promise 的 `then` 上
   - `foo` 函数返回一个 Promise（处于 pending 状态，后续在微任务中 resolve）
3. 执行 `console.log("script end")`
4. script 宏任务结束 → 执行微任务：
   - 执行 `then` 回调 → 输出 `foo end`

最终结果：

```text
script start
foo start
script end
foo end
```

---

## 六、嵌套微任务与宏任务的组合题

示例三：

```js
console.log(1);

setTimeout(() => {
  console.log(2);
  Promise.resolve().then(() => {
    console.log(3);
  });
}, 0);

Promise.resolve().then(() => {
  console.log(4);
  setTimeout(() => {
    console.log(5);
  }, 0);
});

console.log(6);
```

执行步骤：

1. script 宏任务：
   - 输出 `1`
   - 注册 `setTimeout` A（回调：输出 2 + 微任务 3）
   - 注册微任务 M1（输出 4 + 注册 setTimeout B）
   - 输出 `6`
2. script 结束 → 执行微任务队列：
   - M1：输出 `4`，注册 setTimeout B
3. 微任务执行完毕 → 渲染 → 下一轮宏任务：
   - 执行 setTimeout A：输出 `2`，注册微任务 M2（输出 3）
4. setTimeout A 宏任务结束 → 执行微任务队列：
   - M2：输出 `3`
5. 微任务执行完毕 → 渲染 → 下一轮宏任务：
   - 执行 setTimeout B：输出 `5`

最终输出顺序：

```text
1
6
4
2
3
5
```

---

## 七、DOM 渲染与微任务的关系

一般而言，浏览器会在：

1. 执行完一个宏任务
2. 清空对应的微任务队列

之后，决定是否进行一次页面渲染。

这意味着：

- 在同一宏任务中，你可以多次更新 DOM 或样式；
- 这些更新会被浏览器合并，减少重排重绘次数；
- 微任务中的 DOM 改动会在下一次绘制前生效。

---

## 八、Event Loop 与多线程/Worker 的关系

浏览器的 JavaScript 主线程是单线程的，但浏览器整体是多线程的：

- JS 主线程负责执行脚本
- 其他线程（如网络线程、定时器线程、渲染线程等）负责各自的任务

这些线程在任务完成时，会将“回调”推入主线程的宏任务/微任务队列中，等待 JS 主线程调度执行。

Web Worker 则是另外的 JS 线程，有自己的 Event Loop，与主线程之间通过 `postMessage` 进行通信。

---

## 九、工程实践中的注意点

1. **避免在微任务中“死循环”或不断添加新的微任务**，否则会阻塞宏任务执行与渲染。
2. 对于一些“批量更新但不需立即执行”的逻辑，可以考虑使用：
   - `requestAnimationFrame`（配合渲染节奏）
   - `setTimeout` 做适当延迟，降低优先级
3. 对动画、交互要求高的场景，注意：
   - 避免在单个宏任务中执行过长的同步任务
   - 必要时拆分任务或使用 Web Worker

---

## 十、总结

浏览器 Event Loop 的关键要点可以归纳为：

- JavaScript 在浏览器中是单线程的，通过“宏任务队列 + 微任务队列”来调度异步任务；
- 每轮事件循环执行顺序：
  1. 从宏任务队列取出一个任务并执行
  2. 执行过程中产生的微任务加入微任务队列
  3. 宏任务结束后，立刻执行所有微任务
  4. 微任务清空后，再进行渲染，然后进入下一轮循环
- 常见微任务：`Promise.then`、`queueMicrotask`；常见宏任务：`setTimeout`、DOM 事件回调等。

理解了这些规则，你就能更自信地分析各种“看起来很绕”的执行顺序题，也能在实际业务中合理安排异步逻辑的优先级。
