SRCDIR=src
BINDIR=bin
INCDIR=inc

SOURCES=$(wildcard $(SRCDIR)/*.d)
OBJECTS=$(SOURCES:.d=.o)
BIN=dgi
INC=$(wildcard $(INCDIR)/*)

CC=gdmd

CFLAGS=-od$(SRCDIR) -I$(SRCDIR) -J$(INCDIR)
LDFLAGS=-of$(BINDIR)/$(BIN)

ifdef profile
CFLAGS+=-profile
LDFLAGS+=-profile
endif

ifndef nowall
CFLAGS+=-w -wi
endif

ifdef release
CFLAGS+=-O -release -inline -m64 -noboundscheck -q,-O3,-s
else
CFLAGS+=-g -debug
endif

$(BINDIR)/$(BIN): $(OBJECTS)
	mkdir -p $(BINDIR)
	if [ -f $(BINDIR)/$(BIN) ]; then mv $(BINDIR)/$(BIN){,.old}; fi
	$(CC) $(OBJECTS) $(LDFLAGS)

%.o: %.d
	$(CC) -c $(CFLAGS) $*

cdeploy cdeploy.sh: $(BINDIR)/$(BIN)
	./cdeploy.sh
	touch cdeploy cdeploy.sh

deploy deploy.sh: $(BINDIR)/$(BIN)
	./deploy.sh
	touch deploy deploy.sh


clean:
	rm -f $(BINDIR)/$(BIN) $(OBJECTS)

