--
--  Echo server!

private with Ada.Containers.Vectors,
             Ada.Text_IO,
             Ada.Streams,
             GNAT.Sockets;

procedure EchoPool is
    use Ada.Containers,
        Ada.Text_IO,
        Ada.Streams,
        GNAT.Sockets;

    ServerSock : Socket_Type;
    ClientSock : Socket_Type;
    ServerAddr : Sock_Addr_Type;

    Listen_Addr : constant String := "127.0.0.1";
    Listen_Port : constant Integer := 2046;

    task type Echo_Handler is
        entry Handle (Client_Socket : Socket_Type);
    end Echo_Handler;

    task body Echo_Handler is
    begin
        loop
            accept Handle (Client_Socket : Socket_Type) do
                declare
                    Channel : Stream_Access := Stream (Client_Socket);
                    -- Char : Character;
                    Data : Ada.Streams.Stream_Element_Array (1 .. 1);
                    Offset : Ada.Streams.Stream_Element_Count;
                begin
                    while true loop
                        Ada.Streams.Read (Channel.All, Data, Offset);
                        exit when Offset = 0;
                        Put (Character'Val (Data (1)));
                    end loop;
                    Put_Line (".. closing connection");
                    Close_Socket (Client_Socket);
                end;

                --  Arbitrary delay just cause
                delay 5.0;
            end Handle;
        end loop;
    end Echo_Handler;

    type Handler_Ptr is access all Echo_Handler;
    type Handler_Arr is array (Positive range 1 .. 10) of Handler_Ptr;

    package T_Container is new Ada.Containers.Vectors (Element_Type => Handler_Ptr,
                                                       Index_Type   => Natural);

    type Task_Pool is tagged record
        --Busy_Tasks      : T_Container.Vector;
        Available_Tasks : T_Container.Vector;
        All_Tasks       : Handler_Arr;
    end record;

    procedure Acquire (T : in out Task_Pool; H : out Handler_Ptr) is
    begin
        while true loop
            if T_Container.Length (T.Available_Tasks) > 0 then
                declare
                    Ptr : Handler_Ptr := T_Container.First_Element (T.Available_Tasks);
                begin
                    T_Container.Delete_First (T.Available_Tasks, 1);
                    H := Ptr;

                    -- Since we're going to be using this task now, let's put
                    -- it into the Busy_Tasks vector
                    --T_Container.Append (T.Busy_Tasks, Ptr);
                    return;
                end;
            end if;

            --  If we had no tasks available to us, we'll just busy-wait
            delay 0.1;
        end loop;
    end Acquire;

    procedure Release (T : in out Task_Pool; H : in Handler_Ptr) is
    begin
        T_Container.Append (T.Available_Tasks,  H);
    end Release;

    Pool    : Task_Pool;
    Handler : Echo_Handler;
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
        Handler.Handle (ClientSock);
    end loop;
end EchoPool;
