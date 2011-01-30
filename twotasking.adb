--
--
--

with Ada.Text_IO, Ada.Float_Text_IO;
with Ada.Numerics.Float_Random;
use Ada.Float_Text_IO, Ada.Text_IO;

procedure TwoTasking is
    task type TenLooper (Id : Character) is
    end TenLooper;

    task body TenLooper is
        Seed : Ada.Numerics.Float_Random.Generator;
    begin
        Ada.Numerics.Float_Random.Reset (Seed, Character'Pos (Id));
        for I in 1 .. 10 loop
            declare
                Offset : Duration := Duration (Ada.Numerics.Float_Random.Random (Seed));
            begin
                Put_Line ("Derp: " & Id &  " :: " & Integer'Image (I));
                Put_Line ("Delaying: " & Duration'Image (Offset));
                delay Offset;
            end;
        end loop;
    end TenLooper;

    Task_1 : TenLooper ('A');
    Task_2 : TenLooper ('B');
begin
    Put_Line ("..waiting for tasks to complete");
end TwoTasking;
