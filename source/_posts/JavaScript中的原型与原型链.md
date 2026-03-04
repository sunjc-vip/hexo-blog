---
title: JavaScript 中的原型与原型链
index_img: https://sunjc.vip/oss/2026/03/ll.webp
date: 2024-05-20 14:11:33
tags: JavaScript
comments: true
---

# JavaScript 中的原型与原型链

原型与原型链是 JavaScript 面向对象体系的基础，也是高频面试题。理解它们可以帮助你：

- 理解 `new`、`class`、`extends` 等语法糖的本质
- 正确认知“继承”“共享方法”等行为
- 更好地阅读框架/库的底层实现

本文从“代码出发”，逐步讲清楚：

- `__proto__`、`prototype`、`constructor` 三者的关系
- 原型链是如何实现“属性查找”的？
- 如何用 ES5/ES6 实现继承？

---

## 一、对象的原型：__proto__ 与 [[Prototype]]

在 JavaScript 中，每个对象都有一个内部隐藏属性 `[[Prototype]]`，指向另一个对象（或 `null`），这个对象就是它的 **原型（prototype）**。

大多数环境提供了非标准但实用的访问方式：

```js
const obj = {};
console.log(obj.__proto__); // 一般等于 Object.prototype
```

ES6 也提供了标准方法：

```js
Object.getPrototypeOf(obj);
Object.setPrototypeOf(obj, someProto);
```

---

## 二、函数的 prototype 属性

每一个函数（除箭头函数等少数例外）在创建时，都会自动获得一个 `prototype` 属性：

```js
function Person() {}

console.log(typeof Person.prototype); // "object"
console.log(Person.prototype.constructor === Person); // true
```

`Person.prototype` 的作用：

- 当你使用 `new Person()` 创建实例时，新对象的 `[[Prototype]]` 会指向 `Person.prototype`。

示意：

```js
function Person() {}
const p = new Person();

console.log(Object.getPrototypeOf(p) === Person.prototype); // true
console.log(p.__proto__ === Person.prototype);              // true（非标准）
```

---

## 三、constructor、__proto__、prototype 之间的关系

用一张关系图概括（文字版）：

```text
p.__proto__ === Person.prototype
Person.prototype.constructor === Person

// 函数本身也是对象
Person.__proto__ === Function.prototype
Function.prototype.__proto__ === Object.prototype
Object.prototype.__proto__ === null
```

可以记住几个关键点：

1. 实例对象的 `__proto__` 指向构造函数的 `prototype`
2. 构造函数原型对象（`prototype`）上有 `constructor` 指回构造函数
3. 函数本身也是对象，其原型链最终也指向 `Object.prototype`

---

## 四、原型链：属性查找的路径

当访问对象属性时，JavaScript 引擎会沿着原型链逐级查找：

```js
const obj = { a: 1 };

console.log(obj.toString); // 来自 Object.prototype
```

查找顺序：

1. 先在 `obj` 自身查找是否有 `toString` 属性
2. 若没有，沿着 `obj.__proto__`（即 Object.prototype）查找
3. 再没有，则沿着更上一层（`Object.prototype.__proto__` 为 null）终止

**原型链** 就是由 `[[Prototype]]`（或 `__proto__`）串联起来的一条链：  
`obj → Object.prototype → null`

### 1. 自定义构造函数的原型链

```js
function Animal() {}
const cat = new Animal();

// 原型链：
// cat → Animal.prototype → Object.prototype → null
```

属性查找会沿着这条链向上走，直到找到为止或到达 null。

---

## 五、在原型上共享方法

给构造函数的 `prototype` 添加方法，可以在所有实例之间共享，而不是每个实例都创建一份：

```js
function Person(name) {
  this.name = name;
}

Person.prototype.sayHi = function () {
  console.log("Hi, I'm " + this.name);
};

const p1 = new Person("A");
const p2 = new Person("B");

console.log(p1.sayHi === p2.sayHi); // true，共享同一个函数
```

这比在构造函数内部定义方法更节省内存：

```js
function Person(name) {
  this.name = name;
  this.sayHi = function () {}; // 每个实例一份，不推荐
}
```

---

## 六、ES5 中的继承（原型链继承）

### 1. 最基本的原型链继承

```js
function Animal(name) {
  this.name = name;
}
Animal.prototype.sayName = function () {
  console.log(this.name);
};

function Dog(name, age) {
  Animal.call(this, name); // 继承实例属性
  this.age = age;
}

Dog.prototype = Object.create(Animal.prototype); // 继承原型方法
Dog.prototype.constructor = Dog; // 修正 constructor 指向

Dog.prototype.bark = function () {
  console.log("woof");
};

const d = new Dog("Lucky", 2);
d.sayName(); // Lucky
d.bark();    // woof
```

这里用到了一个关键方法：

```js
Dog.prototype = Object.create(Animal.prototype);
```

含义：

- 创建一个新的对象，其 `__proto__` 为 `Animal.prototype`
- 然后把这个新对象赋值给 `Dog.prototype`

这样，`Dog` 的实例在原型链上会先找到自己的 `bark`，再往上找到 `Animal.prototype` 上的 `sayName`。

---

## 七、ES6 class 与原型的关系

ES6 的 `class` 其实是原型的语法糖：

```js
class Person {
  constructor(name) {
    this.name = name;
  }

  sayHi() {
    console.log("Hi, I'm " + this.name);
  }
}

const p = new Person("Sunjc");
p.sayHi();
```

背后等价于：

```js
function Person(name) {
  this.name = name;
}

Person.prototype.sayHi = function () {
  console.log("Hi, I'm " + this.name);
};
```

继承时：

```js
class Animal {
  constructor(name) {
    this.name = name;
  }
  sayName() {
    console.log(this.name);
  }
}

class Dog extends Animal {
  constructor(name, age) {
    super(name); // 调用父类构造函数
    this.age = age;
  }

  bark() {
    console.log("woof");
  }
}
```

本质上还是在设置原型链：

```js
// 类似 ES5 写法：
Dog.prototype = Object.create(Animal.prototype);
Dog.prototype.constructor = Dog;
Object.setPrototypeOf(Dog, Animal); // 静态属性继承
```

---

## 八、常见面试题与易错点

### 1. instanceof 的判断原理

```js
obj instanceof Constructor;
```

判断逻辑：

- 看 `Constructor.prototype` 是否出现在 `obj` 的原型链上

```js
function Foo() {}
const f = new Foo();

console.log(f instanceof Foo);        // true
console.log(f instanceof Object);     // true
console.log(Foo.prototype.isPrototypeOf(f)); // true
```

### 2. Object.create 与 new 的区别

```js
const obj = Object.create(proto);
```

- 只会创建一个空对象，其 `__proto__` 指向 `proto`
- 不会执行构造函数，不会初始化实例属性

而 `new Constructor()`：

- 会执行构造函数
- 初始化实例属性
- 设置原型链

---

## 九、总结

JavaScript 的原型与原型链可以概括为几条核心规则：

- 每个对象内部都有一个 `[[Prototype]]` 指向其原型对象
- 函数都有一个 `prototype` 属性，用于创建实例时设置其 `[[Prototype]]`
- 属性访问时，会沿着原型链自下而上查找，直到 `null`
- 通过在原型上挂方法，可以在实例之间共享逻辑
- `class/extends` 是基于原型链的语法糖，本质仍是对 `prototype` 与 `__proto__` 的配置

掌握这些概念后，再结合 `new` 的实现、`instanceof` 的判断、ES5/ES6 继承写法，就能从容应对与原型相关的所有面试题与实际编码场景。
