# epoll echo

Simple example of building a little epoll(7)-based server

### Known Issues

 * This code is ugly.
 * The `Accept_Socket` code will not handle multiple clients connecting at the
   same time. This is easily accomplished by having a loop that would accept
   incoming connections and then bail out on an `EAGAIN` or `EWOULDBLOCK`.

