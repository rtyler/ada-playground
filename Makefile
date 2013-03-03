
GNATFLAGS=-gnat05
GNATMAKE=gnat make $(GNATFLAGS)
EXES=readself hello twotasking echoserver vectors echopool echomultitask

all: $(EXES)

readself:
	$(GNATMAKE)  readself.adb

hello:
	$(GNATMAKE)  hello.adb

twotasking:
	$(GNATMAKE)  twotasking.adb

echoserver:
	$(GNATMAKE)  echoserver.adb

echopool: clean
	$(GNATMAKE)  echopool.adb

vectors:
	$(GNATMAKE)  vectors.adb

echomultitask:
	$(GNATMAKE) echomultitask.adb

clean:
	rm -f *.o *.ali
	rm -f $(EXES)
