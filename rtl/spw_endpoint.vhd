library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spwpkg.all;

-- Generic, rising-edge-only SpaceWire endpoint. A 400 MHz clock with
-- rate_divider=1 models 200 Mbit/s. Hardware timing is NOT yet proven.
entity spw_endpoint is
    generic (CLOCK_HZ: real := 400.0e6; FIFO_BITS: integer := 8);
    port (
        clk, rst: in std_logic;
        link_start, auto_start, link_disable: in std_logic;
        rate_divider: in std_logic_vector(7 downto 0);
        tx_valid, tx_flag: in std_logic;
        tx_data: in std_logic_vector(7 downto 0);
        tx_ready: out std_logic;
        rx_valid, rx_flag: out std_logic;
        rx_data: out std_logic_vector(7 downto 0);
        rx_ready: in std_logic;
        tick_in: in std_logic;
        time_in: in std_logic_vector(5 downto 0);
        ctrl_in: in std_logic_vector(1 downto 0);
        tick_out: out std_logic;
        time_out: out std_logic_vector(5 downto 0);
        ctrl_out: out std_logic_vector(1 downto 0);
        data_in, strobe_in: in std_logic;
        data_out, strobe_out: out std_logic;
        status: out std_logic_vector(15 downto 0);
        counters: out std_logic_vector(319 downto 0)
    );
end entity;

architecture rtl of spw_endpoint is
    signal started, connecting, running, txrdy, rxvalid_i, rxflag_i: std_logic;
    signal txhalf, rxhalf, tick, disc, parity, escape_err, credit: std_logic;
    signal rxdata_i: std_logic_vector(7 downto 0);
    signal txwrite, rxread: std_logic;
    signal divider: std_logic_vector(7 downto 0) := x"01";
    signal last_run, ever_run: std_logic := '0';
    signal last_errors: std_logic_vector(3 downto 0) := (others=>'0');
    signal errors: std_logic_vector(3 downto 0);
    type count_array is array(0 to 9) of unsigned(31 downto 0);
    signal count: count_array := (others=>(others=>'0'));
    function increment(v: unsigned) return unsigned is
    begin
        if and v = '1' then return v; end if;
        return v+1;
    end function;
begin
    assert FIFO_BITS >= 6 and FIFO_BITS <= 14 report "Invalid FIFO size" severity failure;
    txwrite <= tx_valid and running and not link_disable and not rst;
    tx_ready <= txrdy and running and not link_disable and not rst;
    rxread <= rx_ready and not rst;
    rx_valid <= rxvalid_i and not rst;
    rx_flag <= rxflag_i;
    rx_data <= rxdata_i;
    tick_out <= tick;
    errors <= credit & escape_err & parity & disc;
    status <= "00000" & tick & rxhalf & txhalf & errors & rxvalid_i & running & connecting & started;
    gen_counts: for i in 0 to 9 generate
        counters(32*i+31 downto 32*i) <= std_logic_vector(count(i));
    end generate;

    core: entity work.spwstream
        generic map(sysfreq=>CLOCK_HZ, rximpl=>impl_generic, tximpl=>impl_generic,
                    rxchunk=>1, rxfifosize_bits=>FIFO_BITS, txfifosize_bits=>FIFO_BITS)
        port map(clk=>clk, rxclk=>clk, txclk=>clk, rst=>rst,
            autostart=>auto_start, linkstart=>link_start, linkdis=>link_disable,
            txdivcnt=>divider, tick_in=>tick_in and running, ctrl_in=>ctrl_in, time_in=>time_in,
            txwrite=>txwrite, txflag=>tx_flag, txdata=>tx_data, txrdy=>txrdy, txhalff=>txhalf,
            tick_out=>tick, ctrl_out=>ctrl_out, time_out=>time_out,
            rxvalid=>rxvalid_i, rxhalff=>rxhalf, rxflag=>rxflag_i, rxdata=>rxdata_i,
            rxread=>rxread, started=>started, connecting=>connecting, running=>running,
            errdisc=>disc, errpar=>parity, erresc=>escape_err, errcred=>credit,
            spw_di=>data_in, spw_si=>strobe_in, spw_do=>data_out, spw_so=>strobe_out);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                count <= (others=>(others=>'0'));
                last_run <= '0'; ever_run <= '0'; last_errors <= (others=>'0');
                divider <= rate_divider;
            else
                -- Rate changes are applied only while disconnected.
                if running='0' then divider <= rate_divider; end if;
                last_run <= running;
                last_errors <= errors;
                if txwrite='1' and txrdy='1' then
                    count(0) <= increment(count(0));
                    if tx_flag='1' then count(1) <= increment(count(1)); end if;
                end if;
                if rxread='1' and rxvalid_i='1' then
                    count(2) <= increment(count(2));
                    if rxflag_i='1' then
                        count(3) <= increment(count(3));
                        if rxdata_i=x"01" then count(4) <= increment(count(4)); end if;
                    end if;
                end if;
                if parity='1' and last_errors(1)='0' then count(5)<=increment(count(5)); end if;
                if disc='1' and last_errors(0)='0' then count(6)<=increment(count(6)); end if;
                if escape_err='1' and last_errors(2)='0' then count(7)<=increment(count(7)); end if;
                if credit='1' and last_errors(3)='0' then count(8)<=increment(count(8)); end if;
                if running='1' and last_run='0' then
                    if ever_run='1' then count(9)<=increment(count(9)); end if;
                    ever_run <= '1';
                end if;
            end if;
        end if;
    end process;
end architecture;
