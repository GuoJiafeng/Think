## 基本思路

客户端向服务端发送消息，服务端正常接收的情况下，可以将接受到的消息转发给其他客户端。同时客户端需要新启动线程做监听接受服务端发送的消息（也就是其它客户端发送的消息）。

需要注意的是在代码的编写上需要及时将已经处理过的通道及时清除，另外就是客户端离线的处理，就是通过trycatch块捕捉到是否能从通道中`正常`读取到数据，如果无法正常读取，代码就会进入catch块，然后将该当前的SelectionKey的取消并且将当前通道关闭，然后就可以打印相关的离线消息了。

## 服务端

~~~java
package network.bio.nioserver;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;

public class NIOServer {
    // 定义属性
    private Selector selector;
    private ServerSocketChannel serverSocketChannel;
    private static final int PORT = 6666;

    public NIOServer() {
        try {
            serverSocketChannel = ServerSocketChannel.open();

            selector = Selector.open();

            serverSocketChannel.bind(new InetSocketAddress(PORT));

            serverSocketChannel.configureBlocking(false);

            serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);

        } catch (IOException exception) {
            exception.printStackTrace();
        }
    }

    public void listen() {

        try {

            while (true) {
                int count = selector.select();

                if (count > 0) {

                    Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();

                    while (iterator.hasNext()) {

                        SelectionKey key = iterator.next();

                        if (key.isAcceptable()) {

                            SocketChannel channel = serverSocketChannel.accept();
                            channel.configureBlocking(false);
                            channel.register(selector, SelectionKey.OP_READ);
                            System.out.println(channel.getRemoteAddress() + "上线啦...");
                        }
                        if (key.isReadable()) {

                            readData(key);

                        }
                        iterator.remove();
                    }
                }
            }

        } catch (Exception exception) {
            exception.printStackTrace();
        }

    }


    public void readData(SelectionKey key) {
        SocketChannel channel = null;
        try {
            channel = (SocketChannel) key.channel();

            ByteBuffer byteBuffer = ByteBuffer.allocate(1024);
            int count = channel.read(byteBuffer);
            if (count > 0) {
                String msg = new String(byteBuffer.array());
                System.out.println("from cline :" + msg);

                //channel.register(selector, SelectionKey.OP_WRITE, ByteBuffer.allocate(1024));

                // 在这里接受的到的消息就能向其他的客户端转发

                sendMsgToOtherClients(channel, msg);
            }

        } catch (Exception exception) {

            try {
                System.out.println(channel.getLocalAddress() + "离线了.....");
                key.cancel();
                channel.close();

            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void sendMsgToOtherClients(SocketChannel currentChannel, String msg) {
        try {

            System.out.println("服务器正在转发消息....");

            for (SelectionKey key : selector.keys()) {

                SelectableChannel channel = key.channel();

                if (channel instanceof SocketChannel && channel != currentChannel) {

                    SocketChannel socketChannel = (SocketChannel) channel;
                    ByteBuffer byteBuffer = ByteBuffer.wrap(msg.getBytes());

                    socketChannel.write(byteBuffer);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public static void main(String[] args) {
        NIOServer nioServer = new NIOServer();
        nioServer.listen();
    }
}
~~~

## 客户端

~~~java
package network.bio.nioclient;


import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;

import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Scanner;

public class NIOClient {
    private final String HOST = "127.0.0.1";
    private final Integer PORT = 6666;
    private Selector selector;
    private SocketChannel socketChannel;
    private String username;

    public NIOClient() {
        try {

            selector = Selector.open();
            socketChannel = socketChannel.open(new InetSocketAddress(HOST, PORT));
            socketChannel.configureBlocking(false);
            socketChannel.register(selector, SelectionKey.OP_READ);
            username = socketChannel.getLocalAddress().toString().substring(1);
            System.out.println(username + "is ok !");

        } catch (Exception exception) {

            exception.printStackTrace();
        }

    }

    public void sendMsgToServer(String info) {

        info = username + "说:" + info;
        try {

            socketChannel.write(ByteBuffer.wrap(info.getBytes()));

        } catch (IOException exception) {
            exception.printStackTrace();
        }
    }


    // 从服务端读取消息
    public void readMsgFromServer() {

        try {

            int count = selector.select();

            if (count > 0) {

                Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();

                while (iterator.hasNext()) {

                    SelectionKey key = iterator.next();

                    if (key.isReadable()) {
                        SocketChannel channel = (SocketChannel) key.channel();

                        ByteBuffer byteBuffer = ByteBuffer.allocate(1024);

                        channel.read(byteBuffer);

                        System.out.println(new String(byteBuffer.array(), "UTF-8"));
                    }
                    iterator.remove();
                }

            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        NIOClient nioClient = new NIOClient();
        new Thread() {
            @Override
            public void run() {
                while (true) {
                    nioClient.readMsgFromServer();
                    try {
                        Thread.sleep(3000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        }.start();
        Scanner scanner = new Scanner(System.in);
        while (scanner.hasNextLine()) {
            String s = scanner.nextLine();
            nioClient.sendMsgToServer(s);
        }
    }
}
~~~

