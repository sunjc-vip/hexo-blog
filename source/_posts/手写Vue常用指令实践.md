---
title: 手写 Vue 常用指令实践（v-model / v-show / v-focus…）
index_img: https://sunjc.vip/oss/2026/03/ccc.webp
date: 2025-07-22 10:21:54
tags: Vue
comments: true
---

# 手写 Vue 常用指令实践（v-model / v-show / v-focus…）

Vue 的指令（Directive）是操作 DOM 的重要能力。除了内置的 `v-model`、`v-show`、`v-if`、`v-on` 等，我们也可以通过**自定义指令**把一些通用 DOM 行为（聚焦、权限控制、懒加载等）封装成“模板语法糖”。

这篇文章不去重新实现 Vue 核心指令的全部细节，而是通过**手写简化版常用指令**，帮你理解：

- 指令的生命周期与钩子（`beforeMount/mounted/updated/unmounted`）
- 如何操作 DOM、绑定/解绑事件
- 如何配合响应式和组件一起使用

本文以 Vue 3 为主（Vue 2 也类似，只是钩子名字略有不同）。

---

## 一、快速回顾：Vue 3 自定义指令基本形态

在 Vue 3 中，一个指令对象通常长这样：

```js
const myDirective = {
  // 元素第一次绑定到 DOM 上时调用（还没插入文档）
  beforeMount(el, binding, vnode, prevVnode) {},
  // 元素插入文档后调用
  mounted(el, binding, vnode, prevVnode) {},
  // 绑定的值变化时调用（组件更新后）
  updated(el, binding, vnode, prevVnode) {},
  // 卸载前
  beforeUnmount(el, binding, vnode, prevVnode) {},
  // 已卸载
  unmounted(el, binding, vnode, prevVnode) {},
};
```

全局注册：

```js
const app = createApp(App);
app.directive("my", myDirective);
```

局部注册（在组件里）：

```js
export default {
  directives: {
    my: myDirective,
  },
};
```

使用：

```vue
<template>
  <div v-my="someValue"></div>
</template>
```

接下来我们通过几个“手写指令”的例子来理解指令机制。

---

## 二、手写一个 v-focus：自动聚焦输入框

目标：

```vue
<input v-focus />
```

在元素挂载后自动 `focus()`。

实现：

```js
// focus.js
export const vFocus = {
  mounted(el) {
    el.focus();
  },
};
```

使用：

```js
import { createApp } from "vue";
import App from "./App.vue";
import { vFocus } from "./directives/focus";

const app = createApp(App);
app.directive("focus", vFocus);
app.mount("#app");
```

```vue
<template>
  <input v-focus placeholder="页面加载后自动聚焦" />
</template>
```

> 小结：`v-focus` 这种只需要在初始化时执行的行为，主要用 `mounted` 钩子即可。

---

## 三、手写一个 v-show：控制元素显示/隐藏

Vue 内置 `v-show` 本质上是控制元素的 `display`，我们可以写个简化版：

目标：

```vue
<div v-show-like="visible">内容</div>
```

实现：

```js
// show.js
export const vShowLike = {
  mounted(el, binding) {
    updateDisplay(el, binding.value);
  },
  updated(el, binding) {
    updateDisplay(el, binding.value);
  },
};

function updateDisplay(el, value) {
  el.style.display = value ? "" : "none";
}
```

注册：

```js
app.directive("show-like", vShowLike);
```

使用：

```vue
<script setup>
import { ref } from "vue";
const visible = ref(true);
</script>

<template>
  <button @click="visible = !visible">
    切换显示
  </button>
  <div v-show-like="visible">我会被显示/隐藏</div>
</template>
```

> 小结：这种“值变化就改样式”的指令，通常在 `mounted` + `updated` 中保持行为一致即可。

---

## 四、手写一个简易 v-model：双向绑定 input

真正的 `v-model` 是编译阶段语法糖，内部涉及 `modelValue` / `onUpdate:modelValue` 等，这里我们写一个简单版指令来实现最基础的“值与输入框同步”。

目标：

```vue
<input v-model-like="title" />
```

实现思路：

- 指令的 **值** 是一个“可写的 ref”或者“来自组件里的变量”
- 指令内部需要：
  - 初始化时把 `binding.value` 写到 `el.value`
  - 监听 `input` 事件，把 `el.value` 回写给绑定的变量

但是：指令自己拿不到“修改外部 ref 的 setter”，因此完全仿 `v-model` 需要结合 `get`/`set` 或者使用对象形式传入。这里给一个比较常见、工程中实用的变种：**统一封装 input 的 DOM 同步，但具体赋值仍在组件内处理。**

更现实/简单的方式是：**用指令帮你处理 DOM 事件 + 防抖 + 去除空格** 等，而不是完全实现 `v-model` 本身。  
比如：

```vue
<input v-model.trim="title" />
```

可以实现成一个 `v-trim-input` 指令，帮助自动 `trim`。

示例：`v-trim-input` 自动清除首尾空格并与 `v-model` 配合：

```js
// trim-input.js
export const vTrimInput = {
  mounted(el) {
    const handler = () => {
      const value = el.value;
      const trimmed = value.trim();
      if (value !== trimmed) {
        el.value = trimmed;
        // 触发一次 input 事件，让 v-model 感知变更
        const event = new Event("input", { bubbles: true });
        el.dispatchEvent(event);
      }
    };

    el.__trim_handler__ = handler;
    el.addEventListener("blur", handler);
  },
  unmounted(el) {
    el.removeEventListener("blur", el.__trim_handler__);
    delete el.__trim_handler__;
  },
};
```

使用：

