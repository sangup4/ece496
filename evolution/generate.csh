#!/bin/tcsh -f

# global options
set scripts = "."
set verilog = "verilog"
set proj = "evolution"
set top = "fitness"
set module = "individual"
set prefix = "tester:test|${module}:mutant|"
set files = "tester delay hex_digits uart"
set family = "Cyclone II"
set device = "EP2C20F484C7"

if ($?EVOLUTION_SCRIPTS) then
	set scripts = "$EVOLUTION_SCRIPTS"
endif

if ($?EVOLUTION_VERILOG) then
	set verilog = "$EVOLUTION_VERILOG"
endif

# generate new project file
set out = "$proj.qsf"
set tcl = "set_global_assignment -name"
set q = '"'
echo "creating $out"
cat /dev/null > $out
echo "$tcl PROJECT_CREATION_TIME_DATE $q`date '+%T  %B %d, %Y'`$q" >> $out
echo "$tcl TOP_LEVEL_ENTITY $top" >> $out
echo "$tcl FAMILY $q$family$q" >> $out
echo "$tcl DEVICE $q$device$q" >> $out
echo "$tcl SYNTHESIS_EFFORT FAST" >> $out
echo "$tcl ADV_NETLIST_OPT_SYNTH_WYSIWYG_REMAP ON" >> $out
echo "$tcl VERILOG_FILE $module.v" >> $out
foreach file ($top $files)
	echo "$tcl VERILOG_FILE $verilog/$file.v" >> $out
end

# add DE1 pin definitions to project file
cat "$scripts/pins.tcl" >> $out

set echo

# generate some optional arguments
set seed_file = ""
if ( -e "$module.seed" ) then
	set seed_file = "--seed=$module.seed"
endif

# generate mutant instance
$scripts/synthesize_cells.py \
	--verilog "$module.v" \
	--module "$module" \
	--prefix "$prefix" \
	--csv "$module.csv" \
	--place "$module.place" \
	--cells 128 \
	--min-x 5 --max-x 12 \
	--min-y 3 --luts 2,10,18,26 \
	--inputs in1 \
	--outputs out1 \
	--tie-unused \
	$seed_file \
	| tee $module.generation.rpt || exit $?

# complete functional synthesis
quartus_map $proj | tee quartus.map.log || exit $?

# check for synthesis wanrnings
$scripts/check_warnings.py "$proj.map.rpt" || exit $?

# exit early for stress test
if ($?STRESS) then
	exit 0
endif

# append placement information to the project file
cat $module.place >> $proj.qsf

# run placement and routing, then produce output files
quartus_fit $proj | tee quartus.fit.log || exit $?
quartus_asm $proj | tee quartus.asm.log || exit $?

# back-annotate results for debugging
if ($?DEBUG) then
	quartus_cdb $proj --vqm=$module.vqm
	quartus_cdb $proj --back_annotate=lab
	quartus_cdb $proj --back_annotate=routing
endif

# clean up
rm -f $proj.pof
mv $proj.sof $module.sof

if ($?EVOLUTION_RUN) then
	# program board
	quartus_pgm -c USB-Blaster -m JTAG -o "P;$module.sof" | tee quartus.pgm.log || exit $?

	# check score
	$scripts/read_score.py | tee $module.score.log || exit $?
endif

