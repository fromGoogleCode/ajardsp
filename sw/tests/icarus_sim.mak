INCLUDE = -I../../rtl/verilog/ -I../../rtl/verilog/soc/ddr_sdram_model/
RTL_SIM = ../../rtl/verilog/soc/BUFG.v \
    ../../rtl/verilog/soc/DCM_SP.v \
    ../../rtl/verilog/soc/IDDR2.v \
    ../../rtl/verilog/soc/ODDR2.v \
    ../../rtl/verilog/soc/RAMB16_S9.v \
    ../../rtl/verilog/soc/RAMB16_S36.v \
    ../../rtl/verilog/soc/RAMB16_S36_S36.v \
    ../../rtl/verilog/soc/RAMB16_S18_S18.v \
    ../../rtl/verilog/soc/MULT18X18SIO.v \
    ../../rtl/verilog/soc/ddr_sdram_model/ddr.v

RTL_MODEL= \
    ../../rtl/verilog/soc/sdram_ctrl.v \
    ../../rtl/verilog/soc/soc_top.v \
    ../../rtl/verilog/soc/tb.v \
    ../../rtl/verilog/soc/wb_ajardsp.v \
    ../../rtl/verilog/soc/wb_adc_ctrl.v \
    ../../rtl/verilog/soc/wb_vga_ctrl.v \
    ../../rtl/verilog/soc/vga_font.v \
    ../../rtl/verilog/soc/wb_sdram_ctrl.v \
    ../../rtl/verilog/soc/wb_ram.v \
    ../../rtl/verilog/soc/wb_misc_io.v \
    ../../rtl/verilog/soc/wb_debug.v \
    ../../rtl/verilog/soc/uart.v \
    ../../rtl/verilog/ajardsp_top.v \
    ../../rtl/verilog/vliwfetch.v \
    ../../rtl/verilog/vliwdec.v \
    ../../rtl/verilog/pcu.v \
    ../../rtl/verilog/lsu.v \
    ../../rtl/verilog/sp.v \
    ../../rtl/verilog/ptrrf.v \
    ../../rtl/verilog/dmem.v \
    ../../rtl/verilog/imem.v \
    ../../rtl/verilog/accrf.v \
    ../../rtl/verilog/cu.v \
    ../../rtl/verilog/bmu.v \
    ../../rtl/verilog/curegs.v \
    ../../rtl/verilog/int_addsub.v \
    ../../rtl/verilog/int_mul.v \
    ../../rtl/verilog/pred.v

all: ajardsp_soc.vvp
	vvp ajardsp_soc.vvp -lxt2

ajardsp_soc.vvp: $(RTL_SIM) $(RTL_MODEL) tx.hex wb_ram.hex
	iverilog $(INCLUDE) $(RTL_SIM) $(RTL_MODEL) -DSIMULATION_UART -DIMEM_FILE='"workdir/m_if_07_.imem"' -DDMEM_IN_FILE='"workdir/m_if_07_.dmem"' -DDMEM_OUT_FILE='"workdir/m_if_07_.res"' -o ajardsp_soc.vvp -s tb
