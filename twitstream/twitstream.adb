with Ada.Command_Line,
     Ada.Text_IO,
     AWS.Client,
     AWS.Messages,
     AWS.Response;

procedure TwitStream is
    use Ada.Text_IO;

    package CLI renames Ada.Command_Line;

    Host : constant String := "http://stream.twitter.com/1/statuses/sample.json";
    Conn : AWS.Client.HTTP_Connection;
    Result : AWS.Response.Data;
begin
    if CLI.Argument_Count < 2 then
        Put_Line ("Missing some arguments!");
        CLI.Set_Exit_Status (1);
        return;
    end if;

    Put_Line ("Starting TwitStream..");

    AWS.Client.Create (Conn, Host, Server_Push => True);
    AWS.Client.Set_WWW_Authentication (Conn, CLI.Argument (1),
                                             CLI.Argument (2),
                                             AWS.Client.Basic);

    Put_Line ("..connection created");

    AWS.Client.Get (Conn, Result);

    Status_Check : declare
        use AWS.Messages;

        Code : AWS.Messages.Status_Code := AWS.Response.Status_Code (Result);
    begin
        if Code = AWS.Messages.S200 then
            Put_Line ("200 Status");
        else
            Put_Line ("Bad status: " & AWS.Messages.Image (Code));
            Put_Line (AWS.Messages.Reason_Phrase (Code));
            CLI.Set_Exit_Status (1);
            return;
        end if;
    end Status_Check;

    while true loop
        Put (AWS.Client.Read_Until (Conn, "" & ASCII.LF));
        delay 0.1;
    end loop;

end TwitStream;
