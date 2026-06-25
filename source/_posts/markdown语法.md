---
title: markdown 查询手册
date: 2020-01-03 22:37:53
index_img: https://img.sunjc.vip/2025/12/1.webp
tags: 其他
---

## 标题展示

{% fold info @源码 %}

```markdown
# 一级标题

## 二级标题

### 三级标题

#### 四级标题

##### 五级标题

###### 六级标题
```

{% endfold %}

## 加粗展示

**加粗内容**
{% fold info @源码 %}

```markdown
**加粗内容**
```

{% endfold %}

## 斜体展示

_斜体内容_

{% fold info @源码 %}

```markdown
_斜体内容_
```

{% endfold %}

## 删除线

~~删除线内容~~
{% fold info @源码 %}

```markdown
~~删除线内容~~
```

{% endfold %}

## 超链接

[百度](https://www.baidu.com)

{% fold info @源码 %}

```markdown
[百度](https://www.baidu.com)
```

{% endfold %}

## 图片展示

![6GIYPR](https://img.sunjc.vip/2025/07/6GIYPR.webp)

{% fold info @源码 %}

```markdown
![6GIYPR](https://img.sunjc.vip/2025/07/6GIYPR.png)
```

{% endfold %}

## 列表展示

### 无序列表

- 项 1
- 项 2
- 项 3

{% fold info @源码 %}

```markdown
- 项 1
- 项 2
- 项 3
```

{% endfold %}

### 有序列表

1. 项 1
2. 项 2
3. 项 3

{% fold info @源码 %}

```markdown
1. 项 1
2. 项 2
3. 项 3
```

{% endfold %}

## 引用展示

> 引用：《I Have a Dream》

{% fold info @源码 %}

```markdown
> 引用：《I Have a Dream》
```

{% endfold %}

## 代码展示

### 行内代码

行内代码示例：`print("hello world")`

{% fold info @源码 %}

```markdown
`print("hello world")`
```

{% endfold %}

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

{% fold info @源码 %}

```markdown
| 表头 1 |  表头 2  | 表头 3 | 表头 4 |
| :----- | :------: | -----: | ------ |
| 左对齐 | 中间对齐 | 右对齐 | 默认   |
| 内容 1 |  内容 2  | 内容 3 | 内容 4 |
| 内容 5 |  内容 6  | 内容 7 | 内容 8 |
```

{% endfold %}

## 任务列表

- [ ] 周五
- [ ] 周六
- [x] 周天

{% fold info @源码 %}

```markdown
- [ ] 周五
- [ ] 周六
- [x] 周天
```

{% endfold %}

## 脚注

这是一句话[^1]

{% fold info @源码 %}

```markdown
这是一句话[^1]
```

{% endfold %}

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

{% fold info @源码 %}

```markdown
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
```

{% endfold %}

## 行内标签

{% label primary @text %}
{% label default @text %}
{% label info @text %}
{% label success @text %}
{% label warning @text %}
{% label danger @text %}

{% fold info @源码 %}

```markdown
{% label primary @text %}
{% label default @text %}
{% label info @text %}
{% label success @text %}
{% label warning @text %}
{% label danger @text %}
```

{% endfold %}

## 折叠块

{% fold info @title %}
需要折叠的一段内容，支持 markdown
{% endfold %}

{% fold info @源码 %}

```markdown
{% fold info @title %}
需要折叠的一段内容，支持 markdown
{% endfold %}
```

{% endfold %}

---

[^1]: 这是对应的脚注

{% fold info @源码 %}

```markdown
[^1]: 这是对应的脚注
```

{% endfold %}
