module uart_rx_tb;

reg clk, reset, rx ;
wire [7:0] rx_data ;
wire rx_done;

uart_rx uart_test(clk, reset, rx , rx_data ,  rx_done);

initial 
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

initial 
begin
        reset = 1 ; rx = 0;
    #12; reset = 0; rx = 1;
    #70; rx = 0;   // START

    #40; rx = 1;   // D0
    #40; rx = 0;   // D1
    #40; rx = 1;   // D2
    #40; rx = 0;   // D3
    #40; rx = 0;   // D4
    #40; rx = 1;   // D5
    #40; rx = 0;   // D6
    #40; rx = 1;   // D7

    #40; rx = 1;   // STOP

    #65; rx = 0;   // START
    #25; rx = 1 ;// it should entire IDLE

    #60; rx = 0;   // START
    #40; rx = 1;   // D0
    #40; rx = 1;   // D1
    #40; rx = 1;   // D2
    #40; rx = 1;   // D3
    #40; rx = 0;   // D4
    #40; rx = 0;   // D5
    #40; rx = 0;   // D6
    #40; rx = 0;   // D7

    #40; rx = 1;   // STOP
    
    #50; rx = 0;   // START

    #40; rx = 1;    // D0
    #40; rx = 1;    // D1
    #40; rx = 1;    // D2
    #40; rx = 1;    // D3
    #40; rx = 1;    // D4
    #40; rx = 1;    // D5
    #40; rx = 1;    // D6
    #40; rx = 1;    // D7

    #40; rx = 0;    // INVALID STOP BIT ❌

    #50; rx = 1;    // return line to idle

    #60; $finish();
end    
initial 
begin
    $dumpfile("uart_test.vcd");
    $dumpvars(0 , uart_rx_tb);
    $monitor(
            "T=%0t | state=%0d next=%0d | bit=%0d baud=%0d | shift=%h | rx : %b rx_data : %h ,  rx_done : %b",
                $time,
                uart_test.state,
                uart_test.next_state,
                uart_test.bit_count,
                uart_test.baud_counter,
                uart_test.shift_reg,
                rx , rx_data ,  rx_done);
end
endmodule