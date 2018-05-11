---
title: Heroku部署docker容器应用
date: 2018-05-11 15:06:07
tags: [Heroku, Docker]
categories: [服务器, 文章翻译, Docker]
---
[原文地址](https://devcenter.heroku.com/articles/container-registry-and-runtime#testing-an-image-locally)
容器镜像服务(Container Registry)与运行时(Docker部署)
Heroku容器镜像服务允许你部署你的基于Docker的应用至Heroku平台. 公共运行时和私有空间均支持.

##### 起步
请确认你已经安装好Docker (eg. docker ps) 并且已经登陆Heroku (heroku login).

登陆容器镜像服务:
```
    $ heroku container:login
```
克隆一份样例代码 Alpine-based python example:
```
    $ git clone https://github.com/heroku/alpinehelloworld.git
```
切换到应用的目录，接着创建一个Heroku应用:
```
    $ heroku create
    Creating salty-fortress-4191... done, stack is cedar-14
    https://salty-fortress-4191.herokuapp.com/ | https://git.heroku.com/salty-fortress-4191.git
```
构建镜像并推送至容器镜像平台:
```
    $ heroku container:push web
```
现在可以在浏览器打开你的应用了:
```
    $ heroku open    
```

##### 登陆容器镜像服务(registry)
Heroku runs a container registry on registry.heroku.com.
如果你使用的是Heroku CLI, 使用以下语句登陆:
```
    $ heroku container:login
```
或者直接使用Docker CLI:
```
    $ docker login --username=_ --password=$(heroku auth:token) registry.heroku.com
```

##### 推送一个镜像(镜像组)

###### 1.构建并推送镜像
请先确认你的目录里面包含Dockerfile文件，然后运行:
```
    $heroku container:push <process-type>
```

###### 2.推送已存在的镜像
例如从Docker Hub拉取一个已有镜像，打上Tag便签然后以这样的命名格式语句推送
```
    $ docker tag <image> registry.heroku.com/<app>/<process-type>
    $ docker push registry.heroku.com/<app>/<process-type>
```
当镜像成功推送后，使用以下语句查看:
```
    $ heroku open -a <app>
```

###### 3.推送多个镜像
以这样的格式重命名你的Dockerfile: Dockerfile.<process-type>:
```
    $ ls -R

    ./webapp:
    Dockerfile.web

    ./worker:
    Dockerfile.worker

    ./image-processor:
    Dockerfile.image
```
然后，在工程的根目录运行:
```
    $ heroku container:push --recursive
    === Building web
    === Building worker
    === Building image
    === Pushing web
    === Pushing worker
    === Pushing image
```
这里会构建并推送3个镜像. 如果你想只推送特定的镜像, 可以通过标注 process types:
```
    $ heroku container:push web worker --recursive
    === Building web
    === Building worker
    === Pushing web
    === Pushing worker
```
##### 一次性dynos(One-off dynos)
如果你的应用程序是由多个Docker镜像组成的，在创建独立的一次性dyno时，可以指定操作类型
```
    heroku run bash --type=worker
    Running bash on multidockerfile... up, worker.5180
```
当没有指定类型时, 默认使用的是 web镜像.

##### 使用第三方 CI/CD平台
当前还不支持使用Heroku CI服务来测试容器的构建.

如果你在使用第三方的 CI/CD platform, 你可以把镜像推送到容器镜像服务(registry).首先要登陆验证一下信息:
Registry URL: registry.heroku.com
Username: 你的Heroku email address
Email:    你的Heroku email address
Password: 你的Heroku API key
关于 构建并推送镜像至 Docker registry的方法，请参阅CI/CD 提供商的相关文档:
CircleCI
Bamboo
[TravisCI](https://docs.travis-ci.com/user/docker/#Pushing-a-Docker-Image-to-a-Registry)
Jenkins
Codeship

##### Dockerfile命令和(构建期)运行时环境
当你运行推送Docker镜像至容器服务平台，该镜像会即时地被发行至Heroku app. 
Heroku Docker镜像是用buildpack构建的功能块.Docker镜像以同样的方式运行在dynos上，有以下约束条件：

- The web process必须监听HTTP流量端口$PORT,该参数由Heroku指定. Dockerfile中的EXPOSE指令不被采纳, 但是仍然可以在本地测试中使用. 只有HTTP请求是被支持的(HTTPS端口不被支持).
- dynos间的网络连接不被支持.
- 临时性的文件系统.
- 默认工作目录在 /. 你可以使用 WORKDIR语句设置到别的工作目录.
- ENV 环境参数命令 被支持.
- 我们建议使用ENV作为运行时变量(e.g., GEM_PATH)，而heroku配置参数作为认证,以避免敏感的验证信息不被意外暴露在源码里面.
- ENTRYPOINT 可选用. 如果不设置, 使用的是 /bin/sh -c
- CMD 是必须项. 如果CMD没有写, 镜像容器平台会报错
- CMD 总是被shell执行以确保配置参数被进程有效使用;如果想要单独执行脚本或者不使用shell执行镜像请使用entrypoint

##### 本地环境测试镜像
关于在本地环境测试镜像这里有一些[最佳实践的例子](https://github.com/heroku/alpinehelloworld/blob/master/Dockerfile).

##### 以非root用户运行镜像
我们强烈要求以非root用户在本地测试镜像，因为在Heroku中容器不会在root权限下运行.
在CMD语句前添加以下命令到你的Dockerfile中:

如果使用的是 Alpine:
```
    RUN adduser -D myuser
    USER myuser
```
如果使用的是 Ubuntu:
```
    RUN useradd -m myuser
    USER myuser
```
为了确认你的容器是运行在非root用户环境，attach方式进入正在运行的容器 然后运行 whoami命令:
```
    $docker exec <container-id> bash
    $ whoami
    myuser
```
当完成部署至Heroku操作, 我们一样可以以非root用户方式运行你的容器(尽管我们并没有在Dockerfile里面声明用户组).
```
    $ heroku run bash
    $ whoami
    U7729
```

###### 从环境变量里获取端口
基于测试的目的，我们建议为了让你的Dockerfile或者代码读取到$Port环境变量，例如：
```
    CMD gunicorn --bind 0.0.0.0:$PORT wsgi
```

当需要从本地运行容器, 请设置环境变量 使用 -e 标志:
```
$ docker run -p 5000:5000 -e PORT=5000 <image-name>
```

###### 设置多个环境变量
当在本地使用heroku时, 可以使用.env文件里声明变量. 当heroku本地运行时.env文件会被读取，每个键值对会被设置进环境变量里面. 
运行Docker时你可以使用相同的.env文件:
```
$ docker run -p 5000:5000 --env-file .env <image-name>
```

我们建议在.dockerignore文件里忽略.env文件.

###### 利用 Docker Compose工具构建多容器复合应用
如果你已经创建好了多容器复合应用， 
你可以使用 Docker Compose来定义你的本地开发环境.
请学习如何使用Docker Compose来构建本地环境.

###### 更多
更多关于Docker镜像本地运行的信息请参阅[Docker官方文档](https://docs.docker.com/engine/reference/run/).
更多关于[Docker Compose构建本地开发环境](https://devcenter.heroku.com/articles/local-development-with-docker-compose).

##### 基础镜像栈
Cedar-14 和 Heroku-16都很适合作为 Docker镜像. 然而, 你可以随意选择你想要的镜像 – using a Heroku stack image is not required. 如果选用Heroku镜像 我们建议选用 Heroku-16 (465.3 MB), 它的资源占用远小于 Cedar-14.
选用Heroku-16 在你的Dockerfile的基础镜像，请这样写:
    FROM heroku/heroku:16
拉取最新镜像
如果你已经采用Heroku-16做基础镜像部署过你的应用, 想更新至最新版本(通常包括安全更新), 请这样运行:
    $ docker pull heroku/heroku:16
再重新部署你的应用.

##### 变更部署方法
如果你已经通过镜像服务平台部署过应用, 栈已经被配置上容器. 
这意味着你的应用不再使用Heroku-curated栈, 而是以你的自定义容器代替之.
只要配置好容器通过git推送应用的方式被弃用. 
如果你不再希望通过Container Registry发布你的应用, 而是使用git方式代替，请运行 
    heroku stack:set heroku-16.

##### 使用须知及相关限制
不支持预览应用. 想要使用该项功能, 请试用最新的 heroku.yml build manifest, 其提供在Heroku上构建Docker镜像的支持.
While Docker images are not subject to size restrictions (unlike slugs), they are subject to the dyno boot time restriction. 
As layer count/image size grows, so will dyno boot time.
镜像超过40 layers 可能引起在the Common Runtime启动失败 
不支持Pipeline promotions.
不支持Release phase.
不支持The commands listed here.    

##### 相关概念
Stack的概念: 是应用运行的基础环境的Docker镜像，Heroku当前提供三种基础镜像栈: Cedar-14, Heroku-16, and Heroku-18.
dynos: 所有的Heroku应用运行在一个轻量级的Linux容器组成的集群上面,这个集群称为dynos,扩展灵活.