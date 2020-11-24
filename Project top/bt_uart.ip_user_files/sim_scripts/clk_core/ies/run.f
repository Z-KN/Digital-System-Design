-makelib ies_lib/xil_defaultlib -sv \
  "C:/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib ies_lib/xpm \
  "C:/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../bt_uart.srcs/sources_1/ip/clk_core/clk_core_clk_wiz.v" \
  "../../../../bt_uart.srcs/sources_1/ip/clk_core/clk_core.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

