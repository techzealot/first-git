# reversion from https://github.com/JetBrains/clion-remote/blob/master/Dockerfile.remote-cpp-env
FROM ubuntu:20.04

LABEL maintainer="techzealot" \
      version="1.0" \
      description="ubuntu 20.04 with dev tools for git programing"

#RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install tzdata
ENV USER deploy
ENV PASSWD deploy
ENV PROJECTDIR projects
ENV TZ Asia/Shanghai

RUN set -x \
    # only for users in china to accelerate
    #&& cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    #&& sed  -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list \
    # set timezone to avoid interactive select
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime  \
    && echo ${TZ} > /etc/timezone \
    && apt-get update \
    && apt-get install -y ssh \
      build-essential  \
      git  \
      hexyl \
      pigz \
      strace \
      inotify-tools \
      curl \
      net-tools  \
      lsof  \
      vim  \
      gdb \
      ninja-build \
      rsync \
      tar \
      python \
      libssl-dev \
      zlib1g.dev \
      tree \
      make \
    && apt-get clean
# 安装just
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

RUN ( \
    echo 'LogLevel DEBUG2'; \
    echo 'PermitRootLogin yes'; \
    echo 'PasswordAuthentication yes'; \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
  ) > /etc/ssh/sshd_config_test_clion \
  && mkdir /run/sshd

RUN useradd -m ${USER} \
  && yes ${PASSWD} | passwd ${USER}

RUN usermod -s /bin/bash ${USER}

# set root passwd
RUN echo "root:root" | chpasswd

USER ${USER}

WORKDIR /home/${USER}/${PROJECTDIR}/

# 下载git初始提交代码至/home/{{user}}/目录
RUN git clone https://bitbucket.org/jacobstopak/baby-git.git

USER root

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config_test_clion"]