# PaoPao DNS docker
![PaoPaoDNS](https://th.bing.com/th/id/OIG.0FtL40H4krRLeooEGFpu?w=220&h=220&c=6&r=0&o=5&pid=ImgGn)    
![pull](https://img.shields.io/docker/pulls/sliamb/paopaodns.svg) ![size](https://img.shields.io/docker/image-size/sliamb/paopaodns)   
![Docker Platforms](https://img.shields.io/badge/platforms-linux%2F386%20%7C%20linux%2Famd64%20%7C%20linux%2Farm%2Fv6%20%7C%20linux%2Farm%2Fv7%20%7C%20linux%2Farm64%2Fv8%20%7C%20linux%2Fppc64le%20%7C%20linux%2Friscv64%20%7C%20linux%2Fs390x-blue)

泡泡DNS是一个能一键部署递归DNS的docker镜像，它使用了unbound作为递归服务器程序，使用Redis作为底层缓存，此外针对China大陆，还有智能根据CN分流加密查询的功能，也可以自定义分流列表，可以自动更新IP库，分流使用了mosdns程序，加密查询使用dnscrypt程序，针对IPv4/IPv6双栈用户也有优化处理。   
泡泡DNS适合的使用场景：  
- 场景一：仅作为一个纯粹准确的递归DNS服务器，作为你其他DNS服务程序的上游，替代`114.114.114.114`,`8.8.8.8.8`等公共DNS上游
- 场景二：作为一个局域网内具备CN智能分流、解决污染问题和IPv6双栈优化的DNS服务器，或者你的局域网已经从IP层面解决了“科学”的问题，需要一个能智能分流的DNS服务器。  

## [→详细说明《为啥需要递归DNS》/运行逻辑](https://blog.03k.org/post/paopaodns.html)
## 使用方法
简单来说，那么你可以运行：  
```shell
#拉取最新的docker镜像
docker pull sliamb/paopaodns:latest
#假设你的数据要放在/home/mydata
docker run -d \
--name paopaodns \
-v /home/mydata:/data \
-e CNAUTO=yes \
--restart unless-stopped \
-p 53:53/tcp -p 53:53/udp \
sliamb/paopaodns
```
如果你需要容器运行在同一个局域网段而不是单独映射端口，除了一些NAS有现成的界面点点点，原生docker你可以考虑使用macvlan如下的配置(假设你的网络是192.168.1.0/24)：  
```shell
# 启用eth0网卡混杂模式
ip link set eth0 promisc on
# 创建macvlan网络
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 macvlan_eth0
#拉取最新的docker镜像
docker pull sliamb/paopaodns:latest
# 运行容器并指定IP
docker run -d \
--name paopaodns \
-v /home/mydata:/data \
-e CNAUTO=yes \
--restart unless-stopped \
--network macvlan_eth0 --ip 192.168.1.8 \
sliamb/paopaodns
```
验证你的递归DNS正常运行(假设你的容器IP是192.168.1.8)，可以执行以下命令：   
```cmd
>nslookup -type=TXT whoami.ds.akahelp.net 192.168.1.8
服务器:  PaoPaoDNS,blog.03k.org
Address:  192.168.1.8

非权威应答:
whoami.ds.akahelp.net   text =

        "ns"
        "116.31.123.234"  #连接权威DNS服务器的IP=你的宽带IP
Linux可使用dig命令：  
dig whoami.ds.akahelp.net @192.168.1.8 txt -p53
```  
或者，你可以使用03k.org的服务：  
```cmd
>nslookup whoami.03k.org 192.168.1.8
服务器:  PaoPaoDNS,blog.03k.org
Address:  192.168.1.8

非权威应答:
名称:    whoami.03k.org
Address:  116.31.123.234 #连接权威DNS服务器的IP=你的宽带IP
```
如果返回的IP和你宽带的出口IP一致的话，说明你的递归DNS服务正常运作了。 
   
验证CNAUTO的功能：  
```cmd
# 淘宝有全球CDN，可以用来检测分流
>nslookup www.taobao.com 192.168.1.8
服务器:  PaoPaoDNS,blog.03k.org
Address:  192.168.1.8

非权威应答:
名称:    www.taobao.com.danuoyi.tbcache.com
Addresses:  113.96.179.242 #此处返回的IP应该是CN IP
          113.96.179.243
Aliases:  www.taobao.com
可以把IP用这个网页ping看看是哪里的IP：
https://ping.chinaz.com/
```   
需要注意的是，如果你的网络有“自动分流IP”的功能，请把容器的IP加入不分流的名单，因为权威DNS需要准确的IP去判断，IP分流会影响权威DNS的判断。此外，一些软路由存在劫持DNS请求的情况，解决办法参见[这个issue](https://github.com/kkkgo/PaoPaoDNS/issues/2#issuecomment-1504708367)。    

## 参数说明
环境变量参数如下：  
环境变量|默认值|可用值|
-|-|-|
CNAUTO|`yes`|`yes`,`no`|
DNSPORT|`53`|端口值|
DNS_SERVERNAME|`PaoPaoDNS,blog.03k.org`|不含空格的英文字符串|
SOCKS5|空，非必须。|如：`10.10.10.8:7890`|
TZ|`Asia/Shanghai`|tzdata时区值|
UPDATE|`weekly`|`no`,`daily`,`weekly`,`monthly`|
IPV6|`no`|`no`,`yes`|
CNFALL|`yes`|`no`,`yes`|
CUSTOM_FORWARD|空，可选功能|`IP:PORT`,如`10.10.10.3:53`|
SAFEMODE|`no`|`no`,`yes`|

用途说明：
- CNAUTO：是否开启CN大陆智能分流，如果位于境外可配置为no
- DNSPORT：设置DNS服务器端口，仅在CNAUTO=no时生效
- DNS_SERVERNAME：DNS的服务器名称，你使用windows的nslookup的时候会看到它。注意，该选项仅在容器的网卡IP和外部网卡IP一致的时候生效（比如macvlan）。    
- SOCKS5：为分流非CN IP的域名优先使用SOCKS5查询，但没有也能查，非必须项。仅在CNAUTO=yes时生效
- TZ: 设置系统的运行时区，仅影响输出日志不影响程序运行
- UPDATE: 检查更新根域数据和GEOIP数据的频率,no不检查,其中GEOIP更新仅在CNAUTO=yes时生效。注意：`daily`,`weekly`,`monthly`分别为alpine默认定义的每天凌晨2点、每周6凌晨3点、每月1号凌晨5点。更新数据后会瞬间完成重载。
- IPV6： 仅在CNAUTO=yes时生效，是否返回IPv6的解析结果，默认为no，设置为yes返回IPv6的查询。如果没有IPv6环境，选择no可以节省内存。
- CNFALL: 仅在CNAUTO=yes时生效，在遇到本地递归网络质量较差的时候，递归查询是否回退到转发查询，默认为yes。配置为no可以保证更实时准确的解析，但要求网络质量稳定（尽量减少nat的层数），推荐部署在具备公网IP的一级路由下的时候设置为no； 配置为yes可以兼顾解析质量和网络质量的平衡，保证长期总体的准确解析的同时兼顾短时间内网络超时的回退处理。  旁  
- CUSTOM_FORWARD: 将`force_forward_list.txt`内的域名列表转发到到`CUSTOM_FORWARD`DNS服务器。该功能可以配合第三方旁网关的`fakeip`或者`域名嗅探`特性完成简单的域名分流效果。        
- SAFEMODE： 安全模式，仅作调试使用，内存环境存在问题无法正常启动的时候尝试启用。   

可映射TCP/UDP|端口用途
|-|-|
53|提供DNS服务的端口，在CNAUTO=no时数据直接来自unbound，CNAUTO=yes时数据来自mosdns
5301|在CNAUTO=yes时，递归unbound的端口，可用于dig调试
5302|在CNAUTO=yes时并设置了SOCKS5时，走SOCKS5的dnscrypt服务端口，可用于dig调试
5303|在CNAUTO=yes时，原生dnscrypt服务端口，可用于dig调试
5304|在CNAUTO=yes时，dnscrypt的底层unbound实例缓存，可用于dig调试  

挂载共享文件夹`/data`目录文件说明：存放redis数据、IP库、各种配置文件，在该目录中修改配置文件会覆盖脚本参数，如果你不清楚配置项的作用，**请不要删除任何注释**。如果修改任何配置出现了异常，把配置文件删除，重启容器即可生成默认文件。  

- `redis.conf`：redis服务器配置模板文件，修改它将会覆盖redis运行参数。除非你熟知自己在修改什么，一般强烈建议不修改它。
- `redis_dns.rdb`：redis的缓存文件，容器重启后靠它读取DNS缓存。刚开始使用的时候因为递归DNS有一个积累的过程，一开始查询会比较慢(设置了CNFALL=no的话，如果CNFALL=yes查询速度不会低于公共DNS)，等到这个文件体积起来了就很流畅了。    
注意：redis_dns.rdb文件生成需要累积达到redis的最持久化要求，取决于`redis.conf`的配置，默认最低2小时后才会进行一次持久化操作。如果你升级容器的镜像，可以删除其他所有配置文件而保留这个rdb文件。         
- `unbound.conf`：Unbound递归DNS的配置模板文件，除非你有高级的自定义需求，一般不需要修改它。  
**以下文件仅在开启CNAUTO功能时出现：**  
- `dnscrypt-resolvers`文件夹：储存dnscrypt服务器信息和签名，自动动态更新。
- `Country-only-cn-private.mmdb`：CN IP数据库，自动更新将会覆盖此文件。
- `dnscrypt.toml`：dnscrypt配置模板文件，修改它将会覆盖dnscrypt运行参数。除非你熟知自己在修改什么，一般不用修改它。
- `force_cn_list.txt`：强制使用本地递归服务器查询的域名列表，一行一条，语法规则如下：  
以`domain:`开头域匹配: `domain:03k.org`会匹配自身`03k.org`，以及其子域名`www.03k.org`, `blog.03k.org`等。   
以`full:`开头，完整匹配，`full:03k.org` 只会匹配自身。完整匹配优先级更高。     
以`regxp:`开头，正则匹配，如`regexp:.+\.03k\.org$`。[Go标准正则](https://github.com/google/re2/wiki/Syntax)。   
以`keyword:`开头匹配域名关键字，如以`keyword: 03k.org`会匹配到`www.03k.org.cn`   
尽量避免使用regxp和keyword，会消耗更多资源。同一文本内匹配优先级：`full > domain > regexp > keyword`     
- `force_nocn_list.txt`：强制使用dnscrypt加密查询的域名列表，匹配规则同上。   
- `force_forward_list.txt`： 仅在配置`CUSTOM_FORWARD`有效值时生效，强制转发到`CUSTOM_FORWARD`DNS服务器的域名列表，匹配规则同上。   
- 修改`force_cn_list.txt`或`force_nocn_list.txt`或`force_forward_list.txt`将会实时重载生效。文本匹配优先级`force_forward_list > force_nocn_list > force_cn_list`。
- `mosdns.yaml`：mosdns的配置模板文件，修改它将会覆盖mosdns运行参数。除非你熟知自己在修改什么，一般强烈建议不修改它。
### 进阶自定义
暂时没有什么高级的自定义需求，如果有的话欢迎写在[评论](https://github.com/kkkgo/PaoPaoDNS/discussions)里面，我会回复如何修改配置。   
这里说一个在企业内可能需要的一个功能，就是需要和AD域整合，转发指定域名到AD域服务器的方法：
打开`/data/unbound.conf`编辑，滚动到最后几行，已经帮你准备好了配置示例，你只需要取消注释即可：
```yaml
#Active Directory Forward Example
# 在这个示例中，你公司的AD域名为company.local，有四台AD域DNS服务器。
forward-zone:
 name: "company.local"
 forward-no-cache:yes
 forward-addr: 10.111.222.11
 forward-addr: 10.111.222.12
 forward-addr: 10.111.222.13
 forward-addr: 10.111.222.14

```
## 附赠：PaoPao-Pref
这是一个让DNS服务器预读取缓存或者压力测试的简单工具，配合[PaoPaoDNS](https://github.com/kkkgo/PaoPaoDNS)使用可以快速生成`redis_dns.rdb`缓存。从指定的文本读取域名列表并查询A/AAAA记录，docker镜像默认自带了全球前100万热门域名(经过无效域名筛选)。     
详情：https://github.com/kkkgo/PaoPao-Pref    


## 构建说明
`sliamb/paopaodns`Docker镜像由Github Actions自动构建本仓库代码构建推送，你可以在[Actions](https://github.com/kkkgo/PaoPaoDNS/actions)查看构建日志，或者自行下载源码进行构建，只需要执行docker build即可，或者可以fork仓库然后使用Actions进行自动构建。   

## 附录：使用到的程序
unbound：
- https://nlnetlabs.nl/projects/unbound/about/  
- https://www.nlnetlabs.nl/documentation/unbound/howto-optimise/
- https://unbound.docs.nlnetlabs.nl/en/latest/

redis: https://hub.docker.com/_/redis  
dnscrypt:
- https://github.com/DNSCrypt/dnscrypt-proxy   
- https://github.com/DNSCrypt/dnscrypt-resolvers
- https://dnscrypt.info/  

mosdns:
- https://github.com/kkkgo/mosdns

GEOIP:
- https://github.com/Loyalsoldier/geoip
