使用shell片段实现简化版git,用于学习git三大核心对象实现,以便深入理解git设计思想

usage:
just -l

参考:
https://bitbucket.org/jacobstopak/baby-git.git

依赖工具:
hexyl
pigz
just
git

todo:
dockerfile

支持命令
add 
commit 
diff

未实现分支
未实现index

justfile版:
研究git三大对象代码片段集合
仅支持单文件

测试:

just test


support os:
macos
ubuntu 20.04


