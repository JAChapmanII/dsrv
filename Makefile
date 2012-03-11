SRCDIR=src
INCDIR=inc
OBJDIR=obj
BINDIR=bin

OBJECTS=$(OBJDIR)/about_handler.o $(OBJDIR)/api_handler.o
OBJECTS+=$(OBJDIR)/code_handler.o $(OBJDIR)/repository.o
OBJECTS+=$(OBJDIR)/update_handler.o $(OBJDIR)/update.o

MAIN=dgi
BIN=j.cgi

CC=gdmd

DFLAGS=-I$(SRCDIR) -J$(INCDIR)
LDFLAGS=

USER=jac
SERVER=jachapmanii.net
DESTINATION=http
REMOTE=$(USER)@$(SERVER)

ifdef profile
DFLAGS+=-profile
LDFLAGS+=-profile
endif

ifndef nowall
DFLAGS+=-w -wi
endif

ifdef release
DFLAGS+=-O -release -inline -m64 -noboundscheck -q,-O3,-s
else
DFLAGS+=-g -debug
endif

all: dir top $(BINDIR)/$(BIN) deploy js
dir:
	mkdir -p $(OBJDIR) $(BINDIR)
top:
	[[ -f $(BINDIR)/$(BIN) ]] && cp $(BINDIR)/$(BIN){,.old} || true


# main binary
$(BINDIR)/$(BIN): $(OBJDIR)/$(MAIN).o $(OBJECTS)
	$(CC) -of$@ $^ $(LDFLAGS)

# target for object files
$(OBJDIR)/%.o: $(SRCDIR)/%.d
	$(CC) $(DFLAGS) -c $^ -of$@


# js deployment
js: js/ phony
	scp -r $< $(REMOTE):$(DESTINATION)/

# fresh deployment
$(BIN).tar.xz: $(BINDIR)/$(BIN)
	tar cJf $@ $^

cdeploy: $(BIN).tar.xz
	# copy tar'd binary to remote
	scp $^ $(REMOTE):$(DESTINATION)/
	# extract the file into $(BIN) and ensure it is executable, remove tar
	ssh $(REMOTE) "tar xf $(DESTINATION)/$^ -O > $(DESTINATION)/$(BIN) && \
		chmod +x $(DESTINATION)/$(BIN) && \
		rm $(DESTINATION)/$^"

# targets related to deploying
$(BINDIR)/$(BIN).old.md5sum: $(BINDIR)/$(BIN).old
	md5sum $^ > $@

$(BINDIR)/$(BIN).bspatch: $(BINDIR)/$(BIN).old $(BINDIR)/$(BIN)
	bsdiff $^ $@

sizes: $(BINDIR)/$(BIN).old $(BINDIR)/$(BIN) $(BINDIR)/$(BIN).bspatch
	du -hs $^

remote_copy: $(BINDIR)/$(BIN).bspatch $(BINDIR)/$(BIN).old.md5sum
	scp $^ $(REMOTE):$(DESTINATION)

remote_md5sum:
	# make sure remote binary exists
	[[ -n `ssh $(REMOTE) "ls $(DESTINATION)/$(BIN) 2>/dev/null"` ]]
	# create remote md5sum file
	ssh $(REMOTE) "md5sum $(DESTINATION)/$(BIN) > $(DESTINATION)/$(BIN).md5sum"

deploy: sizes remote_copy remote_md5sum
	# make sure remote md5sum matches
	[[ -n `ssh $(REMOTE) "diff $(DESTINATION)/$(BIN){.old,}.md5sum"` ]]
	# move old binary, apply patch, make executable, remove old binary
	ssh $(REMOTE) "mv $(DESTINATION)/$(BIN){,.old} && \
		bspatch $(DESTINATION)/$(BIN){.old,,.bspatch} && \
		chmod +x $(DESTINATION)/$(BIN) && \
		rm $(DESTINATION)/$(BIN).old"

phony:
	true

clean:
	rm -f $(BINDIR)/$(BIN) $(BINDIR)/$(BIN).old $(OBJDIR)/*.o

