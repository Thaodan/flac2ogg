SHPP          = shpp
SHPP_FLAGS    =
DESTDIR       =
PREFIX        = /usr/local
INSTALL       = /usr/bin/install -D
MSGFMT        = /usr/bin/msgfmt
SED           = /bin/sed
bindir        = $(PREFIX)/bin
libdir        = $(PREFIX)/lib
sysconfdir    = $(PREFIX)/etc

TARGET=flac2ogg
all: $(TARGET)

$(TARGET): ${TARGET:=.in.sh}
	$(SHPP) -Dlibdir=$(libdir) $(SHPP_FLAGS) $@.in.sh -o $(TARGET)

install: $(TARGET) 
	$(INSTALL) $(TARGET) $(bindir)/$(TARGET)


clean: 
	rm -f $(TARGET)

.PHONY: install all clean
