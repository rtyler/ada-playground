with Ada.Text_IO,
     Ada.Command_Line,
     Ada.Streams,
     Interfaces.C;

with GNAT.Sockets;
with Epoll;


procedure Main is
    Event : aliased Epoll.Event_Type;
    Events : Epoll.Event_Array_Type;
    First_Event : aliased Epoll.Event_Type := Events (Events'First);

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
    end Read_Data;

begin
    Put_Line ("Starting epoll-based echo server...");
    ServerAddr.Addr := Inet_Addr (Listen_Addr);
    ServerAddr.Port := Port_Type (Listen_Port);
    Create_Socket (ServerSock);
    Set_Socket_Option (ServerSock, Socket_Level, (Reuse_Address, True));
    Bind_Socket (ServerSock, ServerAddr);
    Put_Line (".. bound to socket");

    Listen_Socket (ServerSock);
    Put_Line (".. listening for connections");

    EpollFD := Epoll.Create (Events'Last);

    if EpollFD = -1 then
        Put_Line ("Failed to create epoll(7) file descriptor");
        Ada.Command_Line.Set_Exit_Status (1);
        return;
    end if;

    Event.Events := Epoll.Epoll_In;
    Event.Data.FD := ServerSock;

    Retval := Epoll.Control (EpollFD, Epoll.Epoll_Ctl_Add, To_C (ServerSock), Event'Access);

    if Retval = -1 then
        Put_Line ("Epoll.Control call failed, not sure why");
        Ada.Command_Line.Set_Exit_Status (1);
        return;
    end if;

    loop
        Put_Line ("Waiting..");
        Num_FDs := Epoll.Wait (EpollFD, First_Event'Access, 10, -1);

        if Num_FDs = -1 then
            Put_Line ("Failure on Epoll.Wait, exiting");
            Ada.Command_Line.Set_Exit_Status (1);
            return;
        end if;

        for I in 0 .. Num_FDs loop
            Put_Line ("Activity on" & Num_FDs'Img & " sockets");
            declare
                Index : constant Integer := Integer (I);
                Polled_Event : Epoll.Event_Type := Events (Index);
                ClientSock   : GNAT.Sockets.Socket_Type;
                Socket_Request : GNAT.Sockets.Request_Type :=
                                   GNAT.Sockets.Request_Type'(Name    => Non_Blocking_IO,
                                                              Enabled => True);
            begin
                Put_Line ("Socket with activity" & Image (Polled_Event.Data.FD));
                if Polled_Event.Data.FD = ServerSock then
                    Put_Line ("Polled_Event is new connection, let's accept");
                    Accept_Socket (ServerSock, ClientSock, ServerAddr);

                    Control_Socket (Socket  => ClientSock,
                                    Request => Socket_Request);

                    Event.Events := Epoll.Epoll_In_And_Et;
                    Event.Data.FD := ClientSock;

                    Put_Line ("Socket opening up: " & Image (ClientSock));

                    Retval := Epoll.Control (EpollFD,
                                             Epoll.Epoll_Ctl_Add,
                                             To_C (ClientSock),
                                             Event'Access);
                    if Retval = -1 then
                        Put_Line ("Failed to add accepted socket to epollfd");
                        Ada.Command_Line.Set_Exit_Status (1);
                        return;
                    end if;
                else
                    Put ("Received data on socket: ");
                    Put (Image (Polled_Event.Data.FD));
                    Put (To_C (Polled_Event.Data.FD)'Img);
                    New_Line;
                    Read_Data (Polled_Event.Data.FD);
                end if;
            end;
        end loop;
    end loop;

end Main;
