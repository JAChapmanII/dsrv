SRCDIR=src
BINDIR=bin
INCDIR=inc

SRC=$(SRCDIR)/dgi.d
OBJ=$(SRCDIR)/dgi.o
BIN=$(BINDIR)/dgi
INC=$(INCDIR)/style.css

CC=gdmd

CFLAGS=-od$(SRCDIR) -I$(SRCDIR) -J$(INCDIR)
LFLAGS=-of$(BIN)

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

$(BIN): $(OBJ)
	mkdir -p $(BINDIR)
	$(CC) $(OBJ) $(LFLAGS)

$(OBJ): $(SRC) $(INC)
	$(CC) -c $(CFLAGS) $(SRC)

clean:
	rm -f $(BIN) $(OBJ)

