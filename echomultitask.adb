with Ada.Text_IO,
     Ada.Task_Identification,
     Ada.Streams,
     GNAT.Sockets;

procedure EchoMultitask is

    task type Connection_Worker is
        entry Serve (Sock : GNAT.Sockets.Socket_Type);
    end Connection_Worker;

    ServerSock : GNAT.Sockets.Socket_Type;
    ServerAddr : GNAT.Sockets.Sock_Addr_Type;

    task body Connection_Worker is
        use Ada.Streams,
            Ada.Text_IO;

        Client_Sock : GNAT.Sockets.Socket_Type;
    begin
        accept Serve (Sock : GNAT.Sockets.Socket_Type) do
            Client_Sock := Sock;
        end Serve;

        declare
            Channel : GNAT.Sockets.Stream_Access := GNAT.Sockets.Stream (Client_Sock);
            Data : Ada.Streams.Stream_Element_Array (1 .. 1);
            Offset : Ada.Streams.Stream_Element_Count;
        begin
            while true loop
                Ada.Streams.Read (Channel.All, Data, Offset);
                exit when Offset = 0;
                Put (Character'Val (Data (1)));
            end loop;
            Put_Line (".. closing connection");
            GNAT.Sockets.Close_Socket (Client_Sock);
        end;
    end Connection_Worker;

    use Ada.Text_IO;
begin
    ServerAddr.Addr := GNAT.Sockets.Inet_Addr ("0.0.0.0");
    ServerAddr.Port := GNAT.Sockets.Port_Type (2046);
    GNAT.Sockets.Create_Socket (ServerSock);

    GNAT.Sockets.Set_Socket_Option (ServerSock, GNAT.Sockets.Socket_Level, (GNAT.Sockets.Reuse_Address, True));
    GNAT.Sockets.Bind_Socket (ServerSock, ServerAddr);
    GNAT.Sockets.Listen_Socket (ServerSock);

    Put_Line ("Listening on port 2046");

    --  Keep the daemon running forever for now
    loop
        Put (".");
        declare
            ClientSock : GNAT.Sockets.Socket_Type;
            Worker : access Connection_Worker := new Connection_Worker;
        begin
            GNAT.Sockets.Accept_Socket (ServerSock, ClientSock, ServerAddr);
            Put_Line ("accepted connection");
            Worker.all.Serve (ClientSock);
        end;
    end loop;

end EchoMultitask;

