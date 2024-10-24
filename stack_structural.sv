module stack_structural_normal(
    inout wire[3:0] IO_DATA, 
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX
    ); 

    wire PUSH, POP, GET;
    push g0(PUSH, COMMAND);
    pop g1(POP, COMMAND);
    get g2(GET, COMMAND);

    wire NPUSH, NPOP, NGET;
    not(NPUSH, PUSH);
    not(NPOP, POP);
    not(NGET, GET);

    wire[3:0] I_DATA;
    wire[3:0] O_DATA;

    cmos4 g3(IO_DATA, I_DATA, PUSH, NPUSH);

    stack_interface g5(I_DATA, O_DATA, RESET, CLK, COMMAND, INDEX);

    wire w0, w1, w2;
    or(w0, POP, GET);
    and(w1, w0, CLK);
    not(w2, w1);

    cmos4 g4(O_DATA, IO_DATA, w1, w2);
endmodule

module cmos4(
    inout wire[3:0] I_DATA,  
    output wire[3:0] O_DATA,
    input wire p_ctrl,
    input wire n_ctrl
    );
    cmos p0(O_DATA[0], I_DATA[0], p_ctrl, n_ctrl);
    cmos p1(O_DATA[1], I_DATA[1], p_ctrl, n_ctrl);
    cmos p2(O_DATA[2], I_DATA[2], p_ctrl, n_ctrl);
    cmos p3(O_DATA[3], I_DATA[3], p_ctrl, n_ctrl);
endmodule

module push(
    output wire PUSH,
    input wire[1:0] COMMAND
    );

    wire ncmd0;
    wire ncmd1;
    not(ncmd0, COMMAND[0]);
    not(ncmd1, COMMAND[1]);

    and(PUSH, ncmd1, COMMAND[0]);
endmodule

module pop(
    output wire POP,
    input wire[1:0] COMMAND
    );

    wire ncmd0;
    wire ncmd1;
    not(ncmd0, COMMAND[0]);
    not(ncmd1, COMMAND[1]);

    and(POP, ncmd0, COMMAND[1]);
endmodule

module get(
    output wire GET,
    input wire[1:0] COMMAND
    );

    and(GET, COMMAND[1], COMMAND[0]);
endmodule

module stack_interface(
    input wire[3:0] I_DATA, 
    output wire[3:0] O_DATA, 
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX
    );

    wire WRITE_FLAG;
    wire[2:0] STACK_POINTER;
    wire[2:0] ASK_INDEX;

    get_stack_pointer g0(RESET, CLK, COMMAND, STACK_POINTER);
    parser g1(CLK, COMMAND, INDEX, STACK_POINTER, WRITE_FLAG, ASK_INDEX);
    big_memory g2(RESET, WRITE_FLAG, ASK_INDEX, I_DATA, O_DATA);
endmodule

module big_memory(
    input wire RESET, 
    input wire CLK, 
    input wire[2:0] INDEX,
    input wire[3:0] IN_DATA, 
    output wire[3:0] O_DATA
    );

    wire[2:0] w0;
    mod_5 g6(INDEX, w0);

    wire[4:0] SYNC;
    demux g0(CLK, INDEX, SYNC);

    wire[3:0] w2, w3, w4, w5, w6;
    memory_cell4 g1(RESET, SYNC[0], IN_DATA, w2);
    memory_cell4 g2(RESET, SYNC[1], IN_DATA, w3);
    memory_cell4 g3(RESET, SYNC[2], IN_DATA, w4);
    memory_cell4 g4(RESET, SYNC[3], IN_DATA, w5);
    memory_cell4 g5(RESET, SYNC[4], IN_DATA, w6);

    mux4 g7(INDEX, w2, w3, w4, w5, w6, O_DATA);
endmodule

module mux4(
    input wire[2:0] INDEX,
    input wire[3:0] a, b, c, d, e,
    output wire[3:0] O_DATA
    );

    mux g0(INDEX, a[0], b[0], c[0], d[0], e[0], O_DATA[0]);
    mux g1(INDEX, a[1], b[1], c[1], d[1], e[1], O_DATA[1]);
    mux g2(INDEX, a[2], b[2], c[2], d[2], e[2], O_DATA[2]);
    mux g3(INDEX, a[3], b[3], c[3], d[3], e[3], O_DATA[3]);
