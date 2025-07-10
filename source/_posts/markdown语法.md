---
title: markdown 查询手册
date: 2025-07-07 22:37:53
index_img: https://sunjc.vip/oss/2025/07/HAFcpS.png
tags:
---

## 标题展示

## 加粗展示

**加粗内容**

## 斜体展示

_斜体内容_

## 删除线

~~删除线内容~~

## 超链接

[百度](https://www.baidu.com)

## 图片展示

![6GIYPR](https://sunjc.vip/oss/2025/07/6GIYPR.png)

## 列表展示

### 无序列表

- 项 1
- 项 2
- 项 3

### 有序列表

1. 项 1
2. 项 2
3. 项 3

## 引用展示

> 引用：《I Have a Dream》

## 代码展示

### 行内代码

行内代码示例：`print("hello world")`

### 代码块

```javascript
console.log("hello world");
```

## 表格展示

| 表头 1 |  表头 2  | 表头 3 | 表头 4 |
| :----- | :------: | -----: | ------ |
| 左对齐 | 中间对齐 | 右对齐 | 默认   |
| 内容 1 |  内容 2  | 内容 3 | 内容 4 |
| 内容 5 |  内容 6  | 内容 7 | 内容 8 |

## 任务列表

- [ ] 周五
- [ ] 周六
- [x] 周天

## 脚注

这是一句话[^1]

## Tag 插件

{% note success %}
文字 或者 `markdown` 均可
{% endnote %}

{% note primary %}
primary
{% endnote %}

{% note secondary %}
secondary
{% endnote %}

{% note success %}
success
{% endnote %}

{% note danger %}
danger
{% endnote %}

{% note warning %}
warning
{% endnote %}

{% note info %}
info
{% endnote %}

{% note light %}
light
{% endnote %}

## 行内标签

{% label primary @text %}
{% label default @text %}
{% label info @text %}
{% label success @text %}
{% label warning @text %}
{% label danger @text %}

## 折叠块

{% fold info @title %}
需要折叠的一段内容，支持 markdown
{% endfold %}

---

[^1]: 这是对应的脚注
