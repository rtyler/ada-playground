with SimpleTest;


package body SimpleTest.Suite is
    use AUnit.Test_Suites;
    function Suite return Access_Test_Suite is
        Result : constant Access_Test_Suite := new Test_Suite;
    begin
        Result.Add_Test(new SimpleTest.Test);
        return Result;
    end Suite;
end SimpleTest.Suite;
