---
title: React 组件通信
index_img: https://sunjc.vip/oss/2026/03/eee.webp
date: 2025-07-12 18:03:27
tags: React
comments: true
---

# React 组件通信

React 的核心思想是“**单向数据流**”：数据从父组件流向子组件，UI 是 state 的函数。正因为是单向流，组件之间的“通信方式”就显得格外重要：父子怎么传值？子组件怎么通知父组件？兄弟组件如何共享状态？跨层级通信怎么做？全局状态又该如何管理？

本文按“从简单到复杂”的顺序，系统总结 React 常见的组件通信方式，并给出适用场景与选型建议。

---

## 一、通信方式总览（先给结论）

常见的 React 组件通信可以归纳为：

1. **父 → 子**：Props
2. **子 → 父**：回调函数（props callback）
3. **兄弟组件**：提升状态到共同父组件（Lifting State Up）
4. **跨层级（多层传递）**：Context
5. **组件实例方法暴露**：ref + `forwardRef` + `useImperativeHandle`
6. **全局/跨页面状态**：状态管理（Redux / Zustand / Jotai / Recoil 等）
7. **路由级共享状态**：URL 参数、search、route state
8. **持久化共享**：localStorage / sessionStorage（配合状态同步）
9. **事件系统（不推荐或谨慎）**：EventBus、自定义事件（通常不是 React 首选）

一个常用的选择原则：

> **能用 Props/提升状态解决的就不要上 Context；能用 Context 解决的就不要急着上 Redux。**

---

## 二、父 → 子：Props（最基础、最推荐）

### 1. 传递数据

```jsx
function Child({ title }) {
  return <h3>{title}</h3>;
}

export default function Parent() {
  return <Child title="Hello React" />;
}
```

### 2. 传递函数、组件、配置等

Props 不仅能传值，也能传函数、组件、渲染函数：

```jsx
function List({ items, renderItem }) {
  return <ul>{items.map((x) => <li key={x.id}>{renderItem(x)}</li>)}</ul>;
}

export default function Page() {
  const items = [{ id: 1, name: "A" }, { id: 2, name: "B" }];
  return <List items={items} renderItem={(x) => x.name} />;
}
```

这种“render props”模式在组件库与高复用组件中非常常见。

---

## 三、子 → 父：回调函数（最常用）

子组件想“把信息传回父组件”，本质就是：**父组件把一个函数传给子组件，子组件在合适时机调用它**。

```jsx
function Child({ onChange }) {
  return (
    <button onClick={() => onChange("child data")}>
      点我把数据传回父组件
    </button>
  );
}

export default function Parent() {
  const handleChange = (payload) => {
    console.log("收到子组件消息：", payload);
  };

  return <Child onChange={handleChange} />;
}
```

这符合 React 单向数据流：

- 数据仍然是“父控制子”
- 子只是触发事件，父决定如何更新 state

---

## 四、兄弟组件通信：提升状态到共同父组件（Lifting State Up）

兄弟组件之间不直接通信，而是把共享状态放到它们共同的父组件里。

```jsx
function Left({ value, onChange }) {
  return <input value={value} onChange={(e) => onChange(e.target.value)} />;
}

function Right({ value }) {
  return <p>右侧展示：{value}</p>;
}

export default function Parent() {
  const [value, setValue] = React.useState("");

  return (
    <div>
      <Left value={value} onChange={setValue} />
      <Right value={value} />
    </div>
  );
}
```

这是 React 官方最推荐的“组件间共享数据”的方式之一：简单、清晰、可追踪。

---

## 五、跨层级通信：Context（避免 props drilling）

当你需要把某个值传给很深层的组件，如果层层透传 props，会变得冗长，这就是“props drilling”。

### 1. 创建 Context

```jsx
import React from "react";

const ThemeContext = React.createContext({ mode: "light" });
```

### 2. 提供 Provider

```jsx
function App() {
  const [mode, setMode] = React.useState("light");

  return (
    <ThemeContext.Provider value={{ mode, setMode }}>
      <Page />
    </ThemeContext.Provider>
  );
}
```

### 3. 深层消费（useContext）

```jsx
function Button() {
  const { mode, setMode } = React.useContext(ThemeContext);
  return (
    <button onClick={() => setMode(mode === "light" ? "dark" : "light")}>
      当前主题：{mode}
    </button>
  );
}
```

### 4. Context 的适用场景

适合：

- 主题（theme）、语言（i18n）
- 用户信息（user）、权限（auth）
- 组件库配置（如表单/弹窗上下文）
- “全局但变化频率不高”的状态

不建议滥用：

- 频繁变化的高频状态（可能导致大量组件重新渲染）
- 大量业务状态都塞进一个 context（难维护、难优化）

优化建议：

- **拆分多个 Context**（按关注点拆）
- 值对象用 `useMemo` 包装，避免无意义刷新

