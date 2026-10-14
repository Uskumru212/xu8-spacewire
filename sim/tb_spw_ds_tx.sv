`timescale 1ns/1ps
module tb_spw_ds_tx;
    reg clk = 0;
    always #2.5 clk = ~clk; // 200 MHz model, not a hardware clock claim.
    reg reset = 1, enable = 0, bit_valid = 0, bit_data = 0;
    reg [7:0] cycles_per_bit = 20;
    wire bit_ready, data_out, strobe_out, bit_sent;
    wire rail_3v3_enable, rail_5v_enable;
    spw_ds_tx dut (.*);
    power_enables power_dut (.rail_3v3_enable, .rail_5v_enable);

    integer cycle = 0, accepted = 0, previous_cycle = -1;
    integer scheduled_gap = 0;
    reg previous_data, previous_strobe, previous_xor;
    reg accepted_now;
    // Scoreboard checks the DS definition independently of the encoder logic.
    always @(posedge clk) begin
        cycle = cycle + 1;
        previous_data = data_out;
        previous_strobe = strobe_out;
        previous_xor = data_out ^ strobe_out;
        accepted_now = bit_valid && bit_ready;
        #0.1;
        if (reset || !enable) begin
            if ({data_out, strobe_out, bit_sent} !== 3'b000)
                $fatal(1, "Disabled/reset transmitter is not low");
            previous_cycle = -1;
        end else if (accepted_now) begin
            if (data_out !== bit_data || !bit_sent)
                $fatal(1, "Incorrect bit or missing acceptance pulse");
            if ((data_out ^ strobe_out) === previous_xor)
                $fatal(1, "DS clock did not transition for an accepted bit");
            if (previous_cycle >= 0 && cycle - previous_cycle < scheduled_gap)
                $fatal(1, "Bit spacing was shorter than the requested period");
            previous_cycle = cycle;
            scheduled_gap = cycles_per_bit == 0 ? 1 : cycles_per_bit;
            accepted = accepted + 1;
        end else begin
            if ({data_out, strobe_out} !== {previous_data, previous_strobe} || bit_sent)
                $fatal(1, "Outputs changed without a transfer");
        end
        if ({rail_3v3_enable, rail_5v_enable} !== 2'b11)
            $fatal(1, "Power enables are not active high");
    end

    task automatic stream(input integer divisor, input integer count);
        integer before_count, start_cycle, i;
        begin
            @(negedge clk);
            reset = 1; enable = 0; bit_valid = 0;
            repeat (2) @(negedge clk);
            reset = 0; enable = 1; bit_valid = 1; cycles_per_bit = divisor;
            before_count = accepted;
            start_cycle = cycle;
            // Enumerate every byte, least-significant bit first. This tests
            // equal runs, alternations and every data bit combination.
            i = 0;
            while (accepted - before_count < count) begin
                bit_data = ((i / 8) >> (i % 8)) & 1;
                @(posedge clk);
                if (bit_ready) i = i + 1;
                @(negedge clk);
            end
            if (cycle - start_cycle != 1 + (count-1)*(divisor == 0 ? 1 : divisor))
                $fatal(1, "Unexpected transfer rate for divisor %0d", divisor);
            bit_valid = 0;
            repeat (30) @(negedge clk);
        end
    endtask

    initial begin
        stream(20, 2048); // 10 Mbit/s at the modeled 200 MHz clock.
        stream(1, 2048);  // 200 Mbit/s at the modeled 200 MHz clock.
        stream(0, 32);   // Defined zero-divisor behavior.
        @(negedge clk);
        cycles_per_bit = 20; bit_valid = 1;
        repeat (45) @(negedge clk);
        cycles_per_bit = 1;
        repeat (50) @(negedge clk);
        cycles_per_bit = 20;
        repeat (80) @(negedge clk);
        enable = 0;
        repeat (4) @(negedge clk);
        enable = 1;
        repeat (45) @(negedge clk);
        reset = 1;
        repeat (3) @(negedge clk);
        $display("TEST_PASS: DS encoding, rates, stalls, rate changes, disable/reset and rail enables; accepted=%0d", accepted);
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Test watchdog expired");
    end
endmodule
