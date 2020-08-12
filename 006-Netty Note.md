## Netty 模型

![服务端Netty Reactor工作架构图](assets/166e428962949a42)

（1）Netty 会抽象出两组线程池 BoosGroup 专门负责接收客户端的连接， WorkeGroup 专门负责网络的读写 

（2）BoosGroup 和 WorkeGroup 的类型都是 NioEventLoopGroup

（3）NioEventLoopGroup 相当于时间循环组，这个组中包含很多时间循环，每一个事件循环是 NioEventLoop

（4）NioEventLoop 表示一个不断循环的执行处理任务的线程，每个 NioEventLoop 都有一个 selector ，用于监听绑定在器其上的 socket网络

（5）NioEventLoopGroup 可以有多个线程，即可以包含多个 NioEventLoop

（6）每个 BoosNioEventLoop 循环执行的步骤有3步

+ 轮询 accept 事件
+ 处理 accept 事件，与 client 建立连接，生成 NioSocketChannel，并将其注册到某个 worker NioEventLoop 上 selector
+ 处理任务队列的任务

（7）每个 Worker NIOEventLoop 循环执行的步骤


+ 轮询 read write 事件
+ 处理 io 事件，即 read write 事件，在对应的 NioSocketChannel处理
+ 处理任务队列的任务

（8）每个 Worker NIOEventLoop 处理业务时，会使用 pipeline （管道），pipeline 中包含了 channel ，即通过pipline 可以获取对应的通道，管道中维护了很多的处理器   