library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Board integration candidate. Requires generated AMD clock/debug IP and
-- reviewed constraints. The standalone DCI-enabled variant was routed and
-- loaded through JTAG on 2026-10-15; physical Run was observed, packets untested.
entity xu8_spacewire_top is
    generic(ENABLE_UART_TELEMETRY: boolean := true;
            ENABLE_DCI_STARTUP: boolean := false);
    port(clk100_p, clk100_n: in std_logic;
         spw_din_p, spw_din_n, spw_sin_p, spw_sin_n: in std_logic;
         spw_dout_p, spw_dout_n, spw_sout_p, spw_sout_n: out std_logic;
         rail_3v3_enable, rail_5v_enable: out std_logic);
end;
architecture rtl of xu8_spacewire_top is
    component STARTUPE3 is
        generic(PROG_USR: string := "FALSE"; SIM_CCLK_FREQ: real := 0.0);
        port(CFGCLK, CFGMCLK: out std_logic; DI: out std_logic_vector(3 downto 0);
             EOS, PREQ: out std_logic; DO, DTS: in std_logic_vector(3 downto 0);
             FCSBO, FCSBTS, GSR, GTS, KEYCLEARB, PACK, USRCCLKO,
             USRCCLKTS, USRDONEO, USRDONETS: in std_logic);
    end component;
    component DCIRESET is
        port(LOCKED: out std_logic; RST: in std_logic);
    end component;
    component telemetry_system_wrapper is
        port(spw_clk, spw_resetn: in std_logic;
             status, control: in std_logic_vector(15 downto 0);
             counters: in std_logic_vector(319 downto 0));
    end component;
    component IBUFDS is
        port(I, IB: in std_logic; O: out std_logic);
    end component;
    component OBUFDS is
        port(I: in std_logic; O, OB: out std_logic);
    end component;
    component spw_clock is
        port(clk_in1_p, clk_in1_n, reset: in std_logic; clk_out1, locked: out std_logic);
    end component;
    component spw_vio is
        port(clk: in std_logic; probe_in0: in std_logic_vector(15 downto 0);
             probe_out0: out std_logic_vector(15 downto 0));
    end component;
    component spw_ila is
        port(clk: in std_logic; probe0: in std_logic_vector(15 downto 0);
             probe1: in std_logic_vector(319 downto 0);
             probe2: in std_logic_vector(19 downto 0);
             probe3: in std_logic_vector(3 downto 0));
    end component;
    signal clk, locked, reset, dci_locked: std_logic;
    signal reset_pipe: std_logic_vector(3 downto 0) := (others=>'1');
    attribute ASYNC_REG: string;
    attribute ASYNC_REG of reset_pipe: signal is "TRUE";
    signal control, status: std_logic_vector(15 downto 0);
    signal counters: std_logic_vector(319 downto 0);
    signal di, si, do_i, so_i, tx_valid, tx_flag, tx_ready, rx_valid, rx_flag: std_logic;
    signal tx_data, rx_data: std_logic_vector(7 downto 0);
begin
    rail_3v3_enable <= '1';
    rail_5v_enable <= '1';
    with_dci: if ENABLE_DCI_STARTUP generate
        signal cfgclk, eos, dci_reset: std_logic;
        signal eos_meta, eos_sync: std_logic := '0';
        signal startup_count: unsigned(6 downto 0) := (others=>'0');
        attribute ASYNC_REG of eos_meta, eos_sync: signal is "TRUE";
        attribute SHREG_EXTRACT: string;
        attribute SHREG_EXTRACT of eos_meta, eos_sync: signal is "NO";
    begin
        -- Independent configuration oscillator avoids waiting on an uncalibrated
        -- bank-65 clock. Hold DCI reset through EOS plus 127 CFGMCLK cycles.
        startup: STARTUPE3 port map(CFGCLK=>open, CFGMCLK=>cfgclk, DI=>open,
            EOS=>eos, PREQ=>open, DO=>"0000", DTS=>"1111", FCSBO=>'1',
            FCSBTS=>'1', GSR=>'0', GTS=>'0', KEYCLEARB=>'1', PACK=>'0',
            USRCCLKO=>'0', USRCCLKTS=>'1', USRDONEO=>'1', USRDONETS=>'1');
        process(cfgclk) begin
            if rising_edge(cfgclk) then
                eos_meta <= eos;
                eos_sync <= eos_meta;
                if eos_sync='0' then startup_count <= (others=>'0');
                elsif startup_count /= 127 then startup_count <= startup_count+1;
                end if;
            end if;
        end process;
        dci_reset <= '1' when startup_count /= 127 else '0';
        calibrate: DCIRESET port map(LOCKED=>dci_locked, RST=>dci_reset);
    end generate;
    without_dci: if not ENABLE_DCI_STARTUP generate
        dci_locked <= '1';
    end generate;
    clock_inst: spw_clock port map(clk100_p,clk100_n,not dci_locked,clk,locked);
    data_input: IBUFDS port map(spw_din_p,spw_din_n,di);
    strobe_input: IBUFDS port map(spw_sin_p,spw_sin_n,si);
    data_output: OBUFDS port map(do_i,spw_dout_p,spw_dout_n);
    strobe_output: OBUFDS port map(so_i,spw_sout_p,spw_sout_n);
    -- Asynchronous assertion on loss of lock, synchronous release.
    process(clk,locked,dci_locked) begin
        if locked='0' or dci_locked='0' then reset_pipe<=(others=>'1');
        elsif rising_edge(clk) then reset_pipe<=reset_pipe(2 downto 0)&'0'; end if;
    end process;
    reset <= reset_pipe(3) or control(0);
    controls: spw_vio port map(clk,status,control);
    source: entity work.spw_test_source
        port map(clk,reset,status(2),control(4),tx_ready,tx_valid,tx_flag,tx_data);
    endpoint: entity work.spw_endpoint
        generic map(CLOCK_HZ=>400.0e6,FIFO_BITS=>8)
        port map(clk=>clk,rst=>reset,link_start=>control(2),auto_start=>control(3),
            link_disable=>control(1),rate_divider=>control(15 downto 8),
            tx_valid=>tx_valid,tx_flag=>tx_flag,tx_data=>tx_data,tx_ready=>tx_ready,
            rx_valid=>rx_valid,rx_flag=>rx_flag,rx_data=>rx_data,rx_ready=>'1',
            tick_in=>'0',time_in=>"000000",ctrl_in=>"00",
            tick_out=>open,time_out=>open,ctrl_out=>open,
            data_in=>di,strobe_in=>si,data_out=>do_i,strobe_out=>so_i,status=>status,counters=>counters);
    -- Telemetry persists across endpoint reset; only clock/PS resets clear it.
    with_uart: if ENABLE_UART_TELEMETRY generate
        uart_telemetry: telemetry_system_wrapper
            port map(spw_clk=>clk,spw_resetn=>not reset_pipe(3),
                     status=>status,control=>control,counters=>counters);
    end generate;
    analyzer: spw_ila port map(clk,status,counters,
        rx_valid & rx_flag & rx_data & tx_valid & tx_flag & tx_data,
        di & si & do_i & so_i);
end;
