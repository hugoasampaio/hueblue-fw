/*
 * Generated by Bluespec Compiler, version 2023.01-6-g034050db (build 034050db)
 * 
 * On Fri Apr 14 15:31:52 -03 2023
 * 
 */
#include "bluesim_primitives.h"
#include "mkCounterSynth.h"


/* Constructor */
MOD_mkCounterSynth::MOD_mkCounterSynth(tSimStateHdl simHdl, char const *name, Module *parent)
  : Module(simHdl, name, parent),
    __clk_handle_0(BAD_CLOCK_HANDLE),
    INST_counter(simHdl, "counter", this, 8u, (tUInt8)0u, (tUInt8)0u),
    PORT_RST_N((tUInt8)1u)
{
  symbol_count = 1u;
  symbols = new tSym[symbol_count];
  init_symbols_0();
}


/* Symbol init fns */

void MOD_mkCounterSynth::init_symbols_0()
{
  init_symbol(&symbols[0u], "counter", SYM_MODULE, &INST_counter);
}


/* Rule actions */


/* Methods */

void MOD_mkCounterSynth::METH_cbus_ifc_write(tUInt32 ARG_cbus_ifc_write_addr,
					     tUInt32 ARG_cbus_ifc_write_data)
{
  tUInt8 DEF_cbus_ifc_write_addr_EQ_13___d1;
  tUInt8 DEF_x__h321;
  DEF_x__h321 = (tUInt8)((tUInt8)255u & ARG_cbus_ifc_write_data);
  DEF_cbus_ifc_write_addr_EQ_13___d1 = ARG_cbus_ifc_write_addr == 13u;
  if (DEF_cbus_ifc_write_addr_EQ_13___d1)
    INST_counter.METH_write(DEF_x__h321);
}

tUInt8 MOD_mkCounterSynth::METH_RDY_cbus_ifc_write()
{
  tUInt8 DEF_CAN_FIRE_cbus_ifc_write;
  tUInt8 PORT_RDY_cbus_ifc_write;
  DEF_CAN_FIRE_cbus_ifc_write = (tUInt8)1u;
  PORT_RDY_cbus_ifc_write = DEF_CAN_FIRE_cbus_ifc_write;
  return PORT_RDY_cbus_ifc_write;
}

tUInt64 MOD_mkCounterSynth::METH_cbus_ifc_read(tUInt32 ARG_cbus_ifc_read_addr)
{
  tUInt8 DEF_cbus_ifc_read_addr_EQ_13___d3;
  tUInt64 PORT_cbus_ifc_read;
  DEF_x_device_ifc__read__h386 = INST_counter.METH_read();
  DEF_cbus_ifc_read_addr_EQ_13___d3 = ARG_cbus_ifc_read_addr == 13u;
  PORT_cbus_ifc_read = 8589934591llu & (((((tUInt64)(DEF_cbus_ifc_read_addr_EQ_13___d3)) << 32u) | (((tUInt64)(0u)) << 8u)) | (tUInt64)(DEF_x_device_ifc__read__h386));
  return PORT_cbus_ifc_read;
}

tUInt8 MOD_mkCounterSynth::METH_RDY_cbus_ifc_read()
{
  tUInt8 DEF_CAN_FIRE_cbus_ifc_read;
  tUInt8 PORT_RDY_cbus_ifc_read;
  DEF_CAN_FIRE_cbus_ifc_read = (tUInt8)1u;
  PORT_RDY_cbus_ifc_read = DEF_CAN_FIRE_cbus_ifc_read;
  return PORT_RDY_cbus_ifc_read;
}

tUInt8 MOD_mkCounterSynth::METH_device_ifc_isZero()
{
  tUInt8 PORT_device_ifc_isZero;
  DEF_x_device_ifc__read__h386 = INST_counter.METH_read();
  PORT_device_ifc_isZero = DEF_x_device_ifc__read__h386 == (tUInt8)0u;
  return PORT_device_ifc_isZero;
}

tUInt8 MOD_mkCounterSynth::METH_RDY_device_ifc_isZero()
{
  tUInt8 DEF_CAN_FIRE_device_ifc_isZero;
  tUInt8 PORT_RDY_device_ifc_isZero;
  DEF_CAN_FIRE_device_ifc_isZero = (tUInt8)1u;
  PORT_RDY_device_ifc_isZero = DEF_CAN_FIRE_device_ifc_isZero;
  return PORT_RDY_device_ifc_isZero;
}

void MOD_mkCounterSynth::METH_device_ifc_decrement()
{
  tUInt8 DEF_x__h399;
  DEF_x_device_ifc__read__h386 = INST_counter.METH_read();
  DEF_x__h399 = (tUInt8)255u & (DEF_x_device_ifc__read__h386 - (tUInt8)1u);
  INST_counter.METH_write(DEF_x__h399);
}

