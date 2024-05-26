//
// Generated by Bluespec Compiler, version 2024.01-9-gc481d7f5 (build c481d7f5)
//
// On Sun May 26 00:22:24 -03 2024
//
//
// Ports:
// Name                         I/O  size props
// IN                             O    12 reg
// OUT                            O    12 reg
// CLK                            I     1 clock
// RST_N                          I     1 reset
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module mkTb(CLK,
	    RST_N,

	    IN,

	    OUT);
  input  CLK;
  input  RST_N;

  // value method inM
  output [11 : 0] IN;

  // value method outM
  output [11 : 0] OUT;

  // signals for module outputs
  wire [11 : 0] IN, OUT;

  // inlined wires
  wire start_wire$whas, state_set_pw$whas;

  // register fV
  reg [23 : 0] fV;
  wire [23 : 0] fV$D_IN;
  wire fV$EN;

  // register inV
  reg [11 : 0] inV;
  wire [11 : 0] inV$D_IN;
  wire inV$EN;

  // register n
  reg [9 : 0] n;
  wire [9 : 0] n$D_IN;
  wire n$EN;

  // register outV
  reg [23 : 0] outV;
  wire [23 : 0] outV$D_IN;
  wire outV$EN;

  // register running
  reg running;
  wire running$D_IN, running$EN;

  // register start_reg
  reg start_reg;
  wire start_reg$D_IN, start_reg$EN;

  // register start_reg_1
  reg start_reg_1;
  wire start_reg_1$D_IN, start_reg_1$EN;

  // register state_can_overlap
  reg state_can_overlap;
  wire state_can_overlap$D_IN, state_can_overlap$EN;

  // register state_fired
  reg state_fired;
  wire state_fired$D_IN, state_fired$EN;

  // register state_mkFSMstate
  reg [2 : 0] state_mkFSMstate;
  reg [2 : 0] state_mkFSMstate$D_IN;
  wire state_mkFSMstate$EN;

  // ports of submodule cc
  wire [47 : 0] cc$addSample_ns, cc$getFixedSample;
  wire cc$EN_addSample,
       cc$EN_getError,
       cc$EN_getFixedSample,
       cc$RDY_addSample,
       cc$RDY_getFixedSample;

  // rule scheduling signals
  wire WILL_FIRE_RL_action_l28c11,
       WILL_FIRE_RL_action_l34c15,
       WILL_FIRE_RL_action_l35c13,
       WILL_FIRE_RL_fsm_start,
       WILL_FIRE_RL_idle_l27c17,
       WILL_FIRE_RL_idle_l27c17_1;

  // inputs to muxes for submodule ports
  wire [9 : 0] MUX_n$write_1__VAL_1;
  wire MUX_start_reg$write_1__SEL_2, MUX_state_mkFSMstate$write_1__SEL_1;

  // remaining internal signals
  wire abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79,
       n_6_ULT_106___d37;

  // value method inM
  assign IN = inV ;

  // value method outM
  assign OUT = outV[11:0] ;

  // submodule cc
  mkCostasLoopO cc(.CLK(CLK),
		   .RST_N(RST_N),
		   .addSample_ns(cc$addSample_ns),
		   .EN_addSample(cc$EN_addSample),
		   .EN_getFixedSample(cc$EN_getFixedSample),
		   .EN_getError(cc$EN_getError),
		   .RDY_addSample(cc$RDY_addSample),
		   .getFixedSample(cc$getFixedSample),
		   .RDY_getFixedSample(cc$RDY_getFixedSample),
		   .getError(),
		   .RDY_getError());

  // rule RL_action_l34c15
  assign WILL_FIRE_RL_action_l34c15 =
	     cc$RDY_addSample && n_6_ULT_106___d37 &&
	     (state_mkFSMstate == 3'd2 || state_mkFSMstate == 3'd5) ;

  // rule RL_action_l35c13
  assign WILL_FIRE_RL_action_l35c13 =
	     cc$RDY_getFixedSample && state_mkFSMstate == 3'd3 ;

  // rule RL_fsm_start
  assign WILL_FIRE_RL_fsm_start =
	     abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79 &&
	     start_reg ;

  // rule RL_action_l28c11
  assign WILL_FIRE_RL_action_l28c11 =
	     start_wire$whas && state_mkFSMstate == 3'd0 ||
	     !n_6_ULT_106___d37 && start_wire$whas &&
	     state_mkFSMstate == 3'd2 ||
	     !n_6_ULT_106___d37 && start_wire$whas &&
	     state_mkFSMstate == 3'd5 ;

  // rule RL_idle_l27c17
  assign WILL_FIRE_RL_idle_l27c17 =
	     !n_6_ULT_106___d37 && !start_wire$whas &&
	     state_mkFSMstate == 3'd2 ;

  // rule RL_idle_l27c17_1
  assign WILL_FIRE_RL_idle_l27c17_1 =
	     !n_6_ULT_106___d37 && !start_wire$whas &&
	     state_mkFSMstate == 3'd5 ;

  // inputs to muxes for submodule ports
  assign MUX_start_reg$write_1__SEL_2 =
	     abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79 &&
	     !start_reg &&
	     !running ;
  assign MUX_state_mkFSMstate$write_1__SEL_1 =
	     WILL_FIRE_RL_idle_l27c17_1 || WILL_FIRE_RL_idle_l27c17 ;
  assign MUX_n$write_1__VAL_1 = n + 10'd1 ;

  // inlined wires
  assign start_wire$whas =
	     WILL_FIRE_RL_fsm_start || start_reg_1 && !state_fired ;
  assign state_set_pw$whas =
	     WILL_FIRE_RL_idle_l27c17_1 || WILL_FIRE_RL_idle_l27c17 ||
	     state_mkFSMstate == 3'd4 ||
	     WILL_FIRE_RL_action_l35c13 ||
	     WILL_FIRE_RL_action_l34c15 ||
	     state_mkFSMstate == 3'd1 ||
	     WILL_FIRE_RL_action_l28c11 ;

  // register fV
  assign fV$D_IN = { fV[23:12], inV } ;
  assign fV$EN = WILL_FIRE_RL_action_l28c11 ;

  // register inV
  assign inV$D_IN = 12'h0 ;
  assign inV$EN = 1'b0 ;

  // register n
  assign n$D_IN = (state_mkFSMstate == 3'd4) ? MUX_n$write_1__VAL_1 : 10'd0 ;
  assign n$EN = state_mkFSMstate == 3'd4 || state_mkFSMstate == 3'd1 ;

  // register outV
  assign outV$D_IN = cc$getFixedSample[47:24] ;
  assign outV$EN = WILL_FIRE_RL_action_l35c13 ;

  // register running
  assign running$D_IN = 1'd1 ;
  assign running$EN = MUX_start_reg$write_1__SEL_2 ;

  // register start_reg
  assign start_reg$D_IN = !WILL_FIRE_RL_fsm_start ;
  assign start_reg$EN =
	     WILL_FIRE_RL_fsm_start ||
	     abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79 &&
	     !start_reg &&
	     !running ;

  // register start_reg_1
  assign start_reg_1$D_IN = start_wire$whas ;
  assign start_reg_1$EN = 1'd1 ;

  // register state_can_overlap
  assign state_can_overlap$D_IN = state_set_pw$whas || state_can_overlap ;
  assign state_can_overlap$EN = 1'd1 ;

  // register state_fired
  assign state_fired$D_IN = state_set_pw$whas ;
  assign state_fired$EN = 1'd1 ;

  // register state_mkFSMstate
  always@(MUX_state_mkFSMstate$write_1__SEL_1 or
	  WILL_FIRE_RL_action_l28c11 or
	  state_mkFSMstate or
	  WILL_FIRE_RL_action_l34c15 or WILL_FIRE_RL_action_l35c13)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_state_mkFSMstate$write_1__SEL_1: state_mkFSMstate$D_IN = 3'd0;
      WILL_FIRE_RL_action_l28c11: state_mkFSMstate$D_IN = 3'd1;
      state_mkFSMstate == 3'd1: state_mkFSMstate$D_IN = 3'd2;
      WILL_FIRE_RL_action_l34c15: state_mkFSMstate$D_IN = 3'd3;
      WILL_FIRE_RL_action_l35c13: state_mkFSMstate$D_IN = 3'd4;
      state_mkFSMstate == 3'd4: state_mkFSMstate$D_IN = 3'd5;
      default: state_mkFSMstate$D_IN = 3'bxxx /* unspecified value */ ;
    endcase
  end
  assign state_mkFSMstate$EN =
	     WILL_FIRE_RL_idle_l27c17_1 || WILL_FIRE_RL_idle_l27c17 ||
	     WILL_FIRE_RL_action_l28c11 ||
	     state_mkFSMstate == 3'd1 ||
	     WILL_FIRE_RL_action_l34c15 ||
	     WILL_FIRE_RL_action_l35c13 ||
	     state_mkFSMstate == 3'd4 ;

  // submodule cc
  assign cc$addSample_ns = {2{fV}} ;
  assign cc$EN_addSample = WILL_FIRE_RL_action_l34c15 ;
  assign cc$EN_getFixedSample = WILL_FIRE_RL_action_l35c13 ;
  assign cc$EN_getError = 1'b0 ;

  // remaining internal signals
  assign abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79 =
	     (state_mkFSMstate == 3'd0 ||
	      !n_6_ULT_106___d37 && state_mkFSMstate == 3'd2 ||
	      !n_6_ULT_106___d37 && state_mkFSMstate == 3'd5) &&
	     (!start_reg_1 || state_fired) ;
  assign n_6_ULT_106___d37 = n < 10'd106 ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (RST_N == `BSV_RESET_VALUE)
      begin
        fV <= `BSV_ASSIGNMENT_DELAY 24'd4096;
	inV <= `BSV_ASSIGNMENT_DELAY 12'd0;
	n <= `BSV_ASSIGNMENT_DELAY 10'd0;
	outV <= `BSV_ASSIGNMENT_DELAY 24'd0;
	running <= `BSV_ASSIGNMENT_DELAY 1'd0;
	start_reg <= `BSV_ASSIGNMENT_DELAY 1'd0;
	start_reg_1 <= `BSV_ASSIGNMENT_DELAY 1'd0;
	state_can_overlap <= `BSV_ASSIGNMENT_DELAY 1'd1;
	state_fired <= `BSV_ASSIGNMENT_DELAY 1'd0;
	state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY 3'd0;
      end
    else
      begin
        if (fV$EN) fV <= `BSV_ASSIGNMENT_DELAY fV$D_IN;
	if (inV$EN) inV <= `BSV_ASSIGNMENT_DELAY inV$D_IN;
	if (n$EN) n <= `BSV_ASSIGNMENT_DELAY n$D_IN;
	if (outV$EN) outV <= `BSV_ASSIGNMENT_DELAY outV$D_IN;
	if (running$EN) running <= `BSV_ASSIGNMENT_DELAY running$D_IN;
	if (start_reg$EN) start_reg <= `BSV_ASSIGNMENT_DELAY start_reg$D_IN;
	if (start_reg_1$EN)
	  start_reg_1 <= `BSV_ASSIGNMENT_DELAY start_reg_1$D_IN;
	if (state_can_overlap$EN)
	  state_can_overlap <= `BSV_ASSIGNMENT_DELAY state_can_overlap$D_IN;
	if (state_fired$EN)
	  state_fired <= `BSV_ASSIGNMENT_DELAY state_fired$D_IN;
	if (state_mkFSMstate$EN)
	  state_mkFSMstate <= `BSV_ASSIGNMENT_DELAY state_mkFSMstate$D_IN;
      end
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    fV = 24'hAAAAAA;
    inV = 12'hAAA;
    n = 10'h2AA;
    outV = 24'hAAAAAA;
    running = 1'h0;
    start_reg = 1'h0;
    start_reg_1 = 1'h0;
    state_can_overlap = 1'h0;
    state_fired = 1'h0;
    state_mkFSMstate = 3'h2;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on

  // handling of system tasks

  // synopsys translate_off
  always@(negedge CLK)
  begin
    #0;
    if (RST_N != `BSV_RESET_VALUE)
      if (state_mkFSMstate == 3'd1 &&
	  (WILL_FIRE_RL_action_l34c15 || WILL_FIRE_RL_action_l35c13 ||
	   state_mkFSMstate == 3'd4))
	$display("Error: \"Tb_tang.bsv\", line 32, column 15: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_action_f_init_l32c9] and\n  [RL_action_l34c15, RL_action_l35c13, RL_action_f_update_l32c9] ) fired in\n  the same clock cycle.\n");
    if (RST_N != `BSV_RESET_VALUE)
      if (WILL_FIRE_RL_action_l34c15 &&
	  (WILL_FIRE_RL_action_l35c13 || state_mkFSMstate == 3'd4))
	$display("Error: \"Tb_tang.bsv\", line 34, column 15: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_action_l34c15] and\n  [RL_action_l35c13, RL_action_f_update_l32c9] ) fired in the same clock\n  cycle.\n");
    if (RST_N != `BSV_RESET_VALUE)
      if (WILL_FIRE_RL_action_l35c13 && state_mkFSMstate == 3'd4)
	$display("Error: \"Tb_tang.bsv\", line 35, column 13: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_action_l35c13] and\n  [RL_action_f_update_l32c9] ) fired in the same clock cycle.\n");
    if (RST_N != `BSV_RESET_VALUE)
      if (WILL_FIRE_RL_action_l28c11 &&
	  (state_mkFSMstate == 3'd1 || WILL_FIRE_RL_action_l34c15 ||
	   WILL_FIRE_RL_action_l35c13 ||
	   state_mkFSMstate == 3'd4))
	$display("Error: \"Tb_tang.bsv\", line 28, column 11: (R0001)\n  Mutually exclusive rules (from the ME sets [RL_action_l28c11] and\n  [RL_action_f_init_l32c9, RL_action_l34c15, RL_action_l35c13,\n  RL_action_f_update_l32c9] ) fired in the same clock cycle.\n");
    if (RST_N != `BSV_RESET_VALUE)
      if (running &&
	  abort_whas_AND_abort_wget_OR_state_mkFSMstate__ETC___d79 &&
	  !start_reg)
	$finish(32'd0);
  end
  // synopsys translate_on
endmodule  // mkTb

