--
--  Echo server!

private with Ada.Text_IO;
private with Ada.Streams;
private with GNAT.Sockets;

use Ada.Text_IO;
use Ada.Streams;
use GNAT.Sockets;

procedure echoserver is
    ServerSock : Socket_Type;
    ClientSock : Socket_Type;
    ServerAddr : Sock_Addr_Type;

    Listen_Addr : constant String := "127.0.0.1";
    Listen_Port : constant Integer := 2046;


begin
    Initialize; -- Initialize the GNAT.Sockets library
    ServerAddr.Addr := Inet_Addr (Listen_Addr);
    ServerAddr.Port := Port_Type (Listen_Port);

    Create_Socket (ServerSock);
    Set_Socket_Option (ServerSock, Socket_Level, (Reuse_Address, True));
    Put_Line (">>> Starting echo server on port" & Integer'Image (Listen_Port) & " ...");

    Bind_Socket (ServerSock, ServerAddr);
    Put_Line (".. bound to socket");

    Listen_Socket (ServerSock);
    Put_Line (".. listening for connections");

    loop
        Accept_Socket (ServerSock, ClientSock, ServerAddr);
        Put_Line (".. accepted connection");

        declare
            Channel : Stream_Access := Stream (ClientSock);
            Char : Character;
            Data : Ada.Streams.Stream_Element_Array (1 .. 1);
            Offset : Ada.Streams.Stream_Element_Count;
        begin
            while true loop
                Ada.Streams.Read (Channel.All, Data, Offset);
                exit when Offset = 0;
                Put (Character'Val (Data (1)));
            end loop;
            Put_Line (".. closing connection");
            Close_Socket (ClientSock);
        end;
    end loop;
end;
