---
title: npm 与 npx 是什么？有什么区别？
index_img: https://img.sunjc.vip/2026/03/aaa.webp
date: 2025-05-16 14:09:37
tags: Node.js
comments: true
---

# npm 与 npx 是什么？有什么区别？

在前端工程化里，`npm` 和 `npx` 基本每天都会用到，但很多人其实只会“照着命令敲”，并不清楚它们分别解决什么问题、为什么要同时存在、在什么场景下该用哪个。

这篇文章从“是什么 → 为什么 → 怎么用 → 常见坑”的结构，系统讲清楚：

- `npm` 到底是干什么的？
- `npx` 是什么？与 `npm` 的关系是什么？
- 什么时候用 `npm`，什么时候用 `npx`？
- 常见误区与最佳实践

---

## 一、npm 是什么？

### 1. npm 的定位

`npm`（Node Package Manager）是 **Node.js 生态的包管理器**，核心职责是：

- **安装依赖**：把第三方包下载安装到项目里（或全局安装）
- **管理依赖清单**：维护 `package.json`（dependencies / devDependencies 等）
- **运行脚本**：执行 `package.json` 的 `scripts`
- **发布包**（给 npm registry）：用于开源库/内部包发布与版本管理

一句话总结：

> **npm 负责“装包”和“跑项目脚本”。**

### 2. npm 最常用的命令

#### （1）安装依赖

```bash
npm i axios
npm i -D eslint
```

- `npm i` 是 `npm install` 的缩写
- `-D` 表示安装到 `devDependencies`

#### （2）卸载依赖

```bash
npm uninstall axios
```

#### （3）安装所有依赖

```bash
npm install
```

会根据 `package.json`（以及锁文件 `package-lock.json`）安装项目需要的所有依赖。

#### （4）运行 scripts

```bash
npm run dev
npm run build
npm test
```

说明：

- `npm run <script>` 会执行 `package.json` 的 `scripts` 中对应的命令。
- 对于 `start/test` 这类内置别名，通常可以省略 `run`。

---

## 二、npx 是什么？

### 1. npx 的定位

`npx` 可以理解为 **“执行 npm 包里的命令”** 的工具。

它解决的一个核心痛点是：

> 很多包提供的是“命令行工具（CLI）”，你想用它的命令，但又不想全局安装，或者希望优先用项目本地安装的版本。

一句话总结：

> **npx 负责“跑 CLI 命令”，优先运行项目本地的可执行文件，也可以临时下载后运行。**

### 2. npx 会去哪里找命令？

通常优先级可以简单理解为：

1. **当前项目的 `node_modules/.bin`**
2. 如果没有，可能会尝试从 registry 临时下载（取决于命令写法与环境）

这也是为什么很多时候你能在项目里直接写：

```bash
npx eslint .
```

即使你没有全局安装 eslint。

---

## 三、npm vs npx：核心区别

| 对比项 | npm | npx |
| --- | --- | --- |
| **核心职责** | 包管理 + 脚本执行 | 执行包提供的 CLI |
| **主要动作** | install/uninstall/update、run scripts | run command from package |
| **是否必须安装依赖** | 通常需要先安装 | 可以不安装，临时运行一次 |
| **常见使用场景** | 安装依赖、跑 dev/build/test | 运行脚手架、运行本地 CLI、指定版本运行 |

简化记忆：

- **装包用 npm**
- **跑命令（尤其是 CLI）用 npx**

---

## 四、npx 的典型使用场景

### 1. 运行项目本地安装的 CLI（推荐）

例如项目安装了 `webpack`、`eslint`，你可以：

```bash
npx webpack
npx eslint .
```

好处：

- 使用的是**项目锁定的版本**，团队一致性更好
- 不需要全局安装，不会污染系统环境

### 2. 临时运行脚手架（不落地安装）

常见做法是“初始化项目”：

```bash
npx create-vite@latest
```

这类脚手架通常只是运行一次，没必要作为依赖长期安装。

### 3. 指定版本运行（解决版本差异）

```bash
npx vite@5.4.0 --version
```

当你想复现线上问题或验证特定版本行为时，指定版本很有用。

---

## 五、npm run 与 npx 的关系：为什么很多时候都能运行同一个命令？

你可能见过两种写法都能跑：

```bash
npm run lint
npx eslint .
```

它们的关系是：

- `npm run <script>`：执行 `scripts` 中你写好的命令（可组合多个命令、带参数、带环境变量等）。
  - 并且在执行时，npm 会自动把 `node_modules/.bin` 加入 PATH，所以脚本里可以直接写 `eslint`、`vite` 这类命令。

- `npx <cmd>`：直接执行某个命令（本地优先），适合临时运行或不想写进 scripts 的一次性命令。

因此在团队项目里更推荐：

- **把常用命令写进 `scripts`**（例如 `lint`、`format`、`test`、`build`）
- 日常开发用 `npm run xxx`（或用你团队的统一约定，如 `pnpm xxx`）

---

## 六、常见坑与最佳实践

### 1. 不要为了省事全局安装所有 CLI

全局安装的问题：

- 不同机器/不同时间安装的版本不一致
- 你本地能跑，别人跑不动（版本差异导致）

更推荐：

- 将 CLI 作为 `devDependencies` 安装在项目里
- 使用 `npm run` 或 `npx` 执行

### 2. 执行脚手架时注意“版本固定”

像 `create-vite@latest` 表示“每次都拿最新版本”，这对新项目很好，但对可复现性较差。

如果你写教程或需要可复现结果，建议写成：

```bash
npx create-vite@5.4.0
```

### 3. npx 运行来源的安全意识

`npx` 可能会临时下载并执行包里的脚本。建议：

- 在团队生产环境或敏感机器上谨慎执行来源不明的命令
- 优先使用你确认可信的官方包与版本

---

## 七、总结

- **npm**：包管理器，负责安装/管理依赖、运行项目脚本。
- **npx**：命令执行器，负责运行包提供的 CLI，优先使用项目本地版本，也可临时下载运行。

实战中的推荐用法：

- 依赖管理用 `npm i / npm ci`
- 常用流程（dev/build/test/lint）固化到 `package.json scripts`，用 `npm run` 执行
- 临时运行脚手架或本地 CLI，用 `npx`

如果你愿意，我也可以基于你当前博客文章风格，顺便再写一篇“npm install vs npm ci 的区别、锁文件与依赖一致性”作为配套篇。