---

## 六、ref 通信：暴露子组件方法（命令式场景）

React 推崇声明式，但某些场景仍然需要“命令式控制”，比如：

- 打开/关闭弹窗
- 让输入框聚焦
- 调用子组件内部方法（如表单校验、滚动到某位置）

### 1. forwardRef + useImperativeHandle

```jsx
import React, { useImperativeHandle, useRef, forwardRef } from "react";

const Child = forwardRef(function Child(_, ref) {
  const inputRef = useRef(null);

  useImperativeHandle(ref, () => ({
    focus() {
      inputRef.current?.focus();
    },
    clear() {
      if (inputRef.current) inputRef.current.value = "";
    },
  }));

  return <input ref={inputRef} placeholder="子组件输入框" />;
});

export default function Parent() {
  const childRef = React.useRef(null);

  return (
    <div>
      <Child ref={childRef} />
      <button onClick={() => childRef.current?.focus()}>聚焦</button>
      <button onClick={() => childRef.current?.clear()}>清空</button>
    </div>
  );
}
```

注意：

- ref 通信适合“命令式控制”，不要用它代替状态管理
- 暴露的 API 尽量少且稳定，避免形成难维护的耦合

---

## 七、全局状态通信：Redux / Zustand 等

当应用变复杂后，“提升状态”会导致：

- 顶层组件 state 非常臃肿
- props drilling 严重
- 跨页面共享状态困难

这时可以使用状态管理库，把共享状态放到“外部 store”中，组件按需订阅。

### 1. 什么时候需要状态管理？

典型信号：

- 同一份状态被多个页面/模块使用
- 状态需要持久化（如登录态、用户偏好）
- 需要时间旅行、可追踪的状态变更（Redux DevTools）
- 复杂的异步流与业务规则

### 2. Zustand（轻量示例）

```js
import { create } from "zustand";

export const useUserStore = create((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
}));
```

组件中直接用：

```jsx
function Header() {
  const user = useUserStore((s) => s.user);
  const logout = useUserStore((s) => s.logout);
  return (
    <div>
      {user ? <span>{user.name}</span> : <span>未登录</span>}
      <button onClick={logout}>退出</button>
    </div>
  );
}
```

核心优点：

- 组件只订阅自己需要的 slice，减少不必要渲染
- API 简洁，适合中小型项目快速落地

---

## 八、路由级通信：URL 参数与路由状态

跨页面通信时，路由往往是天然的“通信载体”。

### 1. URL Params / Query

适合：

- 可分享、可复制链接的状态（筛选条件、分页、tab）
- SEO/可回溯需求

示例（概念）：

- `/list?page=2&keyword=react`

优点：

- 刷新不丢
- 可分享/可回溯

缺点：

- 不适合放敏感信息
- 对复杂结构需要序列化/反序列化

### 2. 路由 state（不在 URL 上）

适合：

- “只在跳转时带过去一次”的临时数据

缺点：

- 刷新会丢（通常）

---

## 九、持久化通信：localStorage/sessionStorage（谨慎）

常见用法：

- 保存主题、语言、token（注意安全）
- 保存用户偏好（列表排序方式、折叠状态）

建议：

- localStorage 适合“用户偏好”，不适合放敏感信息（XSS 风险）
- 持久化应当与 store 联动：初始化时读取，变化时写回

---

## 十、EventBus / 自定义事件：为什么不推荐？

在 React 中，很多人会用 EventBus 解决跨组件通信，但它往往带来：

- 事件名散落、难追踪
- 订阅/取消订阅容易漏，造成内存泄漏
- 数据流不可预测，不利于调试

如果确实需要事件系统，建议：

- 封装成清晰模块（集中定义事件名）
- 必须在组件卸载时取消订阅
- 优先考虑用 store 或 context 解决“共享状态”，把 EventBus 只用于“瞬时事件”（如全局 toast 通知）

---

## 十一、选型总结（最实用的经验）

1. **父子/兄弟**：优先 Props + 回调 + 提升状态（最稳定）
2. **跨层级**：Context（但注意拆分与性能）
3. **命令式控制**：ref + `useImperativeHandle`
4. **跨模块/跨页面共享**：Zustand/Redux 等 store
5. **可分享/可回溯状态**：URL 参数
6. **尽量少用 EventBus**：除非你明确知道在做什么

---

## 十二、总结

React 组件通信的关键不在于“会几种写法”，而在于把握单向数据流的设计哲学：

- **状态尽量靠近使用它的组件**
- **共享状态提升或抽离到合适层级（父组件 / Context / Store）**
- **副作用与命令式行为尽量隔离（ref、effect、事件系统）**

只要你能根据业务复杂度与可维护性做出正确选型，组件通信就会变成一件非常自然的事。

