---
title: CentOS7.4 配置Nginx流媒体服务(上)
date: 2018-04-10 16:50:52
categories: [服务器, 音视频]
tags: [nginx, 阿里云, 流媒体]
---
#### 1.环境准备
##### 准备必要的模块:
```
yum install -y gcc gcc-c++  
yum install –y pcre pcre-devel
yum install –y zlib zlib-devel
yum install -y openssl openssl-devel  
```
#### 2.下载nginx及rtmp模块
```
cd /usr/local

wget  http://nginx.org/download/nginx-1.12.2.tar.gz
tar xzvf nginx_1.12.2.tar.gz

git clone git://github.com/arut/nginx-rtmp-module.git
```

##### 3.编译nginx-rtmp
    cd nginx_1.12.2
    ./configure --prefix=/usr/local/nginx --add-module=../nginx-rtmp-module --with-http_stub_status_module --with-http_ssl_module
```
参数说明:
./configure --prefix=/usr/local/nginx	## 目标文件编译到此目录
	--add-module=../nginx-rtmp-module   ## 新添加的rtmp模块
	--with-http_stub_status_module	    ## 模块监控
	--with-http_ssl_module			    ## ssl证书
```
    make & make install

    到此编译完成.

#### 手动开启nginx:
	切换至执行路径 cd /usr/local/nginx/sbin & ./nginx
#### 手动停止nginx:
	./nginx -s stop
#### 查看状态:
	netstat -ltn
	若80端口为启动状态,则为nginx启动状态.

##### 附:也可以通过 yum来统一配置 rtmp-module, 详见 [Nginx官方文档](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/rtmp/)
<!-- more -->