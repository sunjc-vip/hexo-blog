---
title: 手写代码new
index_img: https://sunjc.vip/oss/2025/12/4.webp
date: 2025-07-07 22:34:33
tags: 手写代码
---

手写new 分为 4 步

1. 新建一个空对象
2. 将空对象的原型指向 new的函数
3. 改变空对象的 this指向
4. 判断 fn返回值是 引用类型 返回引用类型否则 返回新建对象

``` javascript
function myNew(fn, ...args) {
  // 1. 新建一个空对象
  // 2. 将空对象的原型指向 new的函数
  let obj = Object.create(fn.prototype)
  // 3. 改变空对象的 this指向
  let res = fn.apply(obj, args)
  // 4. 判断 fn返回值是 引用类型 返回引用类型否则 返回新建对象
  return (res && typeof res === 'object') ? res : obj
}
```