endmodule

module mux(
    input wire[2:0] INDEX,
    input wire IN0, IN1, IN2, IN3, IN4,
    output wire OUT_DATA
    );

    wire Q0, Q1, Q2, Q3, Q4;
    decoder g0(INDEX[0], INDEX[1], INDEX[2], Q0, Q1, Q2, Q3, Q4);

    wire w0, w1, w2, w3, w4;
    and(w0, IN0, Q0);
    and(w1, IN1, Q1);
    and(w2, IN2, Q2);
    and(w3, IN3, Q3);
    and(w4, IN4, Q4);

    or5 g1(w0, w1, w2, w3, w4, OUT_DATA);
endmodule

module or5(
    input wire w0, w1, w2, w3, w4,
    output wire ow
    );

    wire t0, t1, t2;

    or(t0, w0, w1);
    or(t1, t0, w2);
    or(t2, t1, w3);
    or(ow, t2, w4);
endmodule

module memory_cell4(
    input wire RESET, 
    input wire CLK, 
    input wire[3:0] IN_DATA, 
    output wire[3:0] O_DATA
    );

    wire w0, w1, w2, w3;

    d_trigger g0(IN_DATA[0], CLK, RESET, O_DATA[0], w0);
    d_trigger g1(IN_DATA[1], CLK, RESET, O_DATA[1], w1);
    d_trigger g2(IN_DATA[2], CLK, RESET, O_DATA[2], w2);
    d_trigger g3(IN_DATA[3], CLK, RESET, O_DATA[3], w3);
endmodule

module sync_rs_trigger(
    input wire r, s, RESET, CLK, 
    output wire q, nq);
    wire t0, t1;

    and(t0, r, CLK);
    and(t1, s, CLK);

    rs_trigger g0(t0, t1, RESET, q, nq);
endmodule

module rs_trigger(
    input wire r, s, RESET, 
    output wire q, nq
    );
    wire t;

    or(nq, RESET, t);
    nor(q, r, nq);
    nor(t, s, q);
endmodule

module decoder(
    input wire A0, A1, A2,
    output wire Q0, Q1, Q2, Q3, Q4
    );

    wire NA0, NA1, NA2;
    not(NA0, A0);
    not(NA1, A1);
    not(NA2, A2);

    and3 g0(Q0, NA0, NA1, NA2);
    and3 g1(Q1, A0, NA1, NA2);
    and3 g2(Q2, NA0, A1, NA2);
    and3 g3(Q3, A0, A1, NA2);
    and3 g4(Q4, NA0, NA1, A2);
endmodule

module demux(
    input wire CLK, 
    input wire[2:0] INDEX,
    output wire[4:0] O_DATA
    );

    wire w0, w1, w2, w3, w4;
    decoder g0(INDEX[0], INDEX[1], INDEX[2], w0, w1, w2, w3, w4);

    and(O_DATA[0], w0, CLK);
    and(O_DATA[1], w1, CLK);
    and(O_DATA[2], w2, CLK);
    and(O_DATA[3], w3, CLK);
    and(O_DATA[4], w4, CLK);
endmodule

module mod_5(
    input wire[2:0] I_DATA,
    output wire[2:0] O_DATA
    );
    wire n0, n1, n2;
    not(n0, I_DATA[0]);
    not(n1, I_DATA[1]); 
    not(n2, I_DATA[2]);

    wire w0, w1, w2, w3, w4, w5, w6, w7;
    and(w0, I_DATA[0], I_DATA[1]);
    and(w1, I_DATA[1], I_DATA[2]);
    and(w2, n2, I_DATA[0]);
    and(w3, n2, I_DATA[1]);
    and(w4, n0, n1);
    and(w5, n0, w1);
    and(O_DATA[2], w4, I_DATA[2]);
    and(w7, w0, I_DATA[2]);
    or(O_DATA[1], w7, w3);
    or(O_DATA[0], w2, w5);
endmodule

