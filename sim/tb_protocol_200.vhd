-- Independent upstream wire-level stimulus/checker, two generic configurations.
library ieee;
use ieee.std_logic_1164.all;
use work.spwpkg.all;
entity tb_protocol_200 is end;
architecture test of tb_protocol_200 is begin
    nominal: entity work.spwlink_tb
        generic map(sys_clock_freq=>400.0e6, rx_clock_freq=>400.0e6,
                    tx_clock_freq=>400.0e6, input_rate=>200.0e6, tx_clock_div=>1);
    offset_rate: entity work.spwlink_tb
        generic map(sys_clock_freq=>400.0e6, rx_clock_freq=>400.0e6,
                    tx_clock_freq=>400.0e6, input_rate=>199.6e6, tx_clock_div=>1,
                    startwait=>1 us);
end architecture;
