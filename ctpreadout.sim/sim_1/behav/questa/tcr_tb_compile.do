######################################################################
#
# File name : tcr_tb_compile.do
# Created on: Wed May 11 14:39:21 +0200 2022
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
C:\\questasim64_10.6c\\win64\\vlib questa_lib/work
C:\\questasim64_10.6c\\win64\\vlib questa_lib/msim

C:\\questasim64_10.6c\\win64\\vlib questa_lib/msim/xil_defaultlib

C:\\questasim64_10.6c\\win64\\vmap xil_defaultlib questa_lib/msim/xil_defaultlib

C:\\questasim64_10.6c\\win64\\vlog -64 -incr -work xil_defaultlib  \
"../../../../ctpreadout.ip_user_files/ip/tc_fifo/sim/tc_fifo.v" \

C:\\questasim64_10.6c\\win64\\vcom -64 -93 -work xil_defaultlib  \
"../../../../ctpreadout.srcs/sources_1/imports/alice/IRandTCR/Trigger_class_record/buffer_fifo.vhd" \
"../../../../ctpreadout.srcs/sources_1/imports/alice/IRandTCR/Trigger_class_record/packer.vhd" \
"../../../../ctpreadout.srcs/sources_1/imports/alice/IRandTCR/Trigger_class_record/prsg_tcr.vhd" \
"../../../../ctpreadout.srcs/sources_1/imports/alice/IRandTCR/Trigger_class_record/tc_statemachine.vhd" \
"../../../../ctpreadout.srcs/sources_1/imports/alice/IRandTCR/Trigger_class_record/top_tc_statemachine.vhd" \

C:\\questasim64_10.6c\\win64\\vcom -64 -2008 -work xil_defaultlib  \
"../../../../Trigger_class_record/TCR_tb.vhd" \

# compile glbl module
C:\\questasim64_10.6c\\win64\\vlog -work xil_defaultlib "glbl.v"

quit -force

