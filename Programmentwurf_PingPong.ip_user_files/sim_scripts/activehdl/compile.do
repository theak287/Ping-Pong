transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../Programmentwurf_PingPong.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../Programmentwurf_PingPong.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"../../../Programmentwurf_PingPong.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../Programmentwurf_PingPong.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vcom -work xil_defaultlib -93  \
"../../../Programmentwurf_PingPong.srcs/sources_1/new/renderer.vhd" \
"../../../Programmentwurf_PingPong.srcs/sources_1/new/vga_sync.vhd" \
"../../../Programmentwurf_PingPong.srcs/sources_1/new/top.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

