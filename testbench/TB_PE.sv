`timescale 1ns / 1ps

module PE_tb;

    //====================================================
    // SIGNALS
    //====================================================

    reg clk;
    reg rst;
    reg init;
    reg en;
    reg valid_in;

    reg signed [7:0] a;
    reg signed [7:0] b;

    wire signed [7:0] a_out;
    wire signed [7:0] b_out;
    wire signed [31:0] c_out;

    wire valid_out;

    //====================================================
    // DUT
    //====================================================

    PE dut (

        .clk(clk),
        .rst(rst),
        .init(init),
        .en(en),
        .valid_in(valid_in),

        .a(a),
        .b(b),

        .a_out(a_out),
        .b_out(b_out),
        .c_out(c_out),

        .valid_out(valid_out)
    );

    //====================================================
    // CLOCK
    //====================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //====================================================
    // SEND DATA
    //====================================================

    task send_data;

        input signed [7:0] ta;
        input signed [7:0] tb;

        input tvalid;
        input tinit;
        input ten;

        begin

            @(posedge clk);

            a        <= ta;
            b        <= tb;

            valid_in <= tvalid;
            init     <= tinit;
            en       <= ten;

        end

    endtask

    //====================================================
    // WAIT FOR 3-STAGE PIPELINE
    //====================================================

    task wait_pipeline;
        begin

            @(posedge clk);
            @(posedge clk);
            @(posedge clk);

            #1;

        end
    endtask

    //====================================================
    // MAIN TEST
    //====================================================

    initial begin

        //------------------------------------------------
        // INIT
        //------------------------------------------------

        a        = 0;
        b        = 0;

        rst      = 1;
        init     = 0;
        en       = 1;
        valid_in = 0;

        //------------------------------------------------
        // RESET
        //------------------------------------------------

        #20;
        rst = 0;

        //------------------------------------------------
        // TEST 1
        //------------------------------------------------

        $display("====================================");
        $display("TEST1 : BASIC MULT");
        $display("====================================");

        send_data(8'sd2, 8'sd3, 1'b1, 1'b1, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 6 && valid_out)
            $display("PASS TEST1");
        else
            $display("FAIL TEST1 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 2
        //------------------------------------------------

        $display("====================================");
        $display("TEST2 : ACCUMULATION");
        $display("====================================");

        send_data(8'sd4, 8'sd5, 1'b1, 1'b0, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 26)
            $display("PASS TEST2");
        else
            $display("FAIL TEST2 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 3
        //------------------------------------------------

        $display("====================================");
        $display("TEST3 : NEGATIVE");
        $display("====================================");

        send_data(-8'sd2, 8'sd7, 1'b1, 1'b0, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 12)
            $display("PASS TEST3");
        else
            $display("FAIL TEST3 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 4
        //------------------------------------------------

        $display("====================================");
        $display("TEST4 : VALID = 0");
        $display("====================================");

        send_data(8'sd9, 8'sd9, 1'b0, 1'b0, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 12)
            $display("PASS TEST4");
        else
            $display("FAIL TEST4 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 5
        //------------------------------------------------

        $display("====================================");
        $display("TEST5 : ENABLE = 0");
        $display("====================================");

        send_data(8'sd5, 8'sd5, 1'b1, 1'b0, 1'b0);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 12)
            $display("PASS TEST5");
        else
            $display("FAIL TEST5 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 6
        //------------------------------------------------

        $display("====================================");
        $display("TEST6 : INIT RESET");
        $display("====================================");

        send_data(8'sd3, 8'sd3, 1'b1, 1'b1, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 9)
            $display("PASS TEST6");
        else
            $display("FAIL TEST6 c_out=%d", c_out);

        //------------------------------------------------
        // TEST 7
        //------------------------------------------------

        $display("====================================");
        $display("TEST7 : FORWARDING");
        $display("====================================");

        send_data(8'sd11, -8'sd4, 1'b1, 1'b0, 1'b1);

        @(posedge clk);
        #1;

        if(a_out == 11 && b_out == -4)
            $display("PASS TEST7");
        else
            $display("FAIL TEST7 a_out=%d b_out=%d",
                      a_out, b_out);

        //------------------------------------------------
        // TEST 8
        //------------------------------------------------

        $display("====================================");
        $display("TEST8 : MULTI ACC");
        $display("====================================");

        send_data(8'sd1, 8'sd1, 1'b1, 1'b1, 1'b1);
        send_data(8'sd2, 8'sd2, 1'b1, 1'b0, 1'b1);
        send_data(8'sd3, 8'sd3, 1'b1, 1'b0, 1'b1);

        send_data(0,0,0,0,1);

        wait_pipeline();

        if(c_out == 14)
            $display("PASS TEST8");
        else
            $display("FAIL TEST8 c_out=%d", c_out);

        //------------------------------------------------
        // FINISH
        //------------------------------------------------

        $display("====================================");
        $display("SIMULATION FINISHED");
        $display("====================================");

        #20;
        $finish;

    end

    //====================================================
    // MONITOR
    //====================================================


initial begin

    $monitor(
        "TIME=%0t | a=%d b=%d | a_reg=%d b_reg=%d | mult=%d | valid1=%b valid2=%b valid_out=%b | acc=%d",

        $time,

        a,
        b,

        dut.a_reg,
        dut.b_reg,

        dut.mult,

        dut.valid_reg_1,
        dut.valid_reg_2,
        valid_out,

        c_out
    );

end

endmodule
