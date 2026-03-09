---
title: React 常用 Hooks 完全指南（useState/useEffect/useMemo…）
index_img: https://sunjc.vip/oss/2026/03/eee.webp
date: 2026-02-08 21:26:05
tags: React
comments: true
---

# React 常用 Hooks 完全指南（useState/useEffect/useMemo…）

Hooks 是 React 16.8 引入的函数组件能力扩展，使我们可以在函数组件中使用 state、生命周期、副作用、上下文等特性。从工程实践角度看，Hooks 既提升了代码复用与组织能力，也带来了“依赖数组”“闭包陷阱”“过度 memo”等新问题。

本文用“**最常用 Hooks + 最佳实践 + 常见坑**”的方式，帮助你在业务中更稳、更少踩坑地使用 Hooks。

---

## 一、Hook 使用规则（必须遵守）

React 官方有两条硬规则：

1. **只在函数组件或自定义 Hook 中调用 Hook**
2. **只在顶层调用 Hook**（不要在 if/for/try 内调用）

原因是：Hooks 依赖“调用顺序”来匹配内部状态，如果条件调用会导致顺序错乱。

---

## 二、useState：组件内部状态

### 1. 基本用法

```jsx
import { useState } from "react";

export default function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      count: {count}
    </button>
  );
}
```

### 2. 函数式更新（避免拿到旧值）

当你基于旧值更新时，建议用函数式写法：

```jsx
setCount((c) => c + 1);
```

这能避免：

- 连续多次更新被批处理时拿到旧值
- 闭包捕获旧 state 的问题

### 3. 初始值计算：惰性初始化

如果初始值计算很重，可以传函数：

```jsx
const [value, setValue] = useState(() => heavyInit());
```

---

## 三、useEffect：副作用（请求、订阅、DOM 操作等）

### 1. 基本用法

```jsx
import { useEffect, useState } from "react";

export default function User({ userId }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    let cancelled = false;

    async function run() {
      const res = await fetch(`/api/user/${userId}`);
      const data = await res.json();
      if (!cancelled) setUser(data);
    }

    run();

    return () => {
      cancelled = true;
    };
  }, [userId]);

  return <pre>{JSON.stringify(user, null, 2)}</pre>;
}
```

要点：

- `useEffect` 在渲染提交到 DOM 后执行
- 依赖数组决定何时重新执行
- 返回函数用于清理（取消订阅、清理定时器、abort 请求等）

### 2. 依赖数组怎么写？

经验规则：

- effect 中用到的**来自组件作用域的变量**，都应该出现在依赖数组里
- 依赖缺失会导致“用到旧值”的 bug
- 不要为了“让 effect 少跑”而乱删依赖，应该通过重构解决

### 3. React 18 StrictMode 的“双执行”现象（开发环境）

在 React 18 开发环境下，StrictMode 会让某些 effect 执行两次，用于暴露不安全副作用。  
对策：

- 保证 effect 是可重复执行且可正确清理的
- 请求用 AbortController 或 cancelled 标记防止竞态

---

## 四、useRef：保存可变引用/访问 DOM

### 1. 访问 DOM

```jsx
import { useRef } from "react";

export default function FocusInput() {
  const inputRef = useRef(null);

  return (
    <div>
      <input ref={inputRef} />
      <button onClick={() => inputRef.current?.focus()}>
        聚焦
      </button>
    </div>
  );
}
```

### 2. 保存“不触发渲染”的可变值

```jsx
const latestValueRef = useRef(value);
latestValueRef.current = value;
```

适用场景：

- 保存定时器 id
- 保存上一次值
- 保存某个外部库实例

> `useRef` 的 `.current` 变化不会触发组件重新渲染。

---

## 五、useMemo：缓存计算结果（不是为了“更快”而必用）

### 1. 基本用法

```jsx
import { useMemo } from "react";

const filtered = useMemo(() => {
  return list.filter((x) => x.active);
}, [list]);
```

### 2. 何时需要 useMemo？

只有在以下情况才考虑：

- 计算很重（大列表过滤/排序/复杂计算）
- 计算结果会作为 props 传递给 memo 子组件，且引用稳定能减少子组件渲染

### 3. 常见误区：到处 useMemo

`useMemo` 本身也有成本（比较依赖、维护缓存），对轻量计算可能得不偿失。  
原则：

> **先保证正确性，再用性能数据决定是否 memo。**

---

## 六、useCallback：缓存函数引用

`useCallback(fn, deps)` 等价于 `useMemo(() => fn, deps)`。

### 1. 典型场景：配合 React.memo

```jsx
import React, { useCallback, useState } from "react";

const Child = React.memo(function Child({ onClick }) {
  return <button onClick={onClick}>child</button>;
});

export default function Parent() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    console.log("clicked");
  }, []);

  return (
    <div>
      <Child onClick={handleClick} />
      <button onClick={() => setCount((c) => c + 1)}>+1</button>
    </div>
  );
}
```

如果不 `useCallback`，Parent 每次 re-render 都会创建新函数，导致 memo 子组件也跟着渲染。

### 2. 常见坑：依赖数组写错导致“拿到旧值”