module parser(
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX,
    input wire[2:0] STACK_POINTER,
    output wire WRITE_FLAG,
    output wire[2:0] ASK_INDEX
    );

    wire PUSH, POP, GET;
    push g0(PUSH, COMMAND);
    pop g1(POP, COMMAND);
    get g2(GET, COMMAND);

    and(WRITE_FLAG, PUSH, CLK);

    wire[2:0] Y;
    shifter g3(INDEX, Y);

    wire[2:0] INDEX_A, INDEX_B;
    count_sum_mod5 g4(STACK_POINTER, Y, INDEX_B);
    shift_point g5(COMMAND, STACK_POINTER, INDEX_A);

    wire A, B, t;
    and(t, POP, CLK);
    or(A, PUSH, t);
    and(B, GET, CLK);

    select_index g6(A, B, INDEX_A, INDEX_B, ASK_INDEX);
endmodule

module select_index(
    input wire A, B,
    input wire[2:0] INDEX_A, INDEX_B,
    output wire[2:0] ASK_INDEX
    );

    wire a0, a1, a2;
    wire b0, b1, b2;

    and(a0, A, INDEX_A[0]);
    and(a1, A, INDEX_A[1]);
    and(a2, A, INDEX_A[2]);

    and(b0, B, INDEX_B[0]);
    and(b1, B, INDEX_B[1]);
    and(b2, B, INDEX_B[2]);

    or(ASK_INDEX[0], a0, b0);
    or(ASK_INDEX[1], a1, b1);
    or(ASK_INDEX[2], a2, b2);
endmodule

