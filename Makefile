SRCDIR=src
BINDIR=bin
INCDIR=inc

SOURCES=$(wildcard $(SRCDIR)/*.d)
OBJECTS=$(SOURCES:.d=.o)
BIN=$(BINDIR)/dgi
INC=$(wildcard $(INCDIR)/*)

CC=gdmd

CFLAGS=-od$(SRCDIR) -I$(SRCDIR) -J$(INCDIR)
LDFLAGS=-of$(BIN)

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

$(BIN): $(OBJECTS)
	mkdir -p $(BINDIR)
	$(CC) $(OBJECTS) $(LDFLAGS)

%.o: %.d
	$(CC) -c $(CFLAGS) $*

deploy.sh: $(BIN)
	./deploy.sh

clean:
	rm -f $(BIN) $(OBJECTS)

