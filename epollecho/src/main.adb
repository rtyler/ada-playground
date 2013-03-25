with Ada.Exceptions,
     Ada.Text_IO,
     Ada.Command_Line,
     Ada.Streams,
     Interfaces.C;

with GNAT.Sockets;
with Epoll;


procedure Main is
    Event : aliased Epoll.Event_Type;
    Events : Epoll.Event_Array_Type (1 .. 10);

    ServerSock : GNAT.Sockets.Socket_Type;
    ServerAddr : GNAT.Sockets.Sock_Addr_Type;

    Listen_Addr : constant String := "127.0.0.1";
    Listen_Port : constant Integer := 2046;

    EpollFD     : Epoll.Epoll_Fd_Type;

    Retval, Num_FDs : Interfaces.C.int;


    use Ada.Text_IO,
        Interfaces.C,
        GNAT.Sockets;

    procedure Read_Data (S : in GNAT.Sockets.Socket_Type) is
        Channel : Stream_Access := Stream (S);
        Data : Ada.Streams.Stream_Element_Array (1 .. 1);
        Offset  : Ada.Streams.Stream_Element_Count;

        use Ada.Streams;
    begin
        while true loop
            Ada.Streams.Read (Channel.All, Data, Offset);
            exit when Offset = 0;
            Put (Character'Val (Data (1)));
        end loop;
        Put_Line (".. closing connection");
        GNAT.Sockets.Close_Socket (S);
    exception
        when S_Error : GNAT.Sockets.Socket_Error =>
            if GNAT.Sockets.Resolve_Exception (S_Error) = GNAT.Sockets.Resource_Temporarily_Unavailable then
                -- Resource_Temporarily_Unavailable means we have read all available bytes
                -- we'll let epoll(7) call us back.
                null;
            else
                raise;
            end if;
    end Read_Data;

    procedure Make_Non_Blocking (S : in GNAT.Sockets.Socket_Type) is
        Socket_Request : GNAT.Sockets.Request_Type :=
                           GNAT.Sockets.Request_Type'(Name    => Non_Blocking_IO,
                                                      Enabled => True);
    begin
        Control_Socket (Socket  => S,
                        Request => Socket_Request);
    end Make_Non_Blocking;

    procedure Error_Exit (Message : In String) is
    begin
        Ada.Text_IO.Put_Line (Message);
        Ada.Command_Line.Set_Exit_Status (1);
    end Error_Exit;

begin
    Put_Line ("Starting epoll-based echo server...");
    ServerAddr.Addr := Inet_Addr (Listen_Addr);
    ServerAddr.Port := Port_Type (Listen_Port);
    Create_Socket (ServerSock);
    Set_Socket_Option (ServerSock, Socket_Level, (Reuse_Address, True));
    Bind_Socket (ServerSock, ServerAddr);
    Make_Non_Blocking (ServerSock);
    Put_Line (".. bound to socket");

    Listen_Socket (ServerSock);
    Put_Line (".. listening for connections on" & Image (ServerSock));

    EpollFD := Epoll.Create (Events'Last + 1);

    if EpollFD = -1 then
        Error_Exit ("Failed to create epoll(7) file descriptor");
        return;
    end if;

    Event.Events := Epoll.Epoll_In;
    Event.Data.FD := ServerSock;

    Retval := Epoll.Control (EpollFD, Epoll.Epoll_Ctl_Add, To_C (ServerSock), Event'Access);

    if Retval = -1 then
        Error_Exit ("Epoll.Control call failed, not sure why");
        return;
    end if;

    loop
        Put_Line ("Waiting..");
        -- Reset the Num_FDs before we wait again
        Num_FDs := 0;
        Num_FDs := Epoll.Wait (EpollFD, Events (Events'First)'Access, 10, -1);
        Put_Line ("Activity on" & Num_FDs'Img & " sockets");

        if Num_FDs = -1 then
            Error_Exit ("Failure on Epoll.Wait, exiting");
            return;
        end if;

        for I in 1 .. Num_FDs loop
            declare
                Index : constant Integer := Integer (I);
                Polled_Event : Epoll.Event_Type := Events (Index);
                ClientSock   : GNAT.Sockets.Socket_Type;
            begin
                Put_Line ("Socket (" & Index'Img & ") with data:" & Image (Polled_Event.Data.FD));

                if Polled_Event.Data.FD = ServerSock then
                    Put_Line ("Polled_Event is new connection, let's accept");
                    Accept_Socket (ServerSock, ClientSock, ServerAddr);
                    Make_Non_Blocking (ClientSock);

                    Event.Events := Epoll.Epoll_In_And_Et;
                    Event.Data.FD := ClientSock;

                    Put_Line ("Socket opening up: " & Image (ClientSock));

                    Retval := Epoll.Control (EpollFD,
                                             Epoll.Epoll_Ctl_Add,
                                             To_C (ClientSock),
                                             Event'Access);
                    if Retval = -1 then
                        Error_Exit ("Failed to add accepted socket to epollfd");
                        return;
                    end if;
                else
                    Put_Line ("Received data on socket: " & Image (Polled_Event.Data.FD));
                    Read_Data (Polled_Event.Data.FD);
                end if;
            end;
        end loop;
    end loop;

end Main;
