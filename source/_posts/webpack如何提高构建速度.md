---
title: webpack 怎么提高构建速度？
index_img: https://sunjc.vip/oss/2026/03/nn.webp
date: 2025-06-27 09:31:44
tags: webpack
comments: true
---

# webpack 怎么提高构建速度？

随着项目规模增大，webpack 的构建时间很容易从几秒膨胀到几十秒甚至一分钟以上，严重影响开发效率与 CI/CD 流水线速度。相比“无脑上硬件”，更重要的是利用好 webpack 本身提供的优化手段。

本文围绕以下几个方面，总结 webpack 提速的常用实践：

- 减少不必要的编译工作（范围、体积）
- 提升单次构建效率（缓存、多进程/多实例）
- 优化开发体验（增量构建、热更新）
- 在 CI/生产构建中做差异化优化

---

## 一、明确目标：开发构建 vs 生产构建

首先要区分两类场景：

- **开发环境（dev）**
  - 关注：首次启动时间、热更新速度、错误信息友好
  - 可以牺牲一定的产物质量（不必压缩、不开启复杂优化）
- **生产环境（prod）**
  - 关注：最终包体积、运行性能
  - 构建时间可以稍长，但仍需控制在可接受范围

因此，webpack 配置应当 **按环境拆分**，不要“一套配置走天下”。

---

## 二、减少不必要的编译与打包

### 1. 合理配置 `exclude` / `include`

对于 loader（尤其是 `babel-loader`、`ts-loader` 这类编译型 loader），一定要限制处理范围：

```js
{
  test: /\.[jt]sx?$/,
  include: path.resolve(__dirname, "src"),
  exclude: /node_modules/,
  use: "babel-loader",
}
```

避免无意义地编译：

- `node_modules` 中的第三方库（如无需转译时）
- 已经被编译过的产物（如某些内部组件库）

### 2. 合理使用 alias 与 extensions

```js
resolve: {
  alias: {
    "@": path.resolve(__dirname, "src"),
  },
  extensions: [".js", ".jsx", ".ts", ".tsx", ".json"],
},
```

- 不要把大量不必要的后缀放进 `extensions`
- 合理 alias 可以减少深层目录查找，加快模块解析

### 3. 拆分大型入口

避免将所有页面逻辑集中在一个超大的入口文件中：

- 使用按需加载（动态 import）
- 按路由/模块拆分 entry 或使用 `optimization.splitChunks`

---

## 三、利用缓存：持久化缓存与 loader 缓存

### 1. webpack5 内置持久化缓存（filesystem cache）

在 webpack 5 中，可以开启内置缓存，大幅提升二次构建速度：

```js
module.exports = {
  cache: {
    type: "filesystem",
    buildDependencies: {
      config: [__filename], // 当配置文件变化时失效
    },
  },
};
```

效果：

- 首次构建较慢
- 之后构建会复用缓存，大幅提速（尤其在 CI 缓存场景下）

### 2. loader 级缓存

以 `babel-loader` 为例：

```js
{
  test: /\.[jt]sx?$/,
  include: path.resolve(__dirname, "src"),
  use: {
    loader: "babel-loader",
    options: {
      cacheDirectory: true, // 开启缓存目录
    },
  },
}
```

其他 loader（如 `ts-loader`）也有类似 cache 选项，可根据文档开启。

---

## 四、多进程与多实例并行

### 1. thread-loader：多进程处理编译密集型 loader

对耗时较长的 loader（如 babel/ts）可以使用 `thread-loader` 提升并行度：

```js
{
  test: /\.[jt]sx?$/,
  use: [
    {
      loader: "thread-loader",
      options: {
        workers: 2,
      },
    },
    "babel-loader",
  ],
}
```

注意：

- 子进程本身有启动开销；对于小项目或小文件，不一定提速，甚至可能变慢
- 更适合中大型项目、大量文件编译场景

### 2. cache + thread-loader 的组合

建议优先：

