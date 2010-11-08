with AUnit.Reporter.Text;
with AUnit.Run;

with SimpleTest.Suite;
use SimpleTest.Suite;

procedure RunTests is
    procedure Runner is new AUnit.Run.Test_Runner (Suite);
    Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
    -- Set_Use_ANSI_Colors();
    Runner(Reporter);
end RunTests;
