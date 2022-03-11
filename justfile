# 单文件git实现
# 获取git提交时的用户名和邮箱
user :="techzealot"
email :="techzealot@foxmail.com"
db_dir:="just"
git_dir:="git"
git_alias:="git --git-dir=./git --work-tree=./"
export GIT_WORK_TREE:="./"
export GIT_DIR:="git"

# 删除临时文件
clean:
    -rm *.tmp tmp
    -rm -rf {{db_dir}} {{git_dir}}

# 输出文件字节数 [file] 目标文件
length file:
    cat {{file}}|wc -c

# 创建blob对象 [file] 需要加入版本管理的目标文件
blob file:
    #!/usr/bin/env bash
    set -e    
    inputFile={{file}}
    contentFile={{file}}.blob.tmp
    length=`cat $inputFile|wc -c|sed s/[[:space:]]//g`
    echo -e -n "blob $length\0" > $contentFile
    cat $inputFile >> $contentFile
    just store $contentFile
    rm $contentFile

# 从中间文件创建git对象 [contentFile] 符合blob,tree,commit对象协议的未加密临时中间文件 output: hash
store contentFile:
    #!/usr/bin/env bash
    set -e    
    # hexyl {{contentFile}}
    contentFile={{contentFile}}
    hash=`openssl sha1 $contentFile|awk '{print $2}'|xargs echo -n`
    echo "$hash"
    mkdir -p {{db_dir}}/objects/${hash:0:2}
    dbFile={{db_dir}}/objects/${hash:0:2}/${hash:2}
    # 判断object已存在
    if [[ -f "$dbFile" ]]; then
    exit 0
    fi
    pigz -z --fast < $contentFile > $dbFile
    objectFile={{git_dir}}/objects/${hash:0:2}/${hash:2}
    cmp $dbFile $objectFile

# 创建tree对象 [file] tree对象关联的文件名 [blobHash] blob对象的hash
tree file blobHash:
    #!/usr/bin/env bash
    set -e    
    inputFile={{file}}
    contentFile={{file}}.tree.tmp
    echo -n -e "100644 $inputFile\0" > $contentFile
    echo -n "{{blobHash}}" | xxd -r -p >> $contentFile
    length=`cat $contentFile|wc -c|sed s/[[:space:]]//g`
    echo -e -n "tree $length\0"|cat - $contentFile > tmp
    mv tmp $contentFile
    just store $contentFile
    rm $contentFile

# 创建commit对象 [message] 提交信息 [treeHash] 关联的tree对象的hash [parentHash] 父提交的hash,初次提交无父提交,默认为空
commit message treeHash parentHash='':
    #!/usr/bin/env bash
    set -e    
    contentFile=commit.tmp
    echo "tree {{treeHash}}" > $contentFile
    # parent
    parentHash={{parentHash}}
    if [[ -n $parentHash ]]; then
    echo "parent $parentHash" >> $contentFile
    fi
    # commit timestamp 通过git log获取根据treeHash提交时间
    commitTime=`git log --pretty=format:"%T %at"|grep {{treeHash}}|awk '{print $2}'|xargs echo -n`
    echo -e "author {{user}} <{{email}}> $commitTime +0800" >> $contentFile
    echo -e "committer {{user}} <{{email}}> $commitTime +0800" >> $contentFile
    echo "" >> $contentFile
    echo {{message}} >> $contentFile
    length=`cat $contentFile|wc -c|sed s/[[:space:]]//g`
    echo -e -n "commit $length\0"|cat - $contentFile > tmp
    mv tmp $contentFile
    just store $contentFile
    rm $contentFile

# 查看commit的十六进制内容 [ref] commit hash,支持HEAD相关写法,默认为HEAD(当前提交)
cat-commit ref='HEAD':
    #!/usr/bin/env bash
    set -e    
    git cat-file -p {{ref}}
    echo ""
    hash=`git show {{ref}}|head -n 1|awk '{print $2}'`
    echo "hex format:"
    unpigz -d < {{git_dir}}/objects/${hash:0:2}/${hash:2}|hexyl

# 按指定格式列出commit信息 [ref] commit hash,支持HEAD相关写法,默认为HEAD(当前提交)
list-commits ref='HEAD':
    #!/usr/bin/env bash
    set -e    
    git log {{ref}} --pretty=format:"commit:%H,parent:%P,tree:%T,timestamp:%at"

# 查看commit引用的tree对象中的blob列表 [ref] commit hash,支持HEAD相关写法,默认为HEAD(当前提交)
cat-tree ref='HEAD':
    #!/usr/bin/env bash
    set -e    
    hash=`git cat-file -p {{ref}}|head -n 1|awk '{print $2}'`
    echo "tree item list:"
    git cat-file -p $hash

# 查看commit的提交时间戳 [ref] commit hash,支持HEAD相关写法,默认为HEAD(当前提交)
show-time ref='HEAD':
    #!/usr/bin/env bash
    set -e    
    git show {{ref}} -s --format=%ct

# 设置git用户名和邮件,commit时使用 [user] 用户名 [e-mail] 邮件 
set-git:
    #!/usr/bin/env bash
    set -e    
    git config user.name "{{user}}"
    git config user.email "{{email}}"

# 测试shell版git
test:
    #!/usr/bin/env bash
    set -e
    just clean
    echo "start prepare two git commit"
    git init
    git config user.name "{{user}}"
    git config user.email "{{email}}"
    echo "hello" > hello.txt
    git add hello.txt
    git commit -m "first commit"
    echo "world" >> hello.txt
    git add hello.txt
    git commit -m "second commit"
    echo "start validate shell git"
    echo "hello" > hello.txt
    echo "just blob"
    hash1=`just blob hello.txt|tr -d "\n"`
    echo "just tree"
    tree1=`just tree hello.txt $hash1|tr -d "\n"`
    echo "just commit"
    commit1=`just commit "first commit" $tree1 ""|tr -d "\n"`
    echo "world" >> hello.txt
    echo "just blob"
    hash2=`just blob hello.txt|tr -d "\n"`
    echo "just tree"
    tree2=`just tree hello.txt $hash2|tr -d "\n"`
    echo "just commit"
    hash2=`just commit "second commit" "$tree2" "$commit1"|tr -d "\n"`
    rm hello.txt



# docker镜像

DOCKER_IMAGE_UBUNTU:="techzealot/ubuntu20.04-git-dev"

DOCKER_NAME_UBUNTU:="ubuntu20.04-git-dev"

MOUNT_DIR:=`pwd`

SSHD_PORT:="22222"

DESTINATION:="/home/deploy/mini-git"

# 进入开发环境镜像,并将当前目录挂载到/mnt目录下
exec-ubuntu:
	docker exec -it --user 1000 -w {{DESTINATION}} {{DOCKER_NAME_UBUNTU}} bash

# 运行开发环境镜像
run-ubuntu:
	-docker stop {{DOCKER_NAME_UBUNTU}}
	docker run --rm -d --cap-add sys_ptrace -p127.0.0.1:{{SSHD_PORT}}:22 --mount type=bind,source={{MOUNT_DIR}},destination={{DESTINATION}} --name {{DOCKER_NAME_UBUNTU}} {{DOCKER_IMAGE_UBUNTU}}
# 构建开发环境镜像
build-ubuntu:
	docker build -f Dockerfile -t {{DOCKER_IMAGE_UBUNTU}} .