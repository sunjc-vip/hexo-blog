---
title: Vue 中 computed 和 watch 的核心区别
index_img: https://sunjc.vip/oss/2026/03/ccc.webp
date: 2025-06-19 09:24:58
tags: Vue
comments: true
---

# Vue 中 computed 和 watch 的核心区别

在 Vue（无论 Vue 2 还是 Vue 3）里，`computed` 和 `watch` 都与“响应式”有关，也都是面试高频题。很多同学会困惑：

- 两者都能“根据数据变化做点事情”，到底有什么区别？
- 为什么有些逻辑应该写 computed，有些必须写 watch？
- computed 的“缓存”到底缓存了什么？watch 的“立即执行/深度监听”又是什么？

本文以“**核心差异 → 选型规则 → 实战案例 → 常见坑**”为结构，帮你把这两个概念真正用明白。

---

## 一、先给结论：一句话区分

- **computed**：用于“**派生状态**”（derived state），把多个响应式数据“计算”为一个新值；**有缓存**，返回值像普通变量一样用。
- **watch**：用于“**副作用**”（side effect），当某个数据变化时去做一件事（请求接口、写缓存、手动同步、埋点等）；**无缓存概念**，本质是“监听变化并回调”。

如果你只记住一句话：

> **需要一个“值”→ 用 computed；需要在变化时“做事”→ 用 watch。**

---

## 二、核心区别对照表（高频）

| 维度 | computed | watch |
| --- | --- | --- |
| **定位** | 派生值（计算属性） | 监听器（响应变化触发回调） |
| **关注点** | “我要一个新的值” | “某个值变了我要做事” |
| **返回值** | 有（就是计算结果） | 通常无（执行回调产生副作用） |
| **缓存** | 有缓存：依赖不变则复用上次结果 | 无缓存：每次变化都会触发回调 |
| **依赖收集** | 自动收集（getter 内访问了谁就依赖谁） | 显式指定 source（监听谁） |
| **适合场景** | 拼接展示字段、过滤/排序结果、复杂计算结果 | 接口请求、路由跳转、节流防抖、localStorage 同步、表单联动副作用 |
| **是否可异步** | 不建议（应保持纯计算） | 适合（可以 async/await） |
| **能否拿到新旧值** | 不直接提供（除非自己对比） | 默认提供 `(newVal, oldVal)` |

---

## 三、computed：派生状态 + 缓存

### 1. computed 的本质：一个带缓存的 getter

以 Vue 3 Composition API 为例：

```js
import { ref, computed } from "vue";

const firstName = ref("Sun");
const lastName = ref("jc");

const fullName = computed(() => `${firstName.value} ${lastName.value}`);
```

特点：

- `computed` 产物是一个 `ref`（需要 `.value`）
- getter 内部访问到的响应式数据会被自动收集为依赖
- **依赖不变时，多次读取不会重复计算**

### 2. 缓存到底缓存什么？

缓存的是：**上一次计算出来的结果**。

例如你在模板里多次使用：

```vue
<template>
  <p>{{ fullName }}</p>
  <p>{{ fullName }}</p>
  <p>{{ fullName }}</p>
</template>
```

computed 只会在依赖变化时重新计算一次，而不是每次渲染都重新跑一遍拼接逻辑（尤其是复杂计算时差异明显）。

### 3. computed 应该是“纯函数”

最佳实践：

- computed 里只做计算与返回结果
- 不要在 computed 里发请求、写日志、写 localStorage

原因：

- computed 可能会被多次读取（尤其是模板渲染、依赖追踪）
- 其执行时机由 Vue 调度，副作用会变得不可控

---

## 四、watch：监听变化 + 执行副作用

### 1. watch 的本质：当 source 变化时执行 callback

```js
import { ref, watch } from "vue";

const keyword = ref("");

watch(keyword, (newVal, oldVal) => {
  console.log("keyword changed:", oldVal, "->", newVal);
});
```

特点：

- 你明确告诉 Vue“监听谁”（source）
- 变化时回调会执行，拿到新旧值
- callback 里适合写副作用逻辑（请求、同步、埋点等）

### 2. 监听多个源