```jsx
const handle = useCallback(() => {
  console.log(count);
}, []); // 错：count 没进 deps，会永远打印初始值
```

修正：

```jsx
const handle = useCallback(() => {
  console.log(count);
}, [count]);
```

或使用函数式更新/refs 规避依赖。

---

## 七、useContext：跨层级共享状态

### 1. 基本用法

```jsx
import React, { createContext, useContext } from "react";

const ThemeContext = createContext("light");

function Button() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>theme: {theme}</button>;
}

export default function App() {
  return (
    <ThemeContext.Provider value="dark">
      <Button />
    </ThemeContext.Provider>
  );
}
```

### 2. 注意：Context 更新会触发所有消费者更新

如果 context value 是对象，建议用 `useMemo` 保持引用稳定：

```jsx
const value = useMemo(() => ({ theme, setTheme }), [theme]);
```

并根据关注点拆分多个 context，避免“大 context”导致大面积渲染。

---

## 八、useReducer：复杂状态管理（组件内 Redux）

当状态逻辑复杂、更新路径多时，`useReducer` 会比多个 `useState` 更清晰。

```jsx
import { useReducer } from "react";

function reducer(state, action) {
  switch (action.type) {
    case "inc":
      return { ...state, count: state.count + 1 };
    case "dec":
      return { ...state, count: state.count - 1 };
    default:
      return state;
  }
}

export default function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0 });

  return (
    <div>
      <button onClick={() => dispatch({ type: "dec" })}>-</button>
      <span>{state.count}</span>
      <button onClick={() => dispatch({ type: "inc" })}>+</button>
    </div>
  );
}
```

适用场景：

- 表单状态复杂
- 一个动作影响多个字段
- 希望把更新逻辑集中到 reducer 中管理

---

## 九、useLayoutEffect：在浏览器绘制前同步执行（慎用）

`useLayoutEffect` 与 `useEffect` 的区别：

- `useEffect`：在浏览器绘制后执行（不阻塞渲染）
- `useLayoutEffect`：在 DOM 更新后、绘制前同步执行（会阻塞绘制）

适用场景：

- 需要读取 DOM 布局并同步写回（避免闪烁），例如测量元素尺寸后立即设置位置

慎用原因：

- 容易造成卡顿与掉帧
- SSR 环境会有警告（需要在客户端执行或做兼容处理）

---

## 十、useId：生成稳定的唯一 id（表单/无障碍）

```jsx
import { useId } from "react";

export default function Field() {
  const id = useId();
  return (
    <div>
      <label htmlFor={id}>用户名</label>
      <input id={id} />
    </div>
  );
}
```

相比 `Math.random()`，`useId` 更适合 SSR/同构与可访问性场景。

---

## 十一、useTransition / useDeferredValue：并发相关（提升交互体验）

### 1. useTransition：把“非紧急更新”降优先级

```jsx
import { useState, useTransition } from "react";

export default function Search() {
  const [keyword, setKeyword] = useState("");
  const [isPending, startTransition] = useTransition();

  const onChange = (e) => {
    const v = e.target.value;
    setKeyword(v); // 紧急：输入框要立刻响应
    startTransition(() => {
      // 非紧急：大列表过滤/渲染可以稍后
      // setFiltered(...)
    });
  };

  return (
    <div>
      <input value={keyword} onChange={onChange} />
      {isPending && <span>更新中...</span>}
    </div>
  );
}
```

### 2. useDeferredValue：延迟某个值的更新

适合：

- 输入框实时更新，但列表展示可以稍微延迟，减少卡顿

---

## 十二、如何写一个自定义 Hook（抽复用逻辑）

自定义 Hook 的本质：

> 把可复用的状态与副作用逻辑封装成函数，以 `useXxx` 命名，内部组合 React 提供的 hooks。

示例：监听窗口大小

```jsx
import { useEffect, useState } from "react";

export function useWindowWidth() {
  const [width, setWidth] = useState(() => window.innerWidth);

  useEffect(() => {
    const onResize = () => setWidth(window.innerWidth);
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  return width;
}
```

---

## 十三、常见坑总结（非常重要）

1. **依赖数组写错**：导致拿到旧值、重复订阅、内存泄漏
2. **useEffect 里忘记清理**：事件/定时器/订阅长期存在
3. **过度 useMemo/useCallback**：增加复杂度却没带来收益
4. **在 render 中创建不稳定对象/数组**：导致子组件重复渲染
5. **StrictMode 下副作用双执行**：需要保证 effect 幂等与可清理

---

## 十四、总结：怎么选用 Hooks？

- 管状态：`useState` / `useReducer`
- 副作用：`useEffect`（极少数用 `useLayoutEffect`）
- 共享状态：`useContext`（配合拆分与 memo）
- 性能与引用稳定：按需用 `useMemo` / `useCallback`
- DOM/可变引用：`useRef`
- 并发体验：`useTransition` / `useDeferredValue`
- 抽复用逻辑：自定义 Hook

掌握这些常用 Hooks，并理解它们的“边界与代价”，你在写 React 业务时会更像在搭积木：清晰、可复用、且更不容易踩坑。

