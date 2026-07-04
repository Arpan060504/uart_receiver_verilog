module uart_tx_tb;

reg   clk , reset , tx_start ;
reg [7:0] tx_data;
wire tx;

uart_tx uart_test(.clk(clk) , .reset(reset) , .tx_start(tx_start) , .tx_data(tx_data) , .tx(tx) , .busy(busy));

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial 
begin
    reset = 1  ; tx_start = 0; tx_data = 8'h00;
    #12 ; reset = 0;    
    #10 ; tx_start = 1 ; tx_data = 8'hA5;
    #10 tx_start = 0;
    #500 ; tx_start = 1 ; tx_data = 8'h00;
    #10 tx_start = 0;
    #500 ; tx_start = 1 ; tx_data = 8'hff;
    #10 tx_start = 0;

    #500 ; tx_start = 1 ; tx_data = 8'hab;
    #10 tx_start = 0;
    #100 ; tx_start = 1 ; tx_data = 8'h3c;
    #10 tx_start = 0;
    #35 ; $finish();
end

initial 
begin
    $dumpfile("uart_test.vcd");
    $dumpvars(0 , uart_tx_tb);
    $monitor(
            "T=%0t | state=%0d next=%0d | bit=%0d baud=%0d | shift=%h | tx_start=%b tx_data=%h | tx=%b | busy : %b",
                $time,
                uart_test.state,
                uart_test.next_state,
                uart_test.bit_count,
                uart_test.baud_counter,
                uart_test.shift_reg,
                tx_start,
                tx_data,
                tx,
                busy
            );
end
endmodule