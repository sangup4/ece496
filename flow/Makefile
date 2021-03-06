# usage to compile mydir/mydir.v: make D=mydir flash

# flow directory
FLOW?=.

# directory for project files
DIR?=adder

# prefix for file names
P?=$(DIR)/$(DIR)

# configuration variables
TRACKS?=4
ROWS?=2
COLS?=2
PADVERSION?=clk

# file path configuration
BIN?=$(FLOW)/bin
SCRIPTS?=$(FLOW)/scripts
ARCH?=$(FLOW)/vpr5-k6-n4.template.xml
PADS?=$(FLOW)/pads/pads-$(COLS)x$(ROWS)-$(PADVERSION).txt

# binary paths
ODIN=$(BIN)/odin_ii
ABC=$(BIN)/abc-vtr
VPACK=$(BIN)/t-vpack
VPR=$(BIN)/vpr5

.PHONY: clean flash verilog view

.SECONDARY:

all: $(P).done

clean:
	rm -f gc.txt *.echo $(DIR)/abc.cmd $(P).*.log $(P).*.blif $(P).*.out $(P).net $(P).done $(P).bit $(P).uart-tb.v $(P).arch.xml

$(P).odin.blif: $(P).v
	$(ODIN) -V $< -o $(P).odin.blif 2> $(P).odin.log > $(P).odin.log

$(P).abc.blif: $(P).odin.blif
	printf "read $<\nif -K 6\nsweep\nwrite_hie $< $@" > $(DIR)/abc.cmd
	$(ABC) -f $(DIR)/abc.cmd  > $(P).abc.log

$(P).awk.blif: $(P).abc.blif
	cat $< | awk '{ if ($$1 == ".latch"){ print $$1, $$2, $$3, "re", "top^clk", $$4 } else { print $$0 } }' > $@

$(P).net: $(P).awk.blif
	$(VPACK) $< $@ -inputs_per_cluster 16 -cluster_size 4 -lut_size 6 > $(P).vpack.log

$(P).arch.xml: $(ARCH)
	sed 's/#ROWS#/$(ROWS)/g' $< | sed 's/#COLS#/$(COLS)/g' > $@

$(P).route.out: $(P).net $(P).arch.xml
	$(VPR) $(P).net $(P).arch.xml $(P).place.out $(P).route.out -nodisp -fix_pins $(PADS) -route_chan_width $(TRACKS) > $(P).vpr.log
	@test -e $(P).route.out

view: $(P).net $(P).arch.xml
	$(VPR) $(P).net $(P).arch.xml $(P).place.out $(P).route.out -fix_pins $(PADS) -route_chan_width $(TRACKS) > $(P).vpr.log

$(P).done: $(P).route.out
	$(SCRIPTS)/fpga.py $(P).place.out $(P).route.out $(P).net $(P).abc.blif $(TRACKS) > $(P).bit
	touch $@

verilog: $(P).done
	$(SCRIPTS)/program_bitstream.py --file $(P).bit --dry --sim $(P).uart-tb.v

flash: $(P).done
	$(SCRIPTS)/program_bitstream.py --file $(P).bit

