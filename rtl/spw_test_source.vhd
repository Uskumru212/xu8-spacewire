library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Optional deterministic packets: incrementing bytes modulo 256, then EOP.
-- ONE_SHOT requires enable low before another packet; no automatic link-loss retry.
-- Disabling requests stops after the current packet, not in its middle.
entity spw_test_source is
    generic(PACKET_BYTES: positive := 256; ONE_SHOT: boolean := false);
    port(clk, rst, running, enable, ready: in std_logic;
         valid, flag: out std_logic; data: out std_logic_vector(7 downto 0));
end;
architecture rtl of spw_test_source is
    signal active: std_logic := '0';
    signal position: natural range 0 to PACKET_BYTES := 0;
    signal armed: std_logic := '1';
begin
    valid <= active and running and not rst;
    flag <= '1' when position=PACKET_BYTES else '0';
    data <= x"00" when position=PACKET_BYTES else
            std_logic_vector(to_unsigned(position mod 256,8));
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                active<='0'; position<=0; armed<='1';
            else
                if enable='0' then armed<='1'; end if;
                if running='0' then
                    active<='0'; position<=0;
                elsif active='0' then
                    if enable='1' and (not ONE_SHOT or armed='1') then
                        active<='1'; armed<='0';
                    end if;
                elsif ready='1' then
                    if position=PACKET_BYTES then
                        position<=0;
                        if ONE_SHOT then active<='0'; else active<=enable; end if;
                    else position<=position+1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end;
