private with Ada.Streams,
             Ada.Strings.Hash,
             Ada.Text_IO,
             GNAT.Sockets;

package body EchoMultitask.Worker is
    use Ada.Text_IO,
        GNAT.Sockets;

    -- We need a Hash function to make sure our Hashed_Maps.Map container can
    -- proeprly create the hash map. This function will just rely on the
    -- Ada.Strings.Hash function and pass in the string representation of the
    -- Task_Id
    function Hash (Key : Ada.Task_Identification.Task_Id) return Ada.Containers.Hash_Type is
    begin

        return Ada.Strings.Hash (Ada.Task_Identification.Image (Key));

    end Hash;


    task body Worker is
        use Ada.Streams;

        Client_Sock : Socket_Type;
    begin
        accept Serve (Sock : Socket_Type) do
            Client_Sock := Sock;
        end Serve;

        declare
            Channel : Stream_Access := Stream (Client_Sock);
            Data : Ada.Streams.Stream_Element_Array (1 .. 1);
            Offset : Ada.Streams.Stream_Element_Count;
        begin
            while true loop
                Ada.Streams.Read (Channel.All, Data, Offset);
                exit when Offset = 0;
                Put (Character'Val (Data (1)));
            end loop;
            Free(Channel);
            Put_Line (".. closing connection");
            Close_Socket (Client_Sock);
        end;
    end Worker;


    protected body Coordinator is

        procedure Last_Wish (C : Ada.Task_Termination.Cause_Of_Termination;
                             T : Ada.Task_Identification.Task_Id;
                             X : Ada.Exceptions.Exception_Occurrence) is
            W : Worker_Ptr := Tasks.Element (T);
        begin

            -- First, let's make sure we remove the task object from our Tasks
            -- map
            Tasks.Delete (Key => T);
            -- Then we deallocate it
            Free_Worker (W);
            Put_Line ("Task (" & Ada.Task_Identification.Image (T) & ") deallocated");

        end Last_Wish;

        procedure Track (Ptr : in Worker_Ptr) is
            -- THe Task_Id for a task can be found in the Identity attribute,
            -- but since we're receiving a Worker_Ptr type, we first need to
            -- dereference it into a Worker again
            Key : constant Ada.Task_Identification.Task_Id := Ptr.all'Identity;
        begin

            Put_Line ("Adding task (" & Ada.Task_Identification.Image (Key) & ") to Coordinator.Tasks");

            -- Add our Worker pointer into our hash map to hold onto it for
            -- later
            Tasks.Insert (Key      => Key,
                          New_Item => Ptr);

            -- We need to set a task termination handler (introduced in Ada
            -- 2005) in order to get called when the Worker (W) terminates
            Ada.Task_Termination.Set_Specific_Handler (Key, Last_Wish'Access);

        end Track;

    end Coordinator;

end EchoMultitask.Worker;
