---
title: 🔥httpsok一行命令，轻松搞定SSL证书自动续签
index_img: https://sunjc.vip/oss/2025/07/j3Yoc1.png
date: 2025-07-19 05:53:17
tags: https
comments: true
---

## 介绍

### [httpsok](https://httpsok.com/p/51MZ) 是一个便捷的 HTTPS 证书自动续签工具，专为 Nginx 、OpenResty 服务器设计。已服务众多中小企业，稳定、安全、可靠。

## 特点
- 一行命令，一分钟轻松搞定SSL证书自动续期
- 目前免费（大家放心使用）

## 申请SSL证书

打开 [httpsok](https://httpsok.com/p/51MZ) ，登录后，点击【申请证书】
![申请证书](https://sunjc.vip/oss/2025/07/JAE20M.png)

​输入自己的域名（我这里演示是 *sunjc.vip ）并且提交申请

![](https://sunjc.vip/oss/2025/07/s8fUNi.png)

## 添加DNS解析

因为证书签发时，CA厂商要验证这个域名是否属于您，需要您在域名服务商处添加一条 DNS 解析记录。

![](https://sunjc.vip/oss/2025/07/7uMOLJ.png)


## 部署SSL证书

点击按钮复制安装命令。

![](https://sunjc.vip/oss/2025/07/WF00jb.png)

## 到服务器，粘贴并执行刚刚复制的命令，回车 此时 自动更新SSL证书，并且自动重载nginx

![](https://sunjc.vip/oss/2025/07/adv337.png)

## 通过HTTPS访问网站

查看证书详情

![](https://sunjc.vip/oss/2025/07/4O6DiD.png)