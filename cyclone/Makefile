PROGS = sum-no-sync \
        sum-mutex \
        sum-spin-lock \
        sum-atomic-fxbox 
        sum-atomic-box 

SCMFILES = $(addsuffix .scm, $(PROGS))
CFILES = $(addsuffix .c, $(PROGS))

$(PROGS): %: %.scm
	cyclone $<
	./$@

230.o: 230.sld
	cyclone 230.sld

all: 230.o $(PROGS)

test: all

clean: 
	rm -f $(PROGS) 230.o 230.c 230.so *.meta
