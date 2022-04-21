使用shell片段实现单文件版git,用于学习git三大核心对象实现,以便深入理解git设计思想

usage:

```shell
# 构建运行环境镜像并进入工作目录
just build-ubuntu && just run-ubuntu && just exec-ubuntu

# 进入容器后可执行各种命令进行测试，执行just -l 查看各命令说明
just -l

# 进入git初版实现代码目录 并编译,参考 https://developer.aliyun.com/article/772825?
cd /home/deploy/projects/baby-git && make 
```

参考:

c语言初版实现

https://bitbucket.org/jacobstopak/baby-git.git

依赖工具:

hexyl

pigz

just

git

支持命令:

add 

commit 

diff

*未实现分支*

*未实现index*

justfile版:

研究git三大对象代码片段集合

仅支持单文件

测试:

just test


support os:

macos

ubuntu 20.04


