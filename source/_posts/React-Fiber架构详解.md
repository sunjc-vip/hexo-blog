---
title: React Fiber 架构详解：为什么要 Fiber？它解决了什么？
index_img: https://sunjc.vip/oss/2026/03/eee.webp
date: 2025-07-20 09:58:31
tags: React
comments: true
---

# React Fiber 架构详解：为什么要 Fiber？它解决了什么？

React Fiber 是 React 16 引入的底层重构，被很多人称为“现代 React 的地基”。你可能听过这些说法：

- Fiber 让 React 渲染“可中断、可恢复”
- Fiber 是并发渲染（Concurrent Rendering）的基础
- Fiber 带来了更细粒度的优先级调度

但如果只停留在口号层面，很难真正理解它对 React 性能与体验的意义。本文从“问题 → 方案 → 运行机制 → 工程意义”的结构，尽量用可理解的方式解释 Fiber。

---

## 一、Fiber 出现之前：Stack Reconciler 的问题

在 React 16 之前，React 使用的是“Stack Reconciler”（栈式协调器）。它的特点是：

- React 在一次更新中，会**递归**地遍历组件树进行 diff（reconciliation）
- 这个过程基本是**同步且不可中断**的

### 1. 同步不可中断带来的体验问题

当组件树很大、一次更新需要做很多计算时，JS 主线程会被长时间占用：

- 浏览器无法及时响应输入事件
- 动画掉帧、滚动卡顿
- “点了没反应”的交互延迟增加

因为在旧架构下，React 一旦开始 diff，就必须一口气跑完，无法把控制权交还给浏览器。

> 换句话说：旧架构让 React 的更新像“长任务”，阻塞 UI。

### 2. 递归调用栈的限制

旧 reconciler 大量依赖函数递归：

- 调用栈深度受限
- 很难在中途保存/恢复遍历状态

因此要做“分片执行”“优先级调度”非常困难。

---

## 二、Fiber 的核心目标

Fiber 的目标不是“让 React 更快一点点”，而是让 React 具备更强的调度能力：

1. **可中断（Interruptible）**：更新过程可以暂停，让浏览器先处理更重要的事（输入、动画、渲染）。
2. **可恢复（Resumable）**：暂停后可以从上次位置继续，而不是重来。
3. **可分优先级（Prioritized）**：不同更新有不同优先级（输入 > 动画 > 数据展示）。
4. **可复用与并发（Concurrent）**：为并发渲染、Suspense 等能力打基础。

把 Fiber 理解为：

> React 把“组件树的更新工作”拆成很多小任务，并能调度这些小任务在合适的时机执行。

---

## 三、Fiber 是什么？（数据结构视角）

Fiber 可以从两个角度理解：

1. **一种数据结构**：每个组件/元素对应一个 Fiber 节点，节点之间通过指针连接成树。
2. **一种执行单元**：每个 Fiber 节点代表一小段可被调度的工作。

### 1. Fiber 节点的“树指针”

每个 Fiber 通常会有这些指针（概念层面）：

- `child`：第一个子节点
- `sibling`：下一个兄弟节点
- `return`：父节点（命名为 return 是历史原因）

这让遍历不再依赖函数递归，而是通过“链表式指针”在树上走：

- 先走 child（深入）
- 没 child 就走 sibling（横向）
- 都没有就回到 return（回溯）

这种结构非常适合：

- 把遍历过程拆成一个个“可暂停”的步骤
- 暂停时保存当前 Fiber 指针即可

---

## 四、两阶段：Render（协调）与 Commit（提交）

Fiber 架构下，一次更新通常分成两个阶段：

### 1. Render 阶段（Reconciliation / Render phase）

做什么：

- 计算新的 Fiber 树（或更新 Fiber 树）
- 找出哪些节点需要更新
- 生成“副作用列表”（effects），描述需要对 DOM 做哪些修改

特点：

- **可中断**（可分片执行）
- 可能会重复执行（比如被打断后重试）
- 不能在这里做“有副作用且不可重复”的事情（这也是 StrictMode 更严格的原因之一）

### 2. Commit 阶段（Commit phase）

做什么：

- 把 render 阶段算出来的变更一次性提交到真实 DOM
- 执行生命周期（或对应 hooks 的 effect 触发）

特点：

- **不可中断**（必须一次性做完，保证 UI 一致）
- 这里才会真正操作 DOM

你可以把它理解为：

- Render：在脑子里“算方案”（可反复、可暂停）
- Commit：真正“动手施工”（一次性完成）

---

## 五、时间分片（Time Slicing）：让长任务变短任务

Fiber 的关键能力之一是“时间分片”：

- 把一次大更新拆成很多小工作单元（Fiber）
- 每次只做一小段时间（例如几毫秒）
- 如果时间片用完，就暂停，先让浏览器处理输入/渲染
- 下一轮再继续

这背后需要一个调度器（scheduler）：

- 负责决定当前做哪个 Fiber 工作
- 负责在合适时机让出主线程

在实现层面（概念理解即可），React 会在 render 阶段不断执行“一个 Fiber 的工作”，并在合适时机检查：

- 是否应该让出主线程（time slicing）
- 是否有更高优先级的更新插队

这也是为什么 Fiber 常和“可中断”“优先级”绑定在一起。

---

## 六、优先级：哪些更新更重要？

真实交互里，不同更新的重要程度不同：

