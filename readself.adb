-- Simple Ada program to read "itself" (the file it's compiled from)
-- and print it out
--
--
with Ada.Sequential_IO;
with Ada.Text_IO;

procedure readself is
    package IO is new Ada.Sequential_IO(Element_Type => Character);
    SourceFile : IO.File_Type;
begin

    Ada.Text_IO.New_Line;
    IO.Open(SourceFile, IO.In_File, "readself.adb");

    declare
        C : Character;
    begin
        while not IO.End_Of_File(SourceFile)
        loop
            IO.Read(SourceFile, C);
            Ada.Text_IO.Put(C);
        end loop;
    end;

    IO.Close(SourceFile);
    Ada.Text_IO.New_Line;

end;
