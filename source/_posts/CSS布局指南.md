---
title: CSS 布局指南
index_img: https://img.sunjc.vip/2026/03/css.webp
date: 2025-11-18 16:42:27
tags: CSS
comments: true
---

# CSS 布局指南

从早期的 `float`、`table` 布局，到 Flexbox 和 Grid 的普及，再到容器查询、逻辑属性等新特性，CSS 布局能力已经发生了质的飞跃。

---

## 一、了解布局

传统布局方式存在明显局限：

- **float**：需要清除浮动，难以实现等高、居中等需求，语义不清晰。
- **table**：布局与表格语义混淆，响应式改造成本高。
- **inline-block**：存在空白间隙、垂直对齐等问题。

现代布局方案（Flexbox、Grid、容器查询等）则提供了：

- **声明式、语义化**：用属性直接表达「如何排列」，而非 hack。
- **响应式友好**：配合媒体查询、容器查询，适配多种屏幕。
- **减少 JS 参与**：很多过去需要 JS 计算的布局，现在纯 CSS 即可完成。

---

## 二、Flexbox：一维布局的首选

Flexbox 适合**沿一条主轴**排列元素（行或列），是当前最常用的布局方式之一。

### 1. 核心概念

- **Flex 容器**：`display: flex` 或 `display: inline-flex`。
- **主轴（main axis）**：由 `flex-direction` 决定，默认水平。
- **交叉轴（cross axis）**：与主轴垂直。

### 2. 容器属性速览

| 属性 | 常用值 | 说明 |
| --- | --- | --- |
| `flex-direction` | `row` / `column` / `row-reverse` / `column-reverse` | 主轴方向 |
| `flex-wrap` | `nowrap` / `wrap` / `wrap-reverse` | 是否换行 |
| `justify-content` | `flex-start` / `center` / `flex-end` / `space-between` / `space-around` / `space-evenly` | 主轴对齐 |
| `align-items` | `stretch` / `flex-start` / `center` / `flex-end` / `baseline` | 交叉轴对齐 |
| `align-content` | 同上（多行时生效） | 多行时的交叉轴对齐 |
| `gap` | `8px` / `1rem` 等 | 子项间距（现代浏览器均支持） |

### 3. 子项属性

| 属性 | 常用值 | 说明 |
| --- | --- | --- |
| `flex-grow` | 数字 | 有剩余空间时的放大比例 |
| `flex-shrink` | 数字 | 空间不足时的缩小比例 |
| `flex-basis` | 长度 / `auto` | 初始尺寸 |
| `flex` | 简写，如 `1 1 auto` | `grow shrink basis` |
| `align-self` | 覆盖容器的 `align-items` | 单个子项的对齐方式 |

### 4. 经典场景示例

**水平垂直居中：**

```css
.container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}
```

**等分布局 + 自动换行：**

```css
.container {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}

.item {
  flex: 1 1 200px; /* 最小 200px，有空间则均分 */
}
```

**底部对齐（如页脚贴底）：**

```css
.page {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.main {
  flex: 1;
}
```

### 5. 使用注意

- Flex 适合**一维**场景：一行或一列内的排列。
- 复杂二维网格、不规则布局，优先考虑 Grid。
- `gap` 已广泛支持，可替代 `margin` 做子项间距，更简洁。

---

## 三、Grid：二维布局的利器

Grid 适合**行 + 列**同时控制的场景，是真正的「网格布局」。

### 1. 核心概念

- **Grid 容器**：`display: grid` 或 `display: inline-grid`。
- **网格线（grid lines）**：行和列的分界线。
- **网格单元（grid cell）**：行与列交叉形成的格子。
- **网格区域（grid area）**：由多个单元组成的矩形区域。

### 2. 定义网格

**固定列 + 重复：**

```css
.container {
  display: grid;
  grid-template-columns: repeat(3, 1fr); /* 3 列等分 */
  grid-template-rows: auto 1fr auto;
  gap: 16px;
}
```

**响应式列（无需媒体查询）：**

```css
.container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}
```

- `minmax(280px, 1fr)`：每列最小 280px，有空间则均分。
- `auto-fill`：自动填满行，可能产生空列。
- `auto-fit`：列数自适应，空列会被压缩掉。

