---
title: JavaScript 中 0.1 + 0.2 不等于 0.3 的真相与解决方案
index_img: https://img.sunjc.vip/2026/03/tmp.webp
date: 2026-01-05 21:07:12
tags: JavaScript
comments: true
---

# JavaScript 中 0.1 + 0.2 不等于 0.3 的真相与解决方案

在前端开发中，你一定见过这段代码：

```js
0.1 + 0.2 === 0.3; // false
0.1 + 0.2;         // 0.30000000000000004
```

看似简单的小数加法，却给出了“错误”的结果。这并不是 JavaScript 的 bug，而是 **几乎所有使用 IEEE 754 双精度浮点数的语言** 都会遇到的问题（包括 Java、C#、Python 等）。

本文从原理、现象到工程实践，系统讲清楚：

- 为什么 0.1 + 0.2 不等于 0.3？
- 这个问题具体会在哪些业务场景“坑你”？
- 在项目中，该如何优雅地解决？（包含多种方案对比）

---

## 一、现象：0.1 + 0.2 究竟发生了什么？

先看几组实验：

```js
0.1 + 0.2;              // 0.30000000000000004
0.3 - 0.2;              // 0.09999999999999998
0.1 + 0.7;              // 0.7999999999999999

0.1 * 10;               // 1
0.3 * 10;               // 2.9999999999999996

0.1 + 0.2 === 0.3;      // false
Number(0.1 + 0.2).toFixed(2); // "0.30"
```

可以发现：

- **运算结果本身是“接近”预期的值**，只是多了/少了一个极小的误差。
- 用 `toFixed` 格式化后，看起来又“正常了”。

这说明：

> 问题的本质是“二进制浮点数表示与运算带来的精度误差”，而不是“算错了很多”。

---

## 二、根源：十进制小数在二进制中的表示问题

### 1. JavaScript 使用的是 IEEE 754 双精度浮点数

JavaScript 中的 `Number`（不包括 `BigInt`）统一使用 **IEEE 754 double precision**（64 位双精度浮点数）。

简化理解其结构：

```text
1 位   符号位（sign）
11 位  指数位（exponent）
52 位  尾数/有效数字（fraction / mantissa）
```

数值形式大致为：

\[
(-1)^{sign} \times 1.\text{fraction}_2 \times 2^{exponent - bias}
\]

这意味着：

- 所有数字最终都要表示成“二进制科学计数法”。
- 浮点运算在有限位数下，必然存在**不可精确表示**的情况。

### 2. 0.1 在二进制中是个“无限循环小数”

十进制中的 0.1，用二进制表示大致是：

```text
0.0001100110011001100110011001100...(无限循环)
```

类似于十进制的 1/3：

```text
0.3333333...(无限循环)
```

但浮点数只有 52 位尾数能存储小数部分，因此 **0.1 只能被“截断近似”**。

0.2 也是类似：

```text
0.0011001100110011...(同样是无限循环)
```

所以：

> 在底层，JavaScript 存的并不是“精确的 0.1 和 0.2”，而是两个“最接近它们的二进制浮点近似值”。

### 3. 0.1 + 0.2 的具体误差来源

当进行 `0.1 + 0.2` 时，实际上是：

```text
0.1 的近似值 + 0.2 的近似值 = 0.30000000000000004...
```

因为两次近似值相加后又进行了浮点标准化与舍入，最终得到的结果变成了 `0.30000000000000004`。

换言之：

> **误差并不是运算时“突然出现”的，而是在“表示阶段”就已经埋下了。**

---

## 三、这个坑在实际项目中会怎么“咬你”？

### 1. 金额计算

```js
const price = 0.1;
const count = 3;
const total = price * count; // 0.30000000000000004
```

若直接在页面显示或传给后端，就会出现金额多 0.00000000000000004 的奇怪现象。

### 2. 精确比较失败

```js
if (0.1 + 0.2 === 0.3) {
  // 预期：进入这里
}
// 实际：不会进入
```

逻辑判断中若使用严格相等，会得出“意外结果”。

### 3. 分页/进度等 UI 计算

```js
const step = 0.1;
let sum = 0;
for (let i = 0; i < 10; i++) {
  sum += step;
}
console.log(sum); // 0.9999999999999999
```

可能导致进度条永远到不了 100%、循环终止条件异常等。

---

## 四、解决思路总览：避免“直接用浮点数比大小”

几种常见解决方向：

- **1. 容忍误差 → 误差范围比较（EPSILON）**
- **2. 转为整数运算 → 放大/缩小法**
- **3. 使用专门的 decimal/big number 库**
- **4. 在显示层做格式化 → `toFixed` 或国际化格式化**

不同场景可以组合使用。

---

## 五、方案一：EPSILON 误差范围比较（推荐用在“判断相等”的场景）

### 1. 使用 Number.EPSILON

`Number.EPSILON` 表示 1 与能表示的下一个大于 1 的最小浮点数之间的差值，大约是：

```js
Number.EPSILON; // 2.220446049250313e-16
```

可以基于它定义一个“近似相等”函数：

```js
function nearlyEqual(a, b, epsilon = Number.EPSILON) {
  return Math.abs(a - b) < epsilon;
}

nearlyEqual(0.1 + 0.2, 0.3); // true
```

### 2. 工程中常用的容差设置

