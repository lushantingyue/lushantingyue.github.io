---
title: RxJava2.x学习初步总结
date: 2018-01-15 18:40:05
categories: [Android进阶, 技术趋势]
tags: [异步处理, RxJava]
---

[RxJava解决的问题](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2015/0331/2672.html) <br>
I) 使用RxJava2必须明确的几个概念 <br>

1.观察者:Observer，

    监视着被观察者的行为，当被观察者某个状态改变的时候会通知观察者，观察者会执行对应的操作；

2.被观察者:Observable

    被监视的对象，当某个状态改变的时候会通知观察者；

3.订阅.subscribe()

    使观察者和被观察者之间建立联系。

初级用法:

```
Observer ---订阅---> Observable: 通过subscribe()事件 订阅
```

进阶用法:
Subscriber要与Flowable(也是一种被观察者)联合使用

```
Subscriber ---订阅--->Flowable: 通过subscribe()事件 订阅
```

<!--more--> 

关键回调事件:
onCompelte()    成功完成
onError()       出错
onDisposable()  解除订阅

II) Scheduler线程调度器的概念：
在不指定线程的情况下, 遵循线程不变的原则, 即调用/生产/消费在同一线程.
需要使用Scheduler指定执行线程.
常用的API: 
Schedulers.io() 网络/文件读写/数据库读写操作
AndroidSchedulers.mainThread() UI线程, 需配合RxAndroid库

III) Flowable及backpressure策略:
request()方法定义观察者的消费能力;背压事件处理策略Error,Buffer,Drop,Latest

IV) AS3.0版本后直接支持lambda语法,使用lambda表达式简化RxJava

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=298 height=52 src="//music.163.com/outchain/player?type=2&id=460323237&auto=1&height=32"></iframe>