module stack_behaviour_normal(
    inout wire[3:0] IO_DATA, 
    input wire RESET, 
    input wire CLK, 
    input wire[1:0] COMMAND,
    input wire[2:0] INDEX
    ); 
    
    reg[3:0] memory_cell[4:0];
    integer pointer;
    integer i;

    reg[3:0] result = 4'bzzzz;
    assign IO_DATA = result;

    always @(!CLK) begin
        result = 4'bzzzz;
    end

    always @(CLK or RESET) begin
        if (RESET) begin
            for (i = 0; i < 5; i = i + 1) begin
                memory_cell[i] = 4'b0000;
            end
            pointer = 0;
        end
        else if (CLK) begin
            if (COMMAND == 2'b00) begin
                result = 4'bzzzz;
            end
            if (COMMAND == 2'b01) begin
                memory_cell[pointer] = IO_DATA;
                result = 4'bzzzz;
                pointer = (pointer + 1) % 5;
            end
            if (COMMAND == 2'b10) begin
                pointer = (pointer + 4) % 5;
                result = memory_cell[pointer];
            end
            if (COMMAND == 2'b11) begin
                result = memory_cell[(pointer + 9 - INDEX) % 5];
            end
        end
    end
endmodule
