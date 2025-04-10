`timescale 1ns/1ps

module testbench;
    parameter WIDTH = 32;
    parameter FRAC_BITS = 30;
    
    reg [WIDTH-1:0] x00, x01, x10, x11;
    wire [WIDTH-1:0] pool_out;
    integer infile, outfile, status;
    real temp_x00, temp_x01, temp_x10, temp_x11;
    real y_real;
    reg file_error;
    
    function real fixed_to_real;
        input [WIDTH-1:0] fixed_point;
        begin
            fixed_to_real = $itor(fixed_point) / (2.0 ** FRAC_BITS);
        end
    endfunction
    
    aad_pooling_2x2 uut (
        .x00(x00),
        .x01(x01),
        .x10(x10),
        .x11(x11),
        .pool_out(pool_out)
    );
    
    initial begin
        $display("Starting simulation...");
        file_error = 0;
        
        // Open input file
        infile = $fopen("input_matrix.txt", "r");
        if (!infile) begin
            $display("Error: Could not open input_matrix.txt");
            $finish;
        end
        
        // Open output file
        outfile = $fopen("output_results.csv", "w");
        if (!outfile) begin
            $display("Error: Could not create output_results.csv");
            $fclose(infile);
            $finish;
        end
        
        
        // Process until end of file
        while (!$feof(infile) && !file_error) begin
            // Read first line (x00, x01)
            status = $fscanf(infile, "%f %f", temp_x00, temp_x01);
            if (status != 2) begin
                if ($feof(infile)) begin
                    // Normal EOF reached
                    file_error = 0;
                end else begin
                    $display("Error reading first line");
                    file_error = 1;
                end
            end else begin
                // Read second line (x10, x11)
                status = $fscanf(infile, "%f %f", temp_x10, temp_x11);
                if (status != 2) begin
                    $display("Error reading second line");
                    file_error = 1;
                end else begin
                    // Convert to fixed-point (EXACTLY as before)
                    x00 = temp_x00 * (2**FRAC_BITS);
                    x01 = temp_x01 * (2**FRAC_BITS);
                    x10 = temp_x10 * (2**FRAC_BITS);
                    x11 = temp_x11 * (2**FRAC_BITS);
                    
                    #10; // Processing delay
                    
                    // Calculate result
                    y_real = fixed_to_real(pool_out);
                    
                    // Display to terminal
                    $display("Matrix Input:");
                    $display("%0.9f %0.9f", temp_x00, temp_x01);
                    $display("%0.9f %0.9f", temp_x10, temp_x11);
                    $display("Pooling Result: %0.4f", y_real);
                    $display("------------------");
                    
                    // Save to CSV file
                    $fwrite(outfile, "%0.9f\n", y_real);
                end
            end
        end
        
        // Cleanup
        $fclose(infile);
        $fclose(outfile);
        
        if (file_error) begin
            $display("Simulation completed with errors");
        end else begin
            $display("Simulation completed successfully. Results saved to output_results.csv");
        end
        $finish;
    end
endmodule