**命名网格线 / 区域：**

```css
.container {
  display: grid;
  grid-template-areas:
    "header header header"
    "sidebar main main"
    "footer footer footer";
  grid-template-columns: 200px 1fr 1fr;
  grid-template-rows: auto 1fr auto;
}

.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
.footer { grid-area: footer; }
```

### 3. 子项放置

```css
.item {
  grid-column: 1 / 3;  /* 从第 1 条线到第 3 条线 */
  grid-row: 2 / 4;
}

/* 或使用 span */
.item {
  grid-column: span 2;
  grid-row: span 1;
}
```

### 4. 常见布局示例

**圣杯布局（Header + Sidebar + Main + Footer）：**

```css
.layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-rows: 60px 1fr 48px;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  min-height: 100vh;
}
```

**卡片网格（自适应列数）：**

```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}
```

### 5. Grid vs Flexbox 选型

| 场景 | 推荐 |
| --- | --- |
| 一行/一列内的排列、对齐 | Flexbox |
| 多行多列、整体网格 | Grid |
| 需要子项跨行/跨列 | Grid |
| 一维 + 需要换行 | Flexbox 或 Grid 均可 |

---

## 四、容器查询（Container Queries）：按容器而非视口响应

传统响应式依赖**视口宽度**（`@media (min-width: 768px)`），但组件可能出现在侧边栏、卡片、弹窗等不同尺寸的容器中。**容器查询**让你可以基于**父容器尺寸**来调整样式。

### 1. 基本用法

```css
.card-container {
  container-type: inline-size; /* 或 size */
  container-name: card;        /* 可选，用于区分多个容器 */
}

.card {
  display: grid;
  grid-template-columns: 1fr;
}

@container card (min-width: 400px) {
  .card {
    grid-template-columns: 120px 1fr;
  }
}
```

- `container-type: inline-size`：只查询内联方向（通常为宽度），不包含块方向。
- `container-type: size`：同时查询宽高，适用于需要根据高度调整的场景。

### 2. 容器查询单位

- `cqw`：容器宽度的 1%
- `cqh`：容器高度的 1%
- `cqi`：内联方向的 1%
- `cqb`：块方向的 1%

```css
@container (min-width: 300px) {
  .title {
    font-size: clamp(1rem, 5cqw, 1.5rem);
  }
}
```

### 3. 典型场景

- **卡片组件**：在窄容器中单列，在宽容器中双列。
- **侧边栏内的导航**：根据侧边栏宽度切换图标/文字展示。
- **设计系统中的通用组件**：同一组件在不同布局中自适应。

### 4. 兼容性

现代浏览器已普遍支持。如需兼容旧环境，可使用 `@supports` 做降级：

```css
@supports (container-type: inline-size) {
  .card-container {
    container-type: inline-size;
  }
}
```

---

## 五、逻辑属性（Logical Properties）：更好的国际化支持

传统 `margin-left`、`padding-top`、`width`、`height` 等是**物理方向**。在 RTL（从右到左）或竖排书写模式下，需要额外覆盖。**逻辑属性**基于「块方向 / 内联方向」，能自动适配书写模式。

### 1. 方向映射

| 物理 | 逻辑（LTR 水平书写） |
| --- | --- |
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `margin-top` | `margin-block-start` |
| `margin-bottom` | `margin-block-end` |
| `width` | `inline-size` |
| `height` | `block-size` |

### 2. 简写

```css
/* 块方向：上下 */
margin-block: 16px 8px;
padding-block: 1rem;

/* 内联方向：左右 */
margin-inline: auto;
padding-inline: 24px;
```

### 3. 使用示例

```css
.card {
  margin-inline: auto;
  padding-inline: 1.5rem;
  padding-block: 1rem;
  border-inline-start: 4px solid var(--accent);
}
```

在 `direction: rtl` 或 `writing-mode: vertical-rl` 时，上述样式会自动适配，无需额外写 RTL 覆盖。

### 4. 建议

- 新项目可逐步采用逻辑属性，尤其是间距、边框、尺寸。
- 与 `dir="rtl"`、`lang` 等配合，可显著简化多语言、多书写模式的样式维护。

---

## 六、现代响应式布局策略

### 1. 移动优先 + 断点进阶

