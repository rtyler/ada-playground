with Ada.Containers,
     Ada.Containers.Indefinite_Hashed_Maps,
     Ada.Exceptions,
     Ada.Text_IO,
     Ada.Streams,
     Ada.Strings.Hash,
     Ada.Unchecked_Deallocation,
     GNAT.Sockets;


with EchoMultitask.Worker;


procedure EchoMultitask_Main is
    use Ada.Text_IO,
        GNAT.Sockets,
        EchoMultitask.Worker;

    ServerSock : Socket_Type;
    ServerAddr : Sock_Addr_Type;
begin
    ServerAddr.Addr := Inet_Addr ("0.0.0.0");
    ServerAddr.Port := Port_Type (2046);
    Create_Socket (ServerSock);

    Set_Socket_Option (ServerSock, Socket_Level, (Reuse_Address, True));
    Bind_Socket (ServerSock, ServerAddr);
    Listen_Socket (ServerSock);

    Put_Line ("Listening on port 2046");

    --  Keep the daemon running forever for now
    loop
        Put_Line ("Waiting for a connection..");
        declare
            ClientSock : Socket_Type;
            W : Worker_Ptr := new Worker;
        begin
            Accept_Socket (ServerSock, ClientSock, ServerAddr);
            Put_Line ("accepted connection");
            -- Dereference the pointer and call Server() on the Worker object
            W.all.Serve (ClientSock);
            Coordinator.Track (W);
        end;
    end loop;

end EchoMultitask_Main;

