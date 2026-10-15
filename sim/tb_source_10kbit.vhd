library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity tb_source_10kbit is end;
architecture test of tb_source_10kbit is
    signal clk: std_logic := '0';
    signal rst: std_logic := '1';
    signal running, enable, ready, valid, flag: std_logic := '0';
    signal data: std_logic_vector(7 downto 0);
begin
    clk <= not clk after 5 ns;
    dut: entity work.spw_test_source
        generic map(PACKET_BYTES=>1250,ONE_SHOT=>true)
        port map(clk,rst,running,enable,ready,valid,flag,data);
    process
    begin
        wait until falling_edge(clk); rst<='0'; running<='1'; enable<='1';
        wait until valid='1';
        for i in 0 to 1250 loop
            wait until falling_edge(clk); ready<='0';
            for j in 0 to (i mod 3) loop
                wait until falling_edge(clk);
                assert valid='1' report "Missing source data" severity failure;
                if i<1250 then
                    assert flag='0' and unsigned(data)=i mod 256
                        report "Incorrect 10Kbit payload or stall stability" severity failure;
                else
                    assert flag='1' and data=x"00" report "Missing final EOP" severity failure;
                end if;
            end loop;
            ready<='1'; wait until rising_edge(clk); wait for 1 ns; ready<='0';
        end loop;
        for i in 1 to 100 loop
            wait until falling_edge(clk);
            assert valid='0' report "One-shot emitted extra bytes" severity failure;
        end loop;
        enable<='0'; wait until falling_edge(clk); enable<='1';
        wait until valid='1'; wait until falling_edge(clk);
        assert flag='0' and data=x"00" report "Rearm did not restart payload" severity failure;
        running<='0'; wait until falling_edge(clk); running<='1';
        for i in 1 to 20 loop
            wait until falling_edge(clk);
            assert valid='0' report "One-shot silently retried after link loss" severity failure;
        end loop;
        report "TEST_PASS: exactly 1250 payload bytes plus EOP; stalls, one-shot, rearm, link loss";
        stop;
    end process;
    process begin wait for 200 us; assert false report "Watchdog" severity failure; end process;
end;
