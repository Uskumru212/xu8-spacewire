library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity tb_test_source is end;
architecture test of tb_test_source is
    signal clk: std_logic := '0';
    signal rst: std_logic := '1';
    signal running, enable, ready, valid, flag: std_logic := '0';
    signal data: std_logic_vector(7 downto 0);
begin
    clk <= not clk after 5 ns;
    dut: entity work.spw_test_source port map(clk,rst,running,enable,ready,valid,flag,data);
    process
        variable held_data: std_logic_vector(7 downto 0);
        variable held_flag: std_logic;
    begin
        wait until falling_edge(clk); rst<='0'; running<='1'; enable<='1';
        wait until valid='1';
        for i in 0 to 256 loop
            wait until falling_edge(clk); ready<='0';
            held_data:=data; held_flag:=flag;
            for j in 0 to (i mod 3) loop
                wait until falling_edge(clk);
                assert valid='1' and data=held_data and flag=held_flag
                    report "Source changed during backpressure" severity failure;
            end loop;
            if i=100 then enable<='0'; end if;
            if i<256 then
                assert flag='0' and unsigned(data)=i report "Pattern mismatch" severity failure;
            else
                assert flag='1' and data=x"00" report "Missing EOP" severity failure;
            end if;
            ready<='1'; wait until rising_edge(clk); wait for 1 ns; ready<='0';
        end loop;
        wait until falling_edge(clk);
        assert valid='0' report "Disable did not finish at packet boundary" severity failure;
        enable<='1'; wait until valid='1';
        wait until falling_edge(clk); ready<='1';
        wait until falling_edge(clk); running<='0';
        wait until falling_edge(clk);
        assert valid='0' report "Source active with link down" severity failure;
        running<='1'; ready<='0'; wait until valid='1'; wait for 1 ns;
        assert flag='0' and data=x"00" report "Reconnect did not restart packet" severity failure;
        rst<='1'; wait for 1 ns;
        assert valid='0' report "Reset did not gate output" severity failure;
        report "TEST_PASS: pattern, stalls, boundary disable, link loss and reset";
        stop;
    end process;
    process begin wait for 100 us; assert false report "Watchdog" severity failure; end process;
end;
