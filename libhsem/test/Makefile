BUILDDIR=../_build/test
$(shell mkdir -p $(BUILDDIR))
OCAMLDIR=$(shell ocamlopt -where)

CC:= $(shell ocamlfind ocamlc -config | awk '/^bytecomp_c_compiler/ {for(i=2;i<=NF;i++) printf "%s " ,$$i}')
LD=$(CC)

all: $(BUILDDIR)/test.native

clean:
	rm -rf $(BUILDDIR)

$(BUILDDIR)/test.native: $(BUILDDIR)/test.o
	$(LD) -o $@ $< -L$(BUILDDIR)/.. -lhsem

$(BUILDDIR)/test.o: test.c
	$(CC) -c -o $@ -I $(OCAMLDIR) -I $(BUILDDIR)/../generated  $<

.PHONY: all clean