```js
watch([a, b], ([newA, newB], [oldA, oldB]) => {
  // ...
});
```

### 3. immediate：是否立即执行一次

默认情况下 watch 不会在初始化时运行，只有变化才触发。  
如果希望“初始化也执行一次”，用 `immediate: true`：

```js
watch(
  keyword,
  (newVal) => {
    fetchList(newVal);
  },
  { immediate: true }
);
```

### 4. deep：深度监听（谨慎使用）

当你监听的是对象/数组时，默认 watch 多数情况下只看引用变化（是否是同一个对象），不会递归监听内部每个字段。

```js
const form = reactive({ name: "", info: { age: 1 } });

watch(
  () => form,
  () => {
    // 默认：可能不会因为 form.info.age++ 触发
  }
);
```

这时可以：

- 更推荐：监听具体字段（更精确、性能更好）

```js
watch(
  () => form.info.age,
  (age) => {
    // ...
  }
);
```

- 或使用 `deep: true`（谨慎：对象很大时开销明显）

```js
watch(
  () => form,
  () => {
    // ...
  },
  { deep: true }
);
```

---

## 五、典型场景：到底该用哪个？

### 场景 1：拼接展示字段（用 computed）

```js
const fullName = computed(() => `${first.value} ${last.value}`);
```

原因：你需要的是一个“值”，并且可以被缓存。

### 场景 2：过滤列表（用 computed）

```js
const filtered = computed(() => list.value.filter((x) => x.active));
```

原因：派生状态，模板渲染会多次读取，缓存很重要。

### 场景 3：搜索关键字变化触发请求（用 watch）

```js
watch(keyword, (k) => {
  fetchList(k);
});
```

原因：请求是副作用，computed 不应该做。

### 场景 4：表单联动副作用（用 watch）

例如省份变化后清空城市、重新拉城市列表：

```js
watch(provinceId, async (id) => {
  cityId.value = "";
  cities.value = await fetchCities(id);
});
```

### 场景 5：一个值既要计算又要做事（组合）

例如根据用户信息派生出一个展示标题（computed），同时当用户角色变化时上报埋点（watch）：

```js
const title = computed(() => `${user.value.name}（${user.value.role}）`);

watch(
  () => user.value.role,
  (role) => {
    trackRoleChange(role);
  }
);
```

---

## 六、Vue 2 Options API 中的写法对照

### computed（Vue 2）

```js
export default {
  data() {
    return { first: "Sun", last: "jc" };
  },
  computed: {
    fullName() {
      return `${this.first} ${this.last}`;
    },
  },
};
```

### watch（Vue 2）

```js
export default {
  data() {
    return { keyword: "" };
  },
  watch: {
    keyword(newVal, oldVal) {
      this.fetchList(newVal);
    },
  },
};
```

---

## 七、常见误区与坑

### 1. 用 watch 去维护“派生值”（不推荐）

```js
watch([a, b], ([newA, newB]) => {
  sum.value = newA + newB;
});
```

这种写法能跑，但不优雅：

- sum 本质是派生值，应该用 computed
- watch 更适合副作用，而不是同步派生状态

正确写法：

```js
const sum = computed(() => a.value + b.value);
```

### 2. 在 computed 里做异步请求（不推荐）

```js
const data = computed(async () => {
  return await fetchData();
});
```

问题：

- computed 期望返回一个“同步可用”的值
- async 会返回 Promise，模板渲染与依赖追踪会变得混乱

正确做法：

- 用 watch 或在生命周期中请求，然后把结果写入响应式变量

### 3. deep watch 滥用

对大型对象 `deep: true` 会带来明显性能开销。优先选择：

- 监听具体字段
- 或在提交时一次性读取对象（不需要实时深度监听）

---

## 八、总结（最实用的选型口诀）

- **要一个值（派生状态）**：用 `computed`
- **要做一件事（副作用）**：用 `watch`
- **不要用 watch 去“同步派生值”**，除非有特别原因
- **不要在 computed 里做副作用**（请求、写缓存、埋点）
- **避免滥用 deep watch**，尽量精确监听字段

理解这套思路后，你会发现 computed/watch 的使用边界非常清晰：一个负责“算值”，一个负责“做事”。
