---
title: CentOS7.4 配置Nginx流媒体服务(下)
date: 2018-04-10 17:01:07
categories: [服务器, 音视频]
tags: [nginx, 阿里云, 流媒体]
---
#### 修改Nginx的配置文件
```
进入            cd /usr/local/nginx/conf 路径
修改配置文件     vi nginx.conf
在底部加入这段配置代码

rtmp {                #RTMP服务
    server {
        listen 1935;		# 服务端口
        chunk_size 4096;	# 数据传输块的大小

        application live {	# 直播
            live on;
	        record off;	# 禁止录制流
        }        
    }
}  
:wq 保存并退出

测试nginx配置:
    cd .. & ./sbin/nginx -t
    提示syntax is ok 和 test is successful

重启服务:
    ./sbin/nginx -s reload
``` 
##### 添加阿里云安全组规则, 允许本地访问 1935端口
    配置完成后, 可在pc端通过 telnet serverIP 1935 测试

#### 直播推流/拉流 测试    
    PC端使用 OBS Studio推流,
        填入:URL:rtmp://server_ip:1935/live 流名称:mylive
    打开 Wowza网页测试地址(https://www.wowza.com/testplayers)进行拉流,
        填入Server:server_ip:1935 Stream:mylive Application:live 
    也可以使用VLC播放器拉流,但加载延迟较大,这种测试方法不建议使用:
        打开网络串流,在URL栏输入: rtmp://server_ip:1935/live/mylive 即可,VLC端测试会稍慢,耐心等待其缓冲数十秒即可.
    
#### android端拉流/播放测试
    ijkplayer的使用

#### 配置点播服务
    下载并解压 nginx_mod_h264_streaming-2.2.7.tar.gz
        wget http://h264.code-shop.com/download/nginx_mod_h264_streaming-2.2.7.tar.gz & tar -xzvf nginx_mod_h264_streaming-2.2.7
    
    切换至nginx-1.12.2文件夹, 按上篇提到的方法引入mp4_module和flv_module添加并配置:
    --with-http_mp4_module
    --with-http_flv_module # mp4和flv点播模块
    --add-module=../nginx-mod_h264_streaming-2.2.7  # 引入h264模块

    编辑objs下的makefile配置文件(以解决h264_streaming模块make报 set but not use的错误, 注意这一步必须在 ./configure后面操作):
        vim objs/Makefile (修改objs/Makefile文件, 去掉其中的"-Werror")
    
    重新 make (因为非首次安装无需make install)
    此处有坑, 参考解决 [关于ngx_http_streaming_module.c:158行报错解决方法](https://blog.csdn.net/a454213722/article/details/53446495)
<!-- more -->
##### 相关nginx.conf配置
    在 server {
        listen 80
        ...
        ...
    } 内部添加

    # 对请求路径进行正则匹配, 映射至相应路径
	location ~ \.flv$ {
	    root /usr/local/nginx/html/media/;
	    flv;
	}

	location ~ \.mp4$ {
	    root /usr/local/nginx/html/media/;
	    mp4;
	}

	location /hls {
	    alias hls;
	    types {
		application /vnd.apple.mpegurl m3u8;
		video /mp2t ts;
	    }
	    add_header Cache-Control no-caches;
	    expires -1;
	}

    在 rtmp {
        server {
            ...
        }
    } 内部添加: 
    
    application hls {		# 与hls拉流端关联的直播流
	    live on;
	    hls on;			# 打开点播,会生成临时文件
	    hls_path /tmp/hls;		# 临时文件保存路径
        hls_fragment 8s;        # 缓存片段时长
	}

    application vod_media {       # 视频文件点播
	    play /usr/local/nginx/html/media; # 视频文件存放位置; vod被调用时会直接到该地址寻找媒体文件
	}


    重启 nginx服务后,
    在浏览器打开网址 http://server_ip/name.mp4 此访问方式由 location 正则表达式{ } 控制匹配访问路径
    在Wowza网页测试地址, 选择rtmp流, 选择VOD, 填入:Server:server_ip:1935 Application:vod_media Stream:filename.mp4
    点击start按钮,即可播放.

#### 安装编译ffmpeg过程  附:[官方编译指南解决](https://trac.ffmpeg.org/wiki/CompilationGuide/Centos)
- 其余参考:[在CentOS上编译安装FFmpeg](http://www.yaosansi.com/post/ffmpeg-on-centos/)
-    手动编译的话，请以官方FFmpeg编译指南为准, 以下是对自己的编译过程的记录

    有两种安装方式：
        1.yum管理器 + 第三方yum-repos安装,优点: 操作简便
        2.手动编译,优点: 个性化配置, 这里我选择的手动编译
    
    后面编译ffmpeg的过程需要依赖 yasm,nasm
        yum install -y yasm

        wget https://www.nasm.us/pub/nasm/releasebuilds/2.13.03/nasm-2.13.03.tar.xz
        xz -d nasm-2.13.03.tar && tar -zvf nasm-2.13.03.tar && cd nasm-2.13.03
        ./configure --prefix=/usr/local
        make && make install
    
    mkdir ffmpeg_sources  // 用于存放ffmpeg相关软件包
<!-- 
    wget http://www.ffmpeg.org/releases/ffmpeg-3.0.11.tar.xz    // FFmpeg 3.0.11 "Einstein"
    xz -d ffmpeg-3.0.11.tar.xz && tar -xvf ffmpeg-3.0.11.tar
    mv ffmpeg-3.0.11 ffmpeg_sources && cd ffmpeg_sources/ffmpeg-3.0.11
     -->
    准备ffmpeg源码包
        cd ffmpeg_sources && git clone https://github.com/FFmpeg/FFmpeg.git
        mkdir ffmpeg-latest 
        mv ffmpeg-master ffmpeg-latest && rm ffmpeg-master -rf
        cd ffmpeg-latest 

    配置ffmpeg预备模块
        
    * 安装 x264(选择了github版本stable分支) *H.264 编码器

        git clone https://github.com/mirror/x264/tree/stable.git 
        git checkout -b stable
        cd x264
        ./configure --prefix=usr/local/ffmpeg" --bindir=/usr/local/bin --enable-static
        make & make install(注1:此处可能有坑)

        make distclean

    * 安装 x265 * H.265/HEVC编码器
    x265的编译需要使用cmake: 
        yum install -y cmake
    
    wget http://ftp.videolan.org/pub/videolan/x265/x265_2.7.tar.gz
    tar -xzvf x265_2.7.tar.gz
    cd x265_2.7/build/linux
    cmake -G "Unix Makefiles" \
          -DCMAKE_INSTALL_PREFIX=/usr/local/ffmpeg \
          -DENABLE_SHARED:bool=off ../../source
    make && make install

    * 安装 libfdk_aac * AAC音频编码器，Fraunhofer FDK AAC Library

    配置autoconf
        cd /usr/local
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz \ 
        && tar -xzvf autoconf-latest.tar.gz 
        cd autoconf-2.69
        ./configure --prifix=/usr/local
        make && make install && make distclean

    配置automake
        cd /usr/local
        wget http://ftp.gnu.org/gnu/automake/automake-1.16.tar.xz
        xz -d automake-1.16.tar.xz
        tar -xvf automake-1.16.tar
        cd automake-1.16
        ./configure --prefix=/usr/local/bin
        make && make install

    配置libtool
        wget http://mirror.keystealth.org/gnu/libtool/libtool-2.4.tar.gz
        tar -xvzf libtool-2.4.2.tar.gz
        cd libtool-2.4.2
        ./configure --prefix=/usr/local/bin
        make && sudo make install 

    cd ~/ffmpeg_sources
    git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
    cd fdk-aac
    autoreconf -fiv
    ./configure --prefix=/usr/local/ffmpeg --enable-shared
    make & make install
    make distclean

    * 安装 libmp3lame * Mp3音频编码器 
    wget http://sourceforge.mirrorservice.org/l/la/lame/lame/3.100/lame-3.100.tar.gz
    tar zxf lame-3.100.tar.gz && cd lame-3.100
    ./configure --prefix=/usr/local/ffmpeg --bindir=/usr/local/bin --enable-shared --enable-nasm
    make && make install
    make distclean

    * 安装 libopus * Opus 音频编解码器  
    尝试过v1.0.3版, make失败, 原因是缺失test-driver
    最后选用最新版本 v1.2.1
    wget https://archive.mozilla.org/pub/opus/opus-1.2.1.tar.gz 
    tar -xzvf opus-1.2.1.tar.gz && cd opus-1.2.1
    autoreconf -fiv
    libtoolize -f
    ./configure --prefix="/usr/local/ffmpeg" --disable-shared
    make && make install
    make distclean

    * 安装 libogg库 * libogg是Ogg流库，libtheora、libvorbis需要libogg库，speex需要它。
    curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
    tar xzvf libogg-1.3.2.tar.gz
    cd libogg-1.3.2
    ./configure --prefix="/usr/local/ffmpeg" --disable-shared
    make && make install
    make distclean

    * 安装 libvorbis库 * Vorbis音频编码器，需要libogg库
        wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
        tar xzvf libvorbis-1.3.4.tar.gz
        cd libvorbis-1.3.4

        LDFLAGS="-L/usr/local/ffmeg/lib" CPPFLAGS="-I/usr/local/ffmpeg/include" ./configure --prefix="/usr/local/ffmpeg" --with-ogg="/usr/local/ffmpeg" --disable-shared 
        make && make install
        make distclean

    * 安装 libvpx * VP8/VP9视频编码器
        git clone --depth 1 http://git.chromium.org/webm/libvpx.git
        cd libvpx
        ./configure --prefix="/usr/local/ffmpeg" --enable-examples
        make && make install
        make clean

    编译ffmpeg, 链接相关模块
    PKG_CONFIG_PATH="/usr/local/ffmpeg/lib/pkgconfig" \
    ./configure --prefix=/usr/local/ffmpeg \
    --extra-cflags="-I/usr/local/ffmpeg/include" \
    --extra-ldflags="-L/usr/local/ffmpeg/lib"\
    --extra-libs=-lpthread \
    --extra-libs=-lm \
    --bindir="/usr/local/bin" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-libfdk_aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265
        
    编译ffmpeg
        ./configure --prefix=/usr/local/ffmpeg
        make & make install

    在最后PATH添加环境变量：
        PATH=$PATH:/usr/local/ffmpeg/bin
        export PATH
    保存并退出

    source /etc/profile   刷新激活设置
    ffmpeg -version       查看ffmpeg版本
    至此ffmpeg环境配置完成.
    
##### 编译过程报错问题解决：
>* x265编译报错   ERROR: x265 not found using pkg-config	需要配置pkg-config
    最终解决办法: ffmepg编译时需要添加以下三项
--pkg-config-flags="--static" \     # 指定pc文件路径
--extra-libs=-lpthread \            # x265模块依赖pthread库
--extra-libs=-lm \                  # lamemp3模块依赖该数学函数库

#### ffmpeg流媒体处理
##### ffmpeg命令行生成 m3u8/ts流
---
[配置ngnix实现HLS m3u8点播](https://blog.csdn.net/sunxiaopengsun/article/details/69537302?locationNum=8&fps=1)

[HLS点播 FFmpeg udp视频流](https://blog.csdn.net/xdwyyan/article/details/44957125)

[使用ffmpeg转码m3u8并播放](https://blog.csdn.net/psh18513234633/article/details/79312607)

[ffmpeg转换mp4到flv的命令](https://blog.csdn.net/machh/article/details/78647461)

###### flv支持关键帧, 实现进度条拖动播放
- 下载yamdi-1.9
- wget http://sourceforge.mirrorservice.org/y/ya/yamdi/yamdi/1.9/yamdi-1.9.tar.gz
- tar -xzvf yamdi-1.9.tar.gz
- cd yamdi-1.9
- make && make install

- yamdi 给flv添加关键帧: yamdi -i test.flv -o test2.flv -c "Test"
- ffmpeg给mp4添加关键帧: ffmpeg -i test.mp4 -metadata title="Test" -metadata artist="Test" -metadata date="1995" -acodec copy -vcodec copy test2.mp4

- [HTTP方式播放FLV/mp4：nginx+Yamdi/MP4BOX](http://jingpin.jikexueyuan.com/article/48715.html)    

#### nginx向移动端推流
    转m3u8流  -->  iOS 端拉流
    转rtsp流  -->  android 端拉流

#### android端播放
    ijkplayer
    
    - 待续 -

<!-- >* 注1:18-Jan-2018版本 此处有一个bug,make过程中报错
<pre>In file included from common/opencl.c:116:0:
./common/oclobj.h:4682:1: error: expected expression before ‘static’
static const char x264_opencl_source_hash[] = {
^</pre>
    解决：找到 ~/x264/common/oclobj.h,vi命令打开找到最底部会发现一个段头尾重复代码
    去除掉上下包裹的两段 <pre>static const char x264_opencl_source_hash[] = {</pre>和
    <pre>0x37, 0x39, 0x65, 0x63, 0x62, 0x30, 0x39, 0x39, 0x65, 0x34, 0x37, 0x34, 0x38, 0x62, 0x35, 0x66, 0x37, 0x34, 0x38, 0x35, 0x62, 0x33, 0x30, 0x37, 0x38, 0x66, 0x37, 0x38, 0x31, 0x31, 0x31, 0x30, 0x00 };</pre> -->