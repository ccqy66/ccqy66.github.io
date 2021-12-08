---
title: 为什么会存在IO多路复用?
date: 2021-11-30 18:42:32
tags: [IO多路复用, 网络IO]
index_img: /img/io_multiplexing/multiplexing_demultiplexing.webp
categories:
- 计算机网络
---
&emsp;&emsp;在网络编程中，IO多路复用是一个绕不过的话题。例如常见的实现`select` `poll`和`epoll`，以及unix平台下的`kevent`。本文会通过网络IO模型发展入手，为大家解释为什么会有IO多路复用的存在，以及是为了解决什么问题。帮助大家快速理解IO多路复用的高效之处。
<img src="/img/io_multiplexing/io_struct.png" width="80%" height="50%">
<center>IO多路复用各平台实现</center>

### IO模型发展

#### 阻塞IO
<img src="/img/io_multiplexing/io_blocking.png">
&emsp;&emsp;阻塞IO是最简单，也是最原始的一种IO模型，使用这种模型，用户态应用程序读取网络数据时每次都会一直等待，直到读到数据。一次完整IO耗时可以分为大致两部分：1)等待数据到来；2)将网络数据从内核态拷贝到用户态。

&emsp;&emsp; 通常采取下面的方式来处理阻塞IO：有一个线程用来接收客户端的连接。当完成了三次握手之后，会为每一个连接创建一个新的线程，在新的线程中处理消息。正常情况下这种模式会运行的很好，但是当并发高起来后，随着连接增多，线程增多，服务会逐渐到达瓶颈。
```go
func server() {
	for(;;) {
	    conn := accept()              // accept a new connection
        go func(conn) {
            message := recvfrom(conn) // receive message from conn: blocking!!!
		    handleMessage(message)    // handle message after finishing reviving
        }
    }
}
```
&emsp;&emsp;这种IO模型有瓶颈的原因就在于：会为每一个连接分配一个线程，这个线程只有连接断开才会销毁，即便当前连接并没有数据传输。为了优化这个问题，我们需要尽可能的线程的数量。一个很容易想到的办法是：一般不创建线程，只有当连接有数据包发过来时才创建一个新的线程处理，处理完成后就立即销毁。阻塞IO会阻塞当前的线程，要想实现这种方案，在数据没有到达之前系统调用就不能阻塞，于是就引入了`非阻塞IO`
{% note success %} 
阻塞IO引入的问题：每个连接需要一个线程处理，过多的线程限制了服务的性能。
{% endnote %}

#### 非阻塞IO
&emsp;&emsp;`非阻塞IO`模式下，系统调用不会阻塞，如果有消息就会返回消息，没有消息就会返回`EWOULDBLOCK`错误码， 整体来看下非阻塞IO的工作模式：
<img src="/img/io_multiplexing/io_unblocking.png">
&emsp;&emsp;这种模式下，我们可以使用一个线程来检测对应的文件描述符是否有数据到来，如果没有就跳过，如果有就创建一个新的线程处理消息，当处理完对应描述符所以的消息后，就释放这个线程。在这个方式下，我们通过一个线程的引入，减少了很多不必要线程的创建。下面是常见的使用方式：
```go
func server() {
	...
	syscall.SetNonblock(fd, true) // set not block
	clients := make([]int, 0)     // store connected client's fd 
	...
	for(;;) {
		conn := accept()
		conn.fd->clients     // store new connection'fd into clients slice
		go func(){
			for (;;) {
                for client := range clients {
                    if client has message {
                        // create a new goroutine to handle
						go func (client){
                            // handle message	
                        }
                    }
                }
            }
        }
    }
}
```
&emsp;&emsp;这种IO模式解决了线程数量的问题，所以还是可以适当地提高了服务的吞吐，但是还是引入存在一个问题，从上面的代码我们可以看出，检测线程阶段是一个死循环，只要消息没来会不断地进行系统调用，如果当建立的连接数量增多，会带来两个可预见的问题：

- 频繁的系统调用会占用大量的CPU资源，高并发情况下，这个问题会被放大。
- 过多的连接，会导致时效性降低。
{% note success %} 
非阻塞IO引入的问题：频繁的系统调用占用大量的CPU，而且过多的连接会导致时效性降低。。</span>
{% endnote %}

#### IO多路复用
&emsp;&emsp;从`阻塞IO`和`非阻塞IO` 我们注意到，这两种模型的成本都花在了等待接收数据。`阻塞IO`相对低效一点，会一直等待。虽然`非阻塞IO`进行了优化，但是也引入了两个问题。如果内核能够提供一种能力：消息到来时，内核会通知用户态，再此之前，用户态不需要关注任何IO消息。这样也就彻底解决了由于等待消息带来的性能开销。
<img src="/img/io_multiplexing/io_multiplexing_work.png" width="50%" height="30%">
&emsp;&emsp;这就自然引入了，我们今天的主角：`IO多路复用`

<img src="/img/io_multiplexing/io_multiplexing_flow.png">

&emsp;&emsp;这种模式下，等待消息的过程被一个系统调用替换掉了。而且当有数据可以获取时，会返回有数据的文件描述符，所以这种方式就自然而然的解决了`非阻塞IO`的两个问题：
- 频繁的系统调用，会占用大量的CPU资源。
> 只需要一个系统调用`select`。
- 过多的连接，会导致时效性降低。
> 当有数据可以获取事，会主动回调，减少了由于循环带来的时效性问题

❓讲到这里，大家觉得`IO多路复用`复用的是什么呢？
&emsp;&emsp;我还是比较认可一种说法，复用的是系统调用而不是线程，在`非阻塞IO`模式下，多个文件描述符已经可以做到复用一个线程了。而`IO多路复用`解决的并不是线程的问题，而是频繁的系统问题。
### 总结
&emsp;&emsp;在没有IO多路复用之前，从阻塞IO到非阻塞IO，虽然解决了由于阻塞造成的线程数量较多的问题，但是也引出了诸多的问题，一直未解决本质的问题，而IO多路复用的引入，通过事件驱动，减少了无效的系统调用。从本质上解决了IO过程过程当中第一阶段的耗时。
&emsp;&emsp;IO多路复用，实际上就是通过复用多个文件描述的系统调用，并且在解复用时，内核再一个个判断对应的文件描述符的消息状态。
<img src="/img/io_multiplexing/io_multiplexing_reason.png"></img>

{% note success %}
一句话总结：IO多路复用通过一个系统调用监听多个文件描述符，当任意一个文件描述准备好，内核都会立刻通知，以此减少系统调用，并提高并发度。
{% endnote %}