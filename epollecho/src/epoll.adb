
package body Epoll is

    function Create (Size : Integer) return Epoll_Fd_Type is
    begin
        return Create (Interfaces.C.int (Size));
    end Create;

end Epoll;
