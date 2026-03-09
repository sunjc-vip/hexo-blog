---
title: 为什么 React 不直接用原生 requestIdleCallback 实现调度？
index_img: https://sunjc.vip/oss/2026/03/eee.webp
date: 2025-07-23 09:36:12
tags: React
comments: true
---

# 为什么 React 不直接用原生 requestIdleCallback 实现调度？

谈到 React 的并发渲染和调度（scheduler），很多人都会问一个问题：

> 既然浏览器已经有了 `requestIdleCallback`，为什么 React 不直接用它来做“空闲时间执行渲染”，还要自己搞一套 Scheduler？

这个问题背后的关键，其实是 **requestIdleCallback 的局限性** 与 **React 对调度的更高要求**。  
本文从这两个角度出发，解释为什么 React 没有简单地把 `requestIdleCallback` 当作调度基础，而是实现了自己的调度器。

---

## 一、先复习一下 requestIdleCallback 是什么

`requestIdleCallback` 的设计初衷是：

> 让开发者在浏览器“空闲时间”运行一些不那么紧急的任务，不阻塞关键渲染、输入等。

基本用法：

```js
requestIdleCallback((deadline) => {
  while (deadline.timeRemaining() > 0 && tasks.length > 0) {
    doWork(tasks.pop());
  }
});
```

回调参数 `deadline` 提供：

- `timeRemaining()`：当前帧剩余的“空闲时间”（毫秒）
- `didTimeout`：任务是否已经超时

听起来和 React 想做的“时间分片渲染”很像：  
在空闲时间做一部分渲染工作，时间不够就暂停，等下一次空闲再继续。

那为什么 React 仍然选择了自己实现调度器，而不是直接基于 `requestIdleCallback` 呢？

---

## 二、requestIdleCallback 的几个关键局限

### 1. 浏览器实现与调度策略不一致（不可控）

`requestIdleCallback` 是一个**浏览器提供的“黑盒调度”API**：

- 不同浏览器的实现和调度策略可能不同
- 浏览器可以随时认为“现在不空闲”，从而延后回调
- 在某些环境（低性能设备/繁忙页面）中，可能长时间不调用，甚至饿死任务

对业务小脚本来说，这还好；但对 React 这种**框架级调度**来说，这意味着：

- 无法稳定保证任务在期望的时间内执行
- 无法精确控制“优先级队列”和任务插队

React 希望的是：

> 由自己完全掌控“调度策略”，而不是受制于不同浏览器的 rIC 实现细节。

### 2. 兼容性与历史包袱

`requestIdleCallback` 并不是所有环境都支持（尤其是移动端早期、某些嵌入式环境、老版浏览器等），而 React 需要：

- 在各种浏览器、React Native、SSR 等环境中也能稳定工作

如果过度依赖 rIC：

- 需要复杂的 polyfill/降级逻辑
- 不同环境行为不一致，调试和预测成本增大

React 自己实现调度器，可以：

- 用一套行为一致的 Scheduler 作为基础
- 在支持 rIC 的环境中“选择性利用”，而不依赖它的完整语义

### 3. 不能表达 React 所需要的“优先级模型”

React 的更新并不只是“有空就干活”，而是有不同优先级：

- 用户输入/点击 → 高优先级
- 动画相关更新 → 次高优先级
- 数据加载后刷新 UI → 普通优先级
- 非关键 UI 更新/预加载 → 低优先级

`requestIdleCallback` 只有一个“有空/没空”的概念，不能直接表达：

- 多级优先级
- 任务插队（preemption）
- 不同优先级任务的超时策略

React 的 Scheduler 需要：

- 管理一系列按优先级排序的任务
- 随时可以插入一个更高优先级的更新
- 根据任务过期时间/优先级动态调整执行

这些都超出了 rIC 的原生能力。

### 4. 与帧同步（requestAnimationFrame）的协作问题

React 需要与浏览器的绘制节奏（`requestAnimationFrame`）良好协作：

- 在下次绘制前完成高优先级任务
- 不要在每一帧的末尾塞太多“空闲任务”，影响下一帧

