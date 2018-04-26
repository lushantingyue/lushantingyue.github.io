---
title: 阿里云部署Koa项目小结
date: 2018-04-08 17:27:48
categories: [服务器]
tags: [hexo, 阿里云, 建站]
---
参考文档：
[使用yum包管理器安装mongodb3.4.10](https://www.cnblogs.com/layezi/p/7290082.html)
[mongoDB设置远程访问](https://www.cnblogs.com/web424/p/6928992.html)
[CentOS之7与6的区别](http://www.cnblogs.com/Csir/p/6746667.html)

##### yum安装git, 通过git clone下载部署的项目, 执行npm install

##### yum安装 mongoDB 3.4.10, 并配置服务方式开机启动

##### CentOS7下配置MongoDB v3.4.10的注意事项：
###### 由于CentOS7 改用systemctl管理service,请使用
``` 
 systemctl start mongod.service 启动服务
 systemctl status mongod.service 查看服务状态
 systemctl enable mongod.service 可设置开机启动
```
<!-- more -->
##### 导出本地mongodb数据 
```
mongoexport命令:
    切换到 MongoDB/Server/3.4/bin目录, 执行 mongoexport -d DBName -c tblname -o data.json   
    可选导出格式为 .dat .csv .json
```
##### 上传数据库文件
rz命令(Receive ZMODEM), 基于ZMODEM协议; 与之相对应的有, 下载 sz命令(Send ZMODEM).
```
配置:
    yum install lrzsz
执行:    
    直接执行rz, 在弹出的窗口里选择要上传的文件即可.
```
##### 导入mongoDB数据
```
在数据所在文件夹, 执行 mongoimport -d DBName -c tblname data.json
```
##### 配置安全组规则，允许3000端口被访问
```
npm run start启动项目后, 发现无法在PC端访问项目, 经检查发现必须配置安全组规则：
安全组规则->入方向 授权策略:允许, 端口范围3000/3000, 授权类型:地址段访问, 授权对象: 0.0.0.0/0
```