1. 开启缓存（filesystem cache + babel cacheDirectory）
2. 再考虑使用 `thread-loader` 并行化编译

---

## 五、减少不必要的插件与优化（尤其在开发环境）

### 1. 按环境区分 plugins

在开发环境（`mode: development`）中：

- 可以关闭或弱化：
  - 代码压缩（`TerserPlugin`）
  - 复杂的分析/报告插件（如 bundle analyzer）
  - 体积优化相关的复杂 plugin
- 保留：
  - HMR（热更新）相关 plugin
  - 友好错误提示插件

在生产环境中，再启用这些优化型 plugin。

### 2. optimization 配置按需调整

```js
optimization: {
  minimize: isProd,
  splitChunks: isProd
    ? {
        chunks: "all",
      }
    : false,
  runtimeChunk: isProd ? "single" : false,
}
```

开发环境中可以禁用部分拆包/优化，以缩短构建与热更新时间。

---

## 六、提升开发体验：HMR 与增量构建

### 1. 使用 `webpack-dev-server` 或 `webpack-dev-middleware`

开发时不必每次都输出到磁盘，可以：

- 使用内存文件系统提升读写速度
- 结合 HMR 只热更新修改的模块

示例（devServer）：

```js
devServer: {
  hot: true,
  compress: true,
  historyApiFallback: true,
},
```

### 2. 控制 source map 质量

source map 生成也会消耗时间。开发环境可使用：

```js
devtool: "cheap-module-source-map",
// 或 "eval-cheap-module-source-map"
```

生产环境可以：

- 关闭或使用 `hidden-source-map` / `nosources-source-map`，视安全策略而定

---

## 七、针对第三方库的优化

### 1. externals：排除某些库的打包

如果某些大型库（如 React、Vue）通过 CDN 注入全局变量，可在 webpack 中排除它们：

```js
externals: {
  react: "React",
  "react-dom": "ReactDOM",
},
```

这样可以：

- 减少打包体积
- 缩短构建时间

前提是：

- 确保运行环境中已通过 `<script>` 引入这些库

### 2. 利用 `resolve.alias` 指向更轻量版本

例如 React 16 时代常见：

```js
resolve: {
  alias: {
    "react-dom": "@hot-loader/react-dom",
  },
},
```

或指向预编译版本、生产版本等。

---

## 八、在 CI / 生产构建中的额外优化

### 1. 利用 CI 缓存

如 GitHub Actions / GitLab CI 中：

- 缓存 `node_modules`
- 缓存 webpack filesystem cache 目录

可以显著减少冷启动与全量构建时间。

### 2. 拆分构建任务

对于 Monorepo / 多应用项目：

- 按子项目或子包拆分构建任务
- 使用 Turborepo / Nx 等工具做任务编排与缓存

---

## 九、总结：webpack 提速实践清单

1. **范围控制**
   - [ ] loader 中合理配置 `include` / `exclude`
   - [ ] 避免无意义编译 `node_modules`
2. **缓存**
   - [ ] 开启 webpack5 filesystem cache
   - [ ] 开启 babel/ts-loader 等 loader 缓存
3. **并行**
   - [ ] 对编译耗时 loader 使用 `thread-loader`（结合项目规模评估）
4. **按环境拆配置**
   - [ ] dev 环境关闭压缩与复杂优化
   - [ ] prod 环境启用代码拆分、压缩、hash 等
5. **开发体验**
   - [ ] 使用 devServer + HMR + 内存文件系统
   - [ ] 合理选择 source map 类型
6. **第三方库处理**
   - [ ] 对于通过 CDN 引入的库使用 `externals`

整体原则可以概括为：

> **让 webpack 少干活、干得快、且分工合理。**

在新项目中，如果可以选择更轻量的构建工具（如 Vite），也可以将 webpack 更多用于兼容或特殊场景，但对 webpack 构建流程与优化手段的理解，依然会在各种工程场景中发挥价值。
