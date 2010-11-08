--
--  Simple AUnit test package body
--

with AUnit.Assertions;
use AUnit.Assertions;

package body SimpleTest is
    function Name(T: Test) return AUnit.Message_String is
        pragma Unreferenced(T);
    begin
        return AUnit.Format("SimpleTest package");
    end Name;

    procedure Run_Test(T: In out Test) is
        pragma Unreferenced(T);
    begin
        Assert(True, "How can True be false!");
        Assert(False, "False is False, a-doy");
    end Run_Test;
end SimpleTest;

