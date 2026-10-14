library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Optional deterministic packets: bytes 0..255 followed by EOP.
-- Disabling requests stops after the current packet, not in its middle.
entity spw_test_source is
    port(clk, rst, running, enable, ready: in std_logic;
         valid, flag: out std_logic; data: out std_logic_vector(7 downto 0));
end;
architecture rtl of spw_test_source is
    signal active: std_logic := '0';
    signal position: unsigned(8 downto 0) := (others=>'0');
begin
    valid <= active and running and not rst;
    flag <= position(8);
    data <= std_logic_vector(position(7 downto 0));
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' or running='0' then
                active<='0'; position<=(others=>'0');
            elsif active='0' then
                if enable='1' then active<='1'; end if;
            elsif ready='1' then
                if position=256 then
                    position<=(others=>'0'); active<=enable;
                else position<=position+1;
                end if;
            end if;
        end if;
    end process;
end;