```css
/* 默认：移动端 */
.container {
  padding: 16px;
}

/* 平板及以上 */
@media (min-width: 768px) {
  .container {
    padding: 24px;
  }
}

/* 桌面 */
@media (min-width: 1024px) {
  .container {
    max-width: 1200px;
    margin-inline: auto;
  }
}
```

### 2. 使用 clamp 做流式排版

```css
h1 {
  font-size: clamp(1.5rem, 2vw + 1rem, 2.5rem);
}

.container {
  padding-inline: clamp(16px, 5vw, 48px);
}
```

- `clamp(min, preferred, max)`：在 min 和 max 之间，按 preferred 计算。
- 可实现随视口平滑缩放，减少断点数量。

### 3. 使用 min() / max() 做智能尺寸

```css
.sidebar {
  width: min(300px, 100%);
}

.content {
  width: max(50%, 400px);
}
```

### 4. 响应式网格的几种写法

**方式一：auto-fill / auto-fit**

```css
grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
```

**方式二：媒体查询切换列数**

```css
.grid {
  display: grid;
  gap: 16px;
}

@media (min-width: 640px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}
@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

**方式三：容器查询（组件级响应）**

```css
.component {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .component { grid-template-columns: 1fr 1fr; }
}
```

---

## 七、Subgrid：子网格继承父网格

当 Grid 子项内部也是网格时，若希望子项的网格线与父网格对齐，可使用 `subgrid`。

### 1. 基本用法

```css
.parent {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  gap: 16px;
}

.child {
  grid-column: 1 / -1; /* 跨满整行 */
  display: grid;
  grid-template-columns: subgrid; /* 继承父级的列定义 */
}
```

子项会使用父级的列轨道，无需重复定义，保证对齐。

### 2. 适用场景

- 表头与表体列对齐。
- 卡片列表与卡片内部区块对齐。
- 多层级网格需要统一对齐时。

### 3. 兼容性

Subgrid 目前支持度在提升中，使用前可查 [Can I Use](https://caniuse.com/css-subgrid)。

---

## 八、其他实用布局技巧

### 1. aspect-ratio：固定宽高比

```css
.video-wrapper {
  aspect-ratio: 16 / 9;
  width: 100%;
}

.avatar {
  aspect-ratio: 1;
  border-radius: 50%;
}
```

无需再使用 `padding-bottom` 等 hack 实现比例盒子。

### 2. object-fit：媒体内容适配

```css
img, video {
  width: 100%;
  height: 200px;
  object-fit: cover; /* 或 contain / fill */
}
```

### 3. 多列布局（columns）

适用于长文本、卡片流等简单多列：

```css
.article {
  column-count: 2;
  column-gap: 2rem;
}

@media (min-width: 768px) {
  .article {
    column-count: 3;
  }
}
```

### 4. 粘性定位（position: sticky）

```css
.sidebar-nav {
  position: sticky;
  top: 80px;
}
```

常用于导航、表头等需要「吸顶」的场景。

---

## 九、布局选型速查表

| 需求 | 推荐方案 |
| --- | --- |
| 水平/垂直居中 | Flexbox `justify-content` + `align-items` |
| 一行内均分/对齐 | Flexbox |
| 多行多列网格 | Grid |
| 响应式列数（按视口） | Grid `repeat(auto-fill, minmax(...))` |
| 响应式列数（按容器） | 容器查询 |
| 固定宽高比 | `aspect-ratio` |
| 页脚贴底 | Flexbox 列方向 + `flex: 1` |
| 圣杯/复杂页面结构 | Grid `grid-template-areas` |
| 双栏（侧边栏 + 主内容） | Grid 或 Flexbox |
| RTL / 多书写模式 | 逻辑属性 |
| 子网格与父网格对齐 | Subgrid |

---

## 十、总结

现代 CSS 布局已经能够覆盖绝大多数页面与组件需求：

- **Flexbox**：一维排列、对齐、均分的首选。
- **Grid**：二维网格、复杂页面结构、自适应列数。
- **容器查询**：按组件所在容器尺寸响应，而非仅按视口。
- **逻辑属性**：更好的国际化与多书写模式支持。
- **Subgrid、aspect-ratio、clamp** 等：让布局更简洁、可维护。