tUInt8 MOD_mkCounterSynth::METH_RDY_device_ifc_decrement()
{
  tUInt8 DEF_CAN_FIRE_device_ifc_decrement;
  tUInt8 PORT_RDY_device_ifc_decrement;
  DEF_CAN_FIRE_device_ifc_decrement = (tUInt8)1u;
  PORT_RDY_device_ifc_decrement = DEF_CAN_FIRE_device_ifc_decrement;
  return PORT_RDY_device_ifc_decrement;
}

void MOD_mkCounterSynth::METH_device_ifc_load(tUInt8 ARG_device_ifc_load_newval)
{
  INST_counter.METH_write(ARG_device_ifc_load_newval);
}

tUInt8 MOD_mkCounterSynth::METH_RDY_device_ifc_load()
{
  tUInt8 DEF_CAN_FIRE_device_ifc_load;
  tUInt8 PORT_RDY_device_ifc_load;
  DEF_CAN_FIRE_device_ifc_load = (tUInt8)1u;
  PORT_RDY_device_ifc_load = DEF_CAN_FIRE_device_ifc_load;
  return PORT_RDY_device_ifc_load;
}


/* Reset routines */

void MOD_mkCounterSynth::reset_RST_N(tUInt8 ARG_rst_in)
{
  PORT_RST_N = ARG_rst_in;
  INST_counter.reset_RST(ARG_rst_in);
}


/* Static handles to reset routines */


/* Functions for the parent module to register its reset fns */


/* Functions to set the elaborated clock id */

void MOD_mkCounterSynth::set_clk_0(char const *s)
{
  __clk_handle_0 = bk_get_or_define_clock(sim_hdl, s);
}


/* State dumping routine */
void MOD_mkCounterSynth::dump_state(unsigned int indent)
{
  printf("%*s%s:\n", indent, "", inst_name);
  INST_counter.dump_state(indent + 2u);
}


/* VCD dumping routines */

unsigned int MOD_mkCounterSynth::dump_VCD_defs(unsigned int levels)
{
  vcd_write_scope_start(sim_hdl, inst_name);
  vcd_num = vcd_reserve_ids(sim_hdl, 3u);
  unsigned int num = vcd_num;
  for (unsigned int clk = 0u; clk < bk_num_clocks(sim_hdl); ++clk)
    vcd_add_clock_def(sim_hdl, this, bk_clock_name(sim_hdl, clk), bk_clock_vcd_num(sim_hdl, clk));
  vcd_write_def(sim_hdl, bk_clock_vcd_num(sim_hdl, __clk_handle_0), "CLK", 1u);
  vcd_write_def(sim_hdl, num++, "RST_N", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "x_device_ifc__read__h386", 8u);
  num = INST_counter.dump_VCD_defs(num);
  vcd_write_scope_end(sim_hdl);
  return num;
}

void MOD_mkCounterSynth::dump_VCD(tVCDDumpType dt, unsigned int levels, MOD_mkCounterSynth &backing)
{
  vcd_defs(dt, backing);
  vcd_prims(dt, backing);
}

void MOD_mkCounterSynth::vcd_defs(tVCDDumpType dt, MOD_mkCounterSynth &backing)
{
  unsigned int num = vcd_num;
  if (dt == VCD_DUMP_XS)
  {
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 8u);
  }
  else
    if (dt == VCD_DUMP_CHANGES)
    {
      if ((backing.PORT_RST_N) != PORT_RST_N)
      {
	vcd_write_val(sim_hdl, num, PORT_RST_N, 1u);
	backing.PORT_RST_N = PORT_RST_N;
      }
      ++num;
      if ((backing.DEF_x_device_ifc__read__h386) != DEF_x_device_ifc__read__h386)
      {
	vcd_write_val(sim_hdl, num, DEF_x_device_ifc__read__h386, 8u);
	backing.DEF_x_device_ifc__read__h386 = DEF_x_device_ifc__read__h386;
      }
      ++num;
    }
    else
    {
      vcd_write_val(sim_hdl, num++, PORT_RST_N, 1u);
      backing.PORT_RST_N = PORT_RST_N;
      vcd_write_val(sim_hdl, num++, DEF_x_device_ifc__read__h386, 8u);
      backing.DEF_x_device_ifc__read__h386 = DEF_x_device_ifc__read__h386;
    }
}

void MOD_mkCounterSynth::vcd_prims(tVCDDumpType dt, MOD_mkCounterSynth &backing)
{
  INST_counter.dump_VCD(dt, backing.INST_counter);
}