module shift_point(
    input wire[1:0] COMMAND,
    input wire[2:0] POINTER,
    output wire[2:0] SHIFTED_POINT
    );

    wire PUSH, POP, GET;
    push g0(PUSH, COMMAND);
    pop g1(POP, COMMAND);
    get g2(GET, COMMAND);

    wire[2:0] S;
    mod5_calculate g3(POINTER, 1'b1, S);

    wire w0, w1, w2;
    and(w0, POP, S[0]);
    and(w1, POP, S[1]);
    and(w2, POP, S[2]);

    wire w3, w4, w5;
    and(w3, PUSH, POINTER[0]);
    and(w4, PUSH, POINTER[1]);
    and(w5, PUSH, POINTER[2]);

    or(SHIFTED_POINT[0], w0, w3);
    or(SHIFTED_POINT[1], w1, w4);
    or(SHIFTED_POINT[2], w2, w5);
endmodule

module mod5_calculate(
    input wire[2:0] IN_DATA,
    input wire PM, 
    output wire[2:0] CURRENT_POINTER
    );

    wire T0, T1;
    wire X, Y, Z, W, V, K, L, M, N, A, B, G, D, E, F;
    wire NPM, NIN0;

    wire[2:0] I_DATA;
    mod_5 g(IN_DATA, I_DATA);

    or U0(T0, I_DATA[0], I_DATA[1]);
    or U1(T1, T0, I_DATA[2]);
    not U2(X, T1);
    nand U3(Y, I_DATA[0], I_DATA[1]);
    nor U4(Z, Y, I_DATA[2]);
    not U5(NPM, PM);
    and U6(W, X, PM);
    and U7(V, Z, NPM);
    xor U8(K, I_DATA[0], I_DATA[1]);
    and U9(L, K, NPM);
    xor U10(M, I_DATA[1], I_DATA[2]);
    not U11(N, K);
    and U12(A, M, N);
    and U13(B, A, PM);
    not U14(NIN0, I_DATA[0]);
    and U15(G, M, NIN0);
    and U16(D, G, PM);
    nor U17(E, I_DATA[0], I_DATA[2]);
    and U18(F, E, NPM);

    or U19(CURRENT_POINTER[0], F, D);
    or U20(CURRENT_POINTER[1], B, L);
    or U21(CURRENT_POINTER[2], W, V);
endmodule

module shifter(
    input wire[2:0] INP_DATA,
    output wire[2:0] OUT_DATA
    );
    wire[2:0] t;
    mod_5 g0(INP_DATA, t);

    assign OUT_DATA[0] = t[0];
    xor(OUT_DATA[1], t[0], t[1]);

    wire w0, w1;
    or(w0, t[0], t[1]);
    or(w1, w0, t[2]);
    not(OUT_DATA[2], w1);
endmodule

module get_stack_pointer(
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    output wire[2:0] STACK_POINTER
    );  

    wire PUSH, POP, GET;
    push g0(PUSH, COMMAND);
    pop g1(POP, COMMAND);
    get g2(GET, COMMAND);

    wire w0, w1, nw0, nw1;
    d_trigger g3(PUSH, CLK, RESET, w0, nw0);
    d_trigger g4(POP, CLK, RESET, w1, nw1);

    wire NCLK;
    not(NCLK, CLK);

    wire w2, w3;
    and(w2, w0, NCLK);
    and(w3, w1, NCLK);

    wire w4;
    nand(w4, w2, w3);

    wire w5;
    or(w5, w2, w3);

    wire SHIFT_FLAG;
    and(SHIFT_FLAG, w5, w4);
    wire NSHIFT_FLAG;
    not(NSHIFT_FLAG, SHIFT_FLAG);

    wire[2:0] DATA, T0, T1;
    memory_cell3 g5(RESET, NSHIFT_FLAG, DATA, T0);
    mod5_calculate g6(T0, w3, T1);
    memory_cell3 g7(RESET, SHIFT_FLAG, T1, DATA);

    assign STACK_POINTER = DATA;
endmodule

module d_trigger(
    input wire d, CLK, RESET, 
    output wire q, nq);
    wire nd;
    not(nd, d);

    sync_rs_trigger g0(nd, d, RESET, CLK, q, nq);
endmodule

module memory_cell3(
    input wire RESET, 
    input wire CLK, 
    input wire[2:0] IN_DATA, 
    output wire[2:0] O_DATA
    );

    wire w0, w1, w2;

    d_trigger g0(IN_DATA[0], CLK, RESET, O_DATA[0], w0);
    d_trigger g1(IN_DATA[1], CLK, RESET, O_DATA[1], w1);
    d_trigger g2(IN_DATA[2], CLK, RESET, O_DATA[2], w2);
endmodule

module count_sum_mod5(
    input wire[2:0] X_IN,
    input wire[2:0] Y_IN,
    output wire[2:0] SUM
    );

    wire[2:0] X, Y;
    mod_5 g0(X_IN, X);
    mod_5 g1(Y_IN, Y);

    wire[2:0] A, B, C;
    count_sum34 g2(X, Y, A);
    count_sum22 g3(X, Y, B);
    count_sum0 g4(X, Y, C);

    wire SUM0, SUM1, SUM2;

    or3 g5(A[0], B[0], C[0], SUM0);    
    or3 g6(A[1], B[1], C[1], SUM1);    
    or3 g7(A[2], B[2], C[2], SUM2);    

    assign SUM[0] = SUM0;
    assign SUM[1] = SUM1;
    assign SUM[2] = SUM2;
endmodule

module count_sum0(
    input wire[2:0] X_IN,
    input wire[2:0] Y_IN,
    output wire[2:0] SUM
    );

    wire w0;
    or3 g0(Y_IN[0], Y_IN[1], Y_IN[2], w0);
    wire ZERO_Y;
    not(ZERO_Y, w0);

    wire[2:0] SUM_X;
    and(SUM_X[0], X_IN[0], ZERO_Y);
    and(SUM_X[1], X_IN[1], ZERO_Y);
    and(SUM_X[2], X_IN[2], ZERO_Y);

    wire w1;
    or3 g1(X_IN[0], X_IN[1], X_IN[2], w1);
    wire ZERO_X;
    not(ZERO_X, w1);

    wire[2:0] SUM_Y;
    and(SUM_Y[0], Y_IN[0], ZERO_X);
    and(SUM_Y[1], Y_IN[1], ZERO_X);
    and(SUM_Y[2], Y_IN[2], ZERO_X);

    or(SUM[0], SUM_X[0], SUM_Y[0]);
    or(SUM[1], SUM_X[1], SUM_Y[1]);
    or(SUM[2], SUM_X[2], SUM_Y[2]);
endmodule

module count_sum22(
    input wire[2:0] X_IN,
    input wire[2:0] Y_IN,
    output wire[2:0] SUM
    );

    wire w0, w1;
    less2 g0(X_IN, w0);
    less2 g1(Y_IN, w1);
    wire FLAG;
    and(FLAG, w0, w1);

    wire w2, w3;
    xor(w2, X_IN[0], Y_IN[0]);
    xor(w3, X_IN[1], Y_IN[1]);
    wire NEQ;
    or(NEQ, w2, w3);

    wire[2:0] TWO, THREE, FOUR;
    wire EQ;
    not(EQ, NEQ);

    wire w4, w5;
    and(w4, EQ, X_IN[0]);
    and(w5, EQ, X_IN[1]);

    assign TWO[0] = 1'b0;
    assign TWO[1] = w4;
    assign TWO[2] = 1'b0;

    assign THREE[0] = NEQ;
    assign THREE[1] = NEQ;
    assign THREE[2] = 1'b0;

    assign FOUR[0] = 1'b0;
    assign FOUR[1] = 1'b0;
    assign FOUR[2] = w5;

    wire w6, w7, w8;
    or3 g2(TWO[0], THREE[0], FOUR[0], w6);
    or3 g3(TWO[1], THREE[1], FOUR[1], w7);
    or3 g4(TWO[2], THREE[2], FOUR[2], w8);

    and(SUM[0], FLAG, w6);
    and(SUM[1], FLAG, w7);
    and(SUM[2], FLAG, w8);
endmodule

module and3(
    output wire ow,
    input wire w0, w1, w2
    );

    wire t0;
    and(t0, w0, w1);
    and(ow, t0, w2);
endmodule

module count_sum34(
    input wire[2:0] X_IN,
    input wire[2:0] Y_IN,
    output wire[2:0] SUM
    );

    wire s0, s1, s2;
    xor(s0, X_IN[0], Y_IN[0]);
    xor(s1, X_IN[1], Y_IN[1]);
    xor(s2, X_IN[2], Y_IN[2]);

    wire w0;
    and3 g0(w0, s0, s1, s2);

    wire[2:0] ONE, TWO, THREE, FOUR;

    assign TWO[0] = 1'b0;
    assign TWO[1] = w0;
    assign TWO[2] = 1'b0;

    wire ns0, ns2;
    not(ns0, s0);
    not(ns2, s2);
    and3 g1(FOUR[2], ns0, s1, ns2);
    assign FOUR[0] = 1'b0;
    assign FOUR[1] = 1'b0;

    wire w1, nw1;
    nand(w1, X_IN[2], Y_IN[2]);
    not(nw1, w1);
    assign THREE[0] = nw1;
    assign THREE[1] = nw1;
    assign THREE[2] = 1'b0;

    wire w2, nw2;
    xor(w2, s1, s2);
    not(nw2, w2);
    and3 g2(ONE[0], w1, nw2, ns0);
    assign ONE[1] = 1'b0;
    assign ONE[2] = 1'b0;

    wire w3, w4, w5;
    or3 g3(X_IN[0], X_IN[1], X_IN[2], w3);
    or3 g4(Y_IN[0], Y_IN[1], Y_IN[2], w4);
    and(w5, w3, w4);

    wire w6, w7, w8;
    less2 g5(X_IN, w6);
    less2 g6(Y_IN, w7);
    nand(w8, w6, w7);

    wire FLAG;
    and(FLAG, w5, w8);

    wire w9, w10, w11;
    or4 g7(ONE[0], TWO[0], THREE[0], FOUR[0], w9);
    or4 g8(ONE[1], TWO[1], THREE[1], FOUR[1], w10);
    or4 g9(ONE[2], TWO[2], THREE[2], FOUR[2], w11);

    and(SUM[0], FLAG, w9);
    and(SUM[1], FLAG, w10);
    and(SUM[2], FLAG, w11);
endmodule

module or4(
    input wire iw0, iw1, iw2, iw3,
    output wire ow
    );

    wire t0, t1;

    or(t0, iw0, iw1);
    or(t1, t0, iw2);
    or(ow, t1, iw3);
endmodule

module less2(
    input wire[2:0] INP,
    output wire is_less
    );

    wire w0, w1, w2;
    and(w0, INP[0], INP[1]);
    nor(w1, w0, INP[2]);

    or3 g0(INP[0], INP[1], INP[2], w2);

    and(is_less, w2, w1);
endmodule

module or3(
    input wire iw0, iw1, iw2,
    output wire ow
    );

    wire t0;

    or(t0, iw0, iw1);
    or(ow, t0, iw2);
endmodule