- 用户输入、点击反馈 → 应该优先
- 大列表过滤、低优先级 UI 更新 → 可以稍后

Fiber 架构让 React 能把更新分成不同优先级，并调度执行顺序。

在 React 18+ 中，你会在 API 层感受到这种能力：

- `startTransition` / `useTransition`：把某些更新标记为“非紧急”
- `useDeferredValue`：延迟某个值的更新，避免卡住输入

它们背后的基础就是 Fiber + Scheduler 的调度模型。

---

## 七、双缓冲：current 树与 workInProgress 树

Fiber 架构里常见一个概念：**双缓冲（double buffering）**。

你可以把它理解为：

- `current`：当前屏幕上已经生效的 Fiber 树（对应已提交的 UI）
- `workInProgress`：正在 render 阶段构建/计算的新 Fiber 树（草稿）

render 阶段在 `workInProgress` 上“算方案”，commit 阶段再把结果一次性提交，让它变成新的 `current`。

这样做的好处：

- render 阶段可以被打断、重试，不会把 UI 推到“半完成”状态
- commit 阶段一次性落地，保证 UI 一致性

---

## 八、Fiber 如何完成一次更新？（流程视角）

以一次 setState/状态更新为例，简化理解流程：

1. 某个组件触发更新（state/props/context 变化）
2. React 标记更新并把它加入调度队列（带优先级）
3. 进入 render 阶段：
   - 从根 Fiber 开始，遍历并为需要更新的节点创建/复用 workInProgress Fiber
   - 计算新的 props、state，生成需要提交的变更信息
4. render 阶段完成后，进入 commit 阶段：
   - 将变更提交到真实 DOM
   - 执行 layout effects（如 `useLayoutEffect`）
   - 在之后的时机触发 passive effects（如 `useEffect`）

你在工程中能直接感受到的影响是：

- `useEffect` 不应依赖“只执行一次且不重复”的假设（StrictMode 下更严格）
- render 阶段要保持“纯”（不要做不可逆副作用）

---

## 九、为什么 Fiber 是 Suspense/并发渲染的基础？

### 1. Suspense 需要“可暂停的渲染”

Suspense 的核心体验是：

- 某块 UI 需要数据/代码（懒加载）时，可以先展示 fallback
- 等资源就绪再切回真正内容

要做到这点，React 需要在 render 阶段具备“暂停/恢复/切换树”的能力，而 Fiber 提供了：

- 以 Fiber 为单位的可中断工作
- workInProgress 草稿树的构建与回退
- 按优先级调度与重试机制

### 2. 并发渲染（Concurrent Rendering）需要“算 UI 的过程可被打断”

并发渲染的目标是：

- 在保证 UI 一致性的前提下，让更新更“可调度”
- 高优先级交互不被低优先级渲染阻塞

Fiber 让 React 可以把渲染过程拆分成小单元并让出主线程，给浏览器机会处理输入和绘制。

---

## 十、Fiber 对你写业务代码意味着什么？

理解 Fiber 并不是为了“手写 Fiber”，而是为了写出更符合 React 模型的代码。

### 1. render 阶段尽量保持纯

避免在 render（函数组件本体执行）里做这些事情：

- 发请求
- 写 localStorage
- 注册事件监听
- 改 DOM

这些应该放到 `useEffect/useLayoutEffect` 或事件回调中。

原因：

- render 阶段可能被重复执行（尤其在开发严格模式下更明显）
- 你不能假设 render “只执行一次”

### 2. 把昂贵渲染拆小、可中断≠无限快

Fiber 能“让出主线程”，但如果你的单个组件渲染本身特别重（例如一次渲染创建数千 DOM），仍然会卡。

这时要配合工程化手段：

- 列表虚拟化（react-window）
- 拆分组件、减少不必要渲染
- 使用 `useTransition` 降低非紧急更新优先级

### 3. 正确认识 StrictMode 的提示

React 18 开发模式下 StrictMode 会让一些逻辑更容易暴露问题（例如 effect 双执行、非纯渲染导致异常）。  
从 Fiber 的视角看，这些提示是在逼你写出“可重复、可恢复”的副作用逻辑。

---

## 十一、面试高频：一句话讲清 Fiber

如果你需要一句话回答：

> **Fiber 是 React 16 引入的新协调架构，它把组件树更新拆成可被调度的工作单元，使渲染可中断、可恢复、可分优先级，从而支撑并发渲染与更好的交互体验。**

再补一句“工程意义”：

> render 阶段可重复、可打断，所以渲染逻辑要保持纯；副作用交给 effect，并保证可清理与幂等。

---

## 十二、总结

Fiber 解决的核心问题是：**如何在复杂 UI 更新中，让 React 的渲染过程具备调度能力**。

- 旧架构（Stack Reconciler）同步、不可中断，容易阻塞主线程导致卡顿
- Fiber 用“节点数据结构 + 可调度工作单元”替代递归调用栈
- 引入 render/commit 两阶段与双缓冲，使得渲染可暂停、可恢复且 UI 一致
- 为 React 18/19 的并发能力、Suspense、Transitions 等特性提供底层支撑

理解 Fiber 后，你会更容易理解 React 18+ 的并发相关 API（`useTransition`、`Suspense` 等）为什么能改善交互体验，以及为什么 React 强调“纯渲染 + 可清理副作用”。