但 `requestIdleCallback` 的调用时机由浏览器决定，React 很难基于它构建一个**既与帧率协同又完全可控的调度循环**。

React 的 Scheduler 更常见的做法是：

- 自己基于 `MessageChannel` / `setTimeout` / `rAF` 组合出一套“可预测的时间片调度”
- 在其中**选择性**利用 rIC 提供的“补充空闲时间”，而不是完全托付给它

---

## 三、React 想要的是“可控 Scheduler”，而不是一个“黑盒 idle”

React Scheduler（调度器）的设计目标可以概括为：

1. **跨环境一致**：浏览器、原生（React Native）、SSR 中都能工作
2. **可预测的优先级**：高优任务优先执行，低优任务不会饿死
3. **可插队**：在执行低优先级任务时可以被高优任务打断
4. **可与帧率协作**：避免卡顿，保持动画/交互流畅

这些目标要求 React 控制：

- 任务队列结构（最小堆/优先级队列）
- 任务执行节奏（time slicing）
- 插队与过期策略（expirationTime/lanes 等概念）

如果完全使用 `requestIdleCallback` 来驱动：

- 任务何时执行、能执行多久都由浏览器决定
- React 很难在其上做复杂的“优先级 + 插队”策略
- 不同浏览器行为差异会放大调试与体验不一致的问题

因此 React 选择了：

> **自己实现一套可控的 Scheduler，把 rIC 视为“底层工具之一”，而不是唯一调度基础。**

---

## 四、React Scheduler 大致是怎么做的？（概念层面）

不深入源码细节，从概念上讲：

1. React 维护一个 **优先级任务队列**（按过期时间/优先级排序）
2. 调度循环会：
   - 取出最高优先级任务
   - 在一个“时间片”（如几毫秒）内执行一部分 Fiber 工作
   - 检查时间是否用完、是否有更高优先级任务插入
3. 如果时间片用完或被打断：
   - 暂停当前任务，下次再继续
4. 在支持 rIC 的浏览器中：
   - 可能利用 rIC 作为“空闲补充点”，进一步利用碎片时间
5. 同时与 `requestAnimationFrame` 或其他机制配合：
   - 在浏览器下一帧绘制前避免长时间占用主线程

这套机制比单纯的 `requestIdleCallback` 要精细得多，也更符合 React “并发渲染 + 优先级调度”的需要。

---

## 五、从开发者视角看：为什么这些细节对你很重要？

你可能会问：这些底层调度细节，作为业务开发者知道有用吗？

实际上，它会影响你对 React 18+ 行为的理解，尤其是：

1. **render 阶段可能多次执行/被打断**  
   - 不要在 render 函数里做“不可逆副作用”（发请求、写日志、操作 DOM）
   - 这些应该放到 effect 中，并保证可清理、可重复

2. **高优与低优更新会被区分**  
   - 用 `useTransition` / `useDeferredValue` 给非关键更新“降级”，提升交互体验

3. **不要直接依赖“某次 render 必定执行完整任务”的假设**  
   - React 可能在某个阶段暂停后重新开始

理解到这里，你就能理解：

- 为什么 React 要“自带 Scheduler”，而不是依赖 `requestIdleCallback`
- 为什么 React 强调“渲染纯函数 + 可清理副作用”的约束

---

## 六、总结

如果在面试中被问到“为什么 React 不直接用 `requestIdleCallback` 实现调度？”，可以这样回答：

> `requestIdleCallback` 的实现不可控、兼容性有限，只提供了一个“空闲回调”，难以表达 React 所需的多级优先级、任务插队与跨环境一致性。React 需要一套自己的 Scheduler 来精细控制任务队列和时间分片，在此基础上再选择性利用 rIC 等底层能力，而不是完全依赖它。

再加一句工程意义：

> 对我们写业务代码来说，这意味着要遵守“render 阶段无副作用、effect 可清理”的模型，并合理使用并发相关 API，而不要假设“React 渲染永远是同步一次完成”的旧时代行为。