```vue
<script setup>
import { ref } from "vue";
const title = ref("");
</script>

<template>
  <input v-model="title" v-trim-input placeholder="失焦时去除首尾空格" />
  <p>值：{{ JSON.stringify(title) }}</p>
</template>
```

> 小结：完全“手写 v-model”更多是编译器层面的事情；在业务中，更常见的是写一些 **辅助指令** 去增强 `v-model` 的行为（如 trim、防抖、格式化）。

---

## 五、手写一个 v-debounce：输入防抖

在搜索框中，你可能希望用户停止输入一段时间后再触发搜索请求，这时可以写一个 `v-debounce` 指令。

目标：

```vue
<input v-model="keyword" v-debounce:input="onSearch" />
```

- `v-debounce:input`：监听 input 事件，并对回调 `onSearch` 做防抖

实现：

```js
// debounce.js
function debounce(fn, delay = 300) {
  let timer = null;
  return function (...args) {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}

export const vDebounce = {
  mounted(el, binding) {
    const eventName = binding.arg || "input";
    const delay = binding.modifiers.fast ? 200 : 500;
    const handler = binding.value;

    if (typeof handler !== "function") {
      console.warn("v-debounce 需要一个函数作为值");
      return;
    }

    const debounced = debounce((event) => {
      handler(event);
    }, delay);

    el.__debounce_handler__ = debounced;
    el.addEventListener(eventName, debounced);
  },
  updated(el, binding) {
    // 如果传入的回调函数变了，可以根据需要更新
  },
  unmounted(el, binding) {
    const eventName = binding.arg || "input";
    if (el.__debounce_handler__) {
      el.removeEventListener(eventName, el.__debounce_handler__);
      delete el.__debounce_handler__;
    }
  },
};
```

使用：

```vue
<script setup>
import { ref } from "vue";

const keyword = ref("");

const onSearch = (e) => {
  console.log("搜索：", e.target.value);
};
</script>

<template>
  <input v-model="keyword" v-debounce:input.fast="onSearch" placeholder="输入搜索，防抖触发" />
</template>
```

> 小结：指令非常适合封装这类“DOM 事件 + 通用逻辑”（防抖、节流、格式化、限制输入等）。

---

## 六、手写一个 v-permission：按钮权限控制

很多后台系统需要根据权限隐藏/禁用按钮，这类逻辑用指令封装非常合适。

目标：

```vue
<button v-permission="'user:create'">新建用户</button>
```

实现（简化版）：

```js
// permission.js
import { useUserStore } from "@/stores/user"; // 假设你有一个权限 store

export const vPermission = {
  mounted(el, binding) {
    const required = binding.value;
    const store = useUserStore();
    const has = store.permissions.includes(required);

    if (!has) {
      // 1. 直接移除元素
      el.parentNode && el.parentNode.removeChild(el);
      // 或者 2. 禁用 + 添加样式
      // el.disabled = true;
      // el.classList.add("is-disabled");
    }
  },
};
```

注意：

- 指令内部直接访问 store，有耦合性，但对于权限这种系统级概念是可接受的
- 若希望更解耦，可以在全局 `app.config.globalProperties` 中挂一个 `hasPermission` 函数

> 小结：权限、埋点标记、拖拽、粘贴处理等行为类逻辑非常适合用指令抽象。

---

## 七、手写一个 v-lazy：图片懒加载

目标：

```vue
<img v-lazy="imgUrl" />
```

未出现在视口时不加载图片，进入视口再设置 `src`。

实现（使用 IntersectionObserver）：

```js
// lazy.js
const io =
  typeof IntersectionObserver !== "undefined"
    ? new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target;
            const src = el.getAttribute("data-src");
            if (src) {
              el.src = src;
              io.unobserve(el);
            }
          }
        });
      })
    : null;

export const vLazy = {
  mounted(el, binding) {
    const src = binding.value;
    el.setAttribute("data-src", src);

    if (io) {
      io.observe(el);
    } else {
      // 不支持 IntersectionObserver，降级为直接加载
      el.src = src;
    }
  },
  unmounted(el) {
    if (io) {
      io.unobserve(el);
    }
  },
};
```

使用：

```vue
<img v-lazy="imgUrl" alt="懒加载图片" />
```

---

## 八、指令 vs 组件 vs 组合式 API：何时用哪一个？

简单经验：

- **指令**：更适合封装“纯 DOM 行为”，例如：
  - 聚焦、拖拽、滚动、粘贴处理
  - 权限控制、懒加载、点击外部关闭（`v-click-outside`）
  - 防抖/节流类输入行为增强

- **组件**：更适合封装“有 UI 结构的东西”，例如：
  - 弹窗、抽屉、表单项、按钮组
  - 需要模板/slot 的结构化内容

- **组合式 API（composables）**：更适合封装“业务逻辑 + 状态”，例如：
  - useUser / useRequest / useTheme / useChart

可以这样理解：

> - 行为 + DOM：优先指令  
> - UI + 交互：优先组件  
> - 状态 + 业务逻辑：优先组合式 API

---

## 九、总结

通过手写这几个常见指令，我们可以看到：

- Vue 指令本质是围绕 DOM 的生命周期钩子（`mounted/updated/unmounted`）封装逻辑
- 指令非常适合处理“事件增强 + DOM 操作”的通用场景（聚焦、防抖、懒加载、权限等）
- 对于“结构化 UI”和“业务状态逻辑”，仍然优先组件与组合式 API

在实际项目中，你可以先把这些高频指令沉淀成一个 `directives` 目录，并在入口统一注册，形成自己团队的“指令库”，后续即可在模板中用语义化的方式复用这些行为能力。