实际使用中可将容差适当放大一些，例如：\`1e-10\`、\`1e-8\` 等：

```js
function isEqual(a, b, epsilon = 1e-10) {
  return Math.abs(a - b) < epsilon;
}
```

适用场景：

- 进度比较（是否到 100%）
- 坐标/位移比较（动画、canvas、图表）
- 逻辑判断中“接近即可”的场景

不适用：

- 金额等**必须精确**的场景（钱不能“差不多”）

---

## 六、方案二：放大为整数运算（金额等精确运算推荐）

核心思路：

> 把小数按固定倍数放大成整数进行计算，最后再缩小回来。

### 1. 金额经典写法：以“分”为单位

```js
// 价格以“元”为单位显示，以“分”为单位计算
const priceYuan = 0.1;
const count = 3;

const priceCent = Math.round(priceYuan * 100); // 10
const totalCent = priceCent * count;           // 30
const totalYuan = totalCent / 100;             // 0.3
```

关键点：

- **统一把所有参与运算的金额都转成整数（分）**
- 只在**输入/显示**时做小数转换

### 2. 通用的小数精确运算封装

简单的“精度对齐 + 放大”做法（适用于小数位数有限的情况）：

```js
function toInteger(num) {
  const str = String(num);
  if (!str.includes(".")) return { int: num, multiplier: 1 };
  const decimalLength = str.split(".")[1].length;
  const multiplier = 10 ** decimalLength;
  return { int: Math.round(num * multiplier), multiplier };
}

function add(a, b) {
  const o1 = toInteger(a);
  const o2 = toInteger(b);
  const multiplier = Math.max(o1.multiplier, o2.multiplier);
  const int1 = Math.round(a * multiplier);
  const int2 = Math.round(b * multiplier);
  return (int1 + int2) / multiplier;
}

add(0.1, 0.2); // 0.3
add(0.1, 0.7); // 0.8
```

类似的也可以实现 `sub/mul/div`，许多开源库（如 `number-precision`）就是在这个思路上做了更完善的封装。

适用场景：

- 金额、积分、计数等需要精确的小数运算

注意：

- 对小数位数较长或级联运算复杂的情况，仍建议使用专门的 big number/decimal 库。

---

## 七、方案三：使用 decimal / big number 库（高精度通用方案）

当你需要更强的精度与丰富的运算能力时，可以考虑使用专门的库，例如：

- `decimal.js`
- `big.js`
- `bignumber.js`

### 1. 以 decimal.js 为例

安装：

```bash
npm install decimal.js
```

使用：

```js
import Decimal from "decimal.js";

const a = new Decimal(0.1);
const b = new Decimal(0.2);

a.plus(b).toNumber();   // 0.3
a.plus(b).toString();   // "0.3"

// 更多运算
const c = new Decimal("1.23456789");
const d = new Decimal("0.00000001");
c.plus(d).toString();   // "1.23456790"
```

优势：

- 任意精度控制，适合金融、统计等复杂业务
- 支持大量数学函数和运算

代价：

- 引入额外依赖，包体积增加
- 需要改写大量数值运算代码（用对象和方法替代原生运算符）

适用场景：

- 金融/结算
- 大数运算（如区块链金额、ID）
- 通用高精度需求

---

## 八、方案四：显示层格式化（toFixed 等）

在很多情况下，我们只是「展示给用户看的数字」需要好看/合理，而内部运算误差在可接受范围内。

### 1. 使用 toFixed

```js
const val = 0.1 + 0.2;
val.toFixed(2); // "0.30"
Number(val.toFixed(2)); // 0.3
```

注意：

- `toFixed` 返回的是 **字符串**
- 内部会做四舍五入

适用场景：

- 页面展示金额、百分比等
- 图表/报表上的数值格式化

### 2. 使用 Intl.NumberFormat 国际化格式化

```js
const val = 0.1 + 0.2;

new Intl.NumberFormat("zh-CN", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
}).format(val); // "0.30"
```

优势：

- 内置国际化、千分位等能力

---

## 九、工程实践建议：如何在项目里“统筹规划”

综合来看，可以这样做策略设计：

- **金额/积分等精确数值**
  - 统一采用整数单位（如“分”）
  - 或引入 decimal/big number 库
  - 禁止直接用原生浮点数参与业务结算

- **一般数值逻辑判断**
  - 使用误差容差比较（`epsilon`/`Number.EPSILON`）
  - 避免直接用 `===` 比较浮点结果

- **展示层**
  - 统一使用 `toFixed` 或 `Intl.NumberFormat` 做格式化
  - 在组件层封装 `formatAmount`、`formatPercent` 等工具

- **公共工具库**
  - 抽一个 `math` / `number` 工具模块，统一放：
    - `add/sub/mul/div` 精确运算
    - `isEqual`、`clamp`、`round` 等
  - 所有业务代码只使用工具方法，避免散落的裸算

---

## 十、总结

`0.1 + 0.2 !== 0.3` 的根源是：

- JavaScript 使用 IEEE 754 双精度浮点数表示所有 `Number`
- 许多十进制小数在二进制中是**无限循环小数**，只能近似表示
- 近似值运算后再经过一次舍入，产生微小误差

在工程实践中，不要再纠结“JavaScript 为啥连 0.1 + 0.2 都算不准”，而是：

1. **接受浮点误差是事实**，并理解它的来源。
2. **根据业务场景选择合适方案**：误差容差、整数化、decimal 库、显示层格式化等。
3. **在项目中统一设计数值处理策略**，封装公共工具，避免到处裸写 `0.1 + 0.2 === 0.3` 这种隐患代码。
这样，浮点精度问题就不再是“偶发 bug”，而是被纳入了可控的工程规范之中。
