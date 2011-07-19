AJARDSP_ROOT = ../..

INCLUDE = -I$(AJARDSP_ROOT)/rtl/verilog/ -I$(AJARDSP_ROOT)/sim/rtl_sim/src/ddr_sdram_model/

RTL_SIM = \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/BUFG.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/DCM_SP.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/IDDR2.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/ODDR2.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/RAMB16_S9.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/RAMB16_S36.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/RAMB16_S36_S36.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/RAMB16_S18_S18.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/MULT18X18SIO.v \
    $(AJARDSP_ROOT)/sim/rtl_sim/src/ddr_sdram_model/ddr.v

RTL_MODEL= \
    $(AJARDSP_ROOT)/rtl/verilog/soc/sdram_ctrl.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/soc_top.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/tb.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_ajardsp.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_adc_ctrl.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_vga_ctrl.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/vga_font.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_sdram_ctrl.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_ram.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_misc_io.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/wb_debug.v \
    $(AJARDSP_ROOT)/rtl/verilog/soc/uart.v \
    $(AJARDSP_ROOT)/rtl/verilog/ajardsp_top.v \
    $(AJARDSP_ROOT)/rtl/verilog/vliwfetch.v \
    $(AJARDSP_ROOT)/rtl/verilog/vliwdec.v \
    $(AJARDSP_ROOT)/rtl/verilog/pcu.v \
    $(AJARDSP_ROOT)/rtl/verilog/lsu.v \
    $(AJARDSP_ROOT)/rtl/verilog/sp.v \
    $(AJARDSP_ROOT)/rtl/verilog/ptrrf.v \
    $(AJARDSP_ROOT)/rtl/verilog/dmem.v \
    $(AJARDSP_ROOT)/rtl/verilog/imem.v \
    $(AJARDSP_ROOT)/rtl/verilog/accrf.v \
    $(AJARDSP_ROOT)/rtl/verilog/cu.v \
    $(AJARDSP_ROOT)/rtl/verilog/bmu.v \
    $(AJARDSP_ROOT)/rtl/verilog/curegs.v \
    $(AJARDSP_ROOT)/rtl/verilog/int_addsub.v \
    $(AJARDSP_ROOT)/rtl/verilog/int_mul.v \
    $(AJARDSP_ROOT)/rtl/verilog/pred.v

all: ajardsp_soc.vvp
	vvp ajardsp_soc.vvp -lxt2

ajardsp_soc.vvp: $(RTL_SIM) $(RTL_MODEL) tx.hex wb_ram.hex
	iverilog $(INCLUDE) $(RTL_SIM) $(RTL_MODEL) -DSIMULATION_UART -o ajardsp_soc.vvp -s tb
