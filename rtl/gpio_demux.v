module gpio_demux (
    input  wire [7:0] gpio_out,   
    input  wire       sel,        
    output reg  [7:0] port_a,    
    output reg  [7:0] port_b      
);

    always @(*) begin
        case (sel)
            1'b0: begin
                port_a = gpio_out;
                port_b = 8'b0;
            end
            1'b1: begin
                port_a = 8'b0;
                port_b = gpio_out;
            end
        endcase
    end

endmodule
