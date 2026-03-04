---
title: webpack 的构建流程详解
index_img: https://sunjc.vip/oss/2026/03/nn.webp
date: 2024-12-12 20:33:21
tags: webpack
comments: true
---

# webpack 的构建流程详解

作为前端工程化时代的“老牌选手”，webpack 依然广泛应用在中大型项目中。理解 webpack 的构建流程，有助于你：

- 正确使用 loader / plugin，避免配置“玄学”
- 更好地做按需拆包、性能优化
- 在项目定制化需求下扩展构建能力

本文从整体流程入手，讲清楚：

- webpack 在一次构建中都做了哪些事情？
- loader 与 plugin 分别介入在什么阶段？
- 常见的构建问题（路径、别名、hash 等）背后发生了什么？

---

## 一、webpack 的核心概念回顾

- **Entry（入口）**：构建从哪里开始解析依赖图
- **Module（模块）**：每个 JS/TS/CSS/图片等都被视为一个模块
- **Dependency Graph（依赖图）**：模块之间通过 `import/require` 形成的有向图
- **Chunk（代码块）**：一组模块的打包结果（入口 chunk、异步 chunk 等）
- **Bundle（产物）**：最终输出到磁盘的文件，如 `main.[hash].js`

---

## 二、整体构建流程总览

可以将 webpack 的构建流程概括为以下几个阶段：

1. 初始化参数（解析配置、合并 CLI 选项）
2. 创建 Compiler 对象
3. 挂载插件（plugins）并执行 Tapable 钩子
4. 确定入口并从入口出发构建模块依赖图
5. 使用 loader 处理各类模块，生成最终 JS 模块
6. 对所有模块进行优化（tree-shaking、scope hoisting 等）
7. 生成 chunk，并输出到指定目录（emit）

下面逐步展开。

---

## 三、初始化阶段：读取配置与创建 Compiler

1. 读取配置文件（`webpack.config.js` 或多配置对象）
2. 与 CLI 传入的参数（如 `--mode production`）进行合并
3. 创建一个 **Compiler 实例**：
   - 全局只有一个 Compiler，贯穿整个构建生命周期
   - 内部保存着 options、loader/plugin 注册信息、文件系统等

在这一步，webpack 会执行：

```js
const compiler = webpack(config);
```

很多插件会在此阶段通过 `compiler.hooks` 注册钩子。

---

## 四、挂载插件：Tapable 钩子系统

webpack 大量使用 Tapable 实现插件机制：

- `compiler` 与 `compilation` 对象上有许多生命周期钩子，如：
  - `beforeRun`, `run`, `compile`, `make`, `emit`, `done` ...
- 插件通过在这些钩子上 `tap` / `tapAsync` / `tapPromise` 注入逻辑

示例（简化）：

```js
class MyPlugin {
  apply(compiler) {
    compiler.hooks.emit.tap("MyPlugin", (compilation) => {
      // 在 emit 阶段对输出资源做处理
    });
  }
}
```

**理解插件 = 理解它在哪个钩子上做了什么事情**。

---

## 五、从 Entry 出发构建模块依赖图

确定入口（entry）后，webpack 会：

1. 为每个入口创建一个对应的入口模块
2. 递归解析模块中的依赖（`import/require`）
3. 为每个依赖创建模块对象，并继续向下递归

这个过程中，会用到：

- 模块解析规则（`resolve.alias`、`extensions` 等）
- loader 对不同类型文件的处理规则（`module.rules`）

---

## 六、Loader：模块转换管道

webpack 的模块处理采用“loader 链”的模式：

```js
module: {
  rules: [
    {
      test: /\.css$/,
      use: ["style-loader", "css-loader"],
    },
  ];
}
```

含义：

- 当遇到 `.css` 文件时：
  - 先由 `css-loader` 处理（从右到左执行）
  - 再由 `style-loader` 处理

loader 的职责：

- 接收源文件内容（字符串/Buffer）
- 进行转换（如 TS→JS、SCSS→CSS、图片转 Base64 等）
- 输出 JS 模块代码（或异步返回）

webpack 本身只理解 JS，所有非 JS 资源都需要通过 loader 转换为 JS 可以处理的模块形式。

---

## 七、Compilation：一次构建过程的“快照”

在构建过程中，webpack 会为每一次构建/增量构建创建一个 **Compilation 对象**：

- 用于描述当前构建的模块、依赖、chunk 等信息
- plugin 可以通过 `compilation.hooks` 在更细粒度的阶段干预

例如：

```js
compiler.hooks.compilation.tap("MyPlugin", (compilation) => {
  compilation.hooks.optimizeChunks.tap("MyPlugin", (chunks) => {
    // 对 chunk 做进一步优化/拆分
  });
});
```

---

## 八、优化阶段：Tree Shaking / 代码分割等

在所有模块构建完成后，webpack 会进入优化阶段：

1. Tree Shaking（在 ESModule 下，基于“按需导出”的静态分析删除未使用代码）
2. Scope Hoisting（作用域提升，将多个模块合并到一个函数中，减少闭包层级）
3. 代码分割（Code Splitting）：
   - 按路由/组件拆分异步 chunk
   - 抽离公共模块/第三方库到独立 chunk
4. 压缩与混淆（production 模式下一般由 TerserPlugin 完成）

这些优化通常由内置插件和配置驱动：

- `optimization.splitChunks`
- `optimization.runtimeChunk`
- `mode: "production"` 或显式配置 minimizer

---

## 九、生成 Chunk 与输出文件（Emit 阶段）

在模块优化完成后，webpack 会根据入口与依赖关系生成若干 chunk：

- entry chunk：入口对应的主 bundle
- async chunk：动态 import 或代码分割产生的异步 chunk

然后为每个 chunk 生成对应文件名（带 hash/ contenthash 等），并写入输出目录：

```js
output: {
  path: path.resolve(__dirname, "dist"),
  filename: "[name].[contenthash:8].js",
  publicPath: "/",
}
```

在 `emit` 阶段，许多插件会对最终产物做处理，例如：

- `HtmlWebpackPlugin`：生成 HTML 并自动注入 `<script>` 标签
- `CopyWebpackPlugin`：复制静态资源
- 自定义 plugin：生成额外的 manifest 文件等

---

## 十、一次构建流程的“时间线”示意

简化版时间线如下：

1. 读取 & 合并配置
2. 创建 Compiler
3. 挂载所有 Plugin（`apply`）
4. 执行 `compiler.run`（或 `watch`）
5. 触发 `compile` / `make` 钩子
6. 从 Entry 出发构建模块 & 依赖图（loader 介入）
7. 完成所有模块构建，进入优化阶段（plugin 介入）
8. 生成 chunk 与文件名
9. 触发 `emit` 钩子，输出文件到磁盘（plugin 介入）
10. 触发 `done` 钩子，构建结束

理解这条时间线，有助于你知道：

- 某个 plugin/loader 的配置问题会在哪个阶段暴露
- 想在构建的哪个阶段插入定制逻辑，应该用哪个钩子

---

## 十一、总结

webpack 的构建流程可以概括为：

- **入口**：依据 entry 创建依赖图的起点
- **模块处理**：通过 loader 把各种资源转换为 JS 模块
- **图构建**：递归解析 import/require，构建完整依赖图
- **优化**：tree-shaking、代码分割、压缩混淆等
- **输出**：生成 chunk 和 bundle 文件，通过 plugin 在各阶段插入自定义逻辑

理解这套流程，不仅能帮助你更合理地组织 webpack 配置，也能在遇到打包问题时快速定位到“是 loader 问题、plugin 问题、还是优化/输出阶段的问题”。
