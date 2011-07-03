SRCDIR=src
BINDIR=bin
INCDIR=inc
SOURCES=$(wildcard $(SRCDIR)/*.d)
#HEADERS=$(wildcard $(SRCDIR)/*.hpp)
OBJS=$(SOURCES:.d=.o)
EXEC=dgi

CC=gdmd
CFLAGS=-od$(SRCDIR) -I$(SRCDIR) -J$(INCDIR)

LD=gdmd
LFLAGS=

ifdef profile
CFLAGS+=-profile
LFLAGS+=-profile
endif

ifndef nowall
CFLAGS+=-w -wi
endif

ifdef release
CFLAGS+=-O -release -inline -m64 -noboundscheck -q,-O3,-s
else
CFLAGS+=-g -debug
endif

ifdef coverage
CFLAGS+=-cov
LFLAGS+=-cov
endif

all: $(EXEC)

full: release

$(EXEC): $(OBJS)
	mkdir -p $(BINDIR)
	$(CC) $(LFLAGS) $?
	mv a.out $(BINDIR)/$(EXEC)

%.o: %.d $(HEADERS)
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(BINDIR)/$(EXEC)
	rm -f $(SRCDIR)/*.o

