# first-network-with-tools
Added tape (Chaincode benchmark) and Hyperledger Explorer for first-network v1.4.4 ,and updating

简介：first-network-with-tools 基于Hyperledger Fabric v1.4.4，集成了常用的工具，如tape（对fabric chaincode 进行压测），Hyperledger  Explorer （区块链浏览器，可以查看网络的区块与交易明细），会更新更多工具，可以在此网络基础上搭建自己的应用。

视频步骤：https://www.bilibili.com/video/BV17v4y1q78J

文章包含在专栏：https://blog.csdn.net/qq_41575489/category_12099332.html

环境要求：ubuntu 20.04（或其他Linux发行版）、docker与docker-compose、git。相关教程可以看下专栏内其他文章。

### 使用步骤：

1.克隆本仓库
```bash
git clone https://github.com/realcoooool/first-network-with-tools
```
2.启动网络

```bash
./start.sh
```
3.区块链浏览器
使用浏览器访问：ip:8080

4.对chaincode进行压测
进入tape目录，使用以下命令：

```bash
./tape --config=config.yaml --number=100
```
