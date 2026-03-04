#!/usr/bin/env bash

# 提交信息（可选参数，不传就是 "new post"）
MSG=${1:-"new post"}

git add .
git commit -m "$MSG"
git push
