
GNATMAKE=gnat make
EXES=readself hello

all: $(EXES)

readself:
	$(GNATMAKE) readself.adb

hello:
	$(GNATMAKE) hello.adb

clean:
	rm -f *.o *.ali
	rm -f $(EXES)
