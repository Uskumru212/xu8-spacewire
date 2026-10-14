library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Read-only telemetry on AXI4-Lite. All signals share aclk; use an AXI
-- asynchronous bridge from the PS clock domain, never synchronize words bitwise.
entity spw_telemetry_axi is
    generic (EVENT_DEPTH: positive := 64);
    port (
        aclk, aresetn: in std_logic;
        status, control: in std_logic_vector(15 downto 0);
        counters: in std_logic_vector(319 downto 0);
        s_axi_awaddr: in std_logic_vector(11 downto 0);
        s_axi_awprot: in std_logic_vector(2 downto 0);
        s_axi_awvalid: in std_logic; s_axi_awready: out std_logic;
        s_axi_wdata: in std_logic_vector(31 downto 0);
        s_axi_wstrb: in std_logic_vector(3 downto 0);
        s_axi_wvalid: in std_logic; s_axi_wready: out std_logic;
        s_axi_bresp: out std_logic_vector(1 downto 0);
        s_axi_bvalid: out std_logic; s_axi_bready: in std_logic;
        s_axi_araddr: in std_logic_vector(11 downto 0);
        s_axi_arprot: in std_logic_vector(2 downto 0);
        s_axi_arvalid: in std_logic; s_axi_arready: out std_logic;
        s_axi_rdata: out std_logic_vector(31 downto 0);
        s_axi_rresp: out std_logic_vector(1 downto 0);
        s_axi_rvalid: out std_logic; s_axi_rready: in std_logic
    );
end;
architecture rtl of spw_telemetry_axi is
    attribute X_INTERFACE_INFO: string;
    attribute X_INTERFACE_PARAMETER: string;
    attribute X_INTERFACE_INFO of aclk: signal is "xilinx.com:signal:clock:1.0 aclk CLK";
    attribute X_INTERFACE_PARAMETER of aclk: signal is "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET aresetn, FREQ_HZ 400000000";
    attribute X_INTERFACE_INFO of aresetn: signal is "xilinx.com:signal:reset:1.0 aresetn RST";
    attribute X_INTERFACE_PARAMETER of aresetn: signal is "POLARITY ACTIVE_LOW";
    attribute X_INTERFACE_INFO of s_axi_awaddr: signal is "xilinx.com:interface:aximm:1.0 S_AXI AWADDR";
    attribute X_INTERFACE_INFO of s_axi_awprot: signal is "xilinx.com:interface:aximm:1.0 S_AXI AWPROT";
    attribute X_INTERFACE_INFO of s_axi_awvalid: signal is "xilinx.com:interface:aximm:1.0 S_AXI AWVALID";
    attribute X_INTERFACE_INFO of s_axi_awready: signal is "xilinx.com:interface:aximm:1.0 S_AXI AWREADY";
    attribute X_INTERFACE_INFO of s_axi_wdata: signal is "xilinx.com:interface:aximm:1.0 S_AXI WDATA";
    attribute X_INTERFACE_INFO of s_axi_wstrb: signal is "xilinx.com:interface:aximm:1.0 S_AXI WSTRB";
    attribute X_INTERFACE_INFO of s_axi_wvalid: signal is "xilinx.com:interface:aximm:1.0 S_AXI WVALID";
    attribute X_INTERFACE_INFO of s_axi_wready: signal is "xilinx.com:interface:aximm:1.0 S_AXI WREADY";
    attribute X_INTERFACE_INFO of s_axi_bresp: signal is "xilinx.com:interface:aximm:1.0 S_AXI BRESP";
    attribute X_INTERFACE_INFO of s_axi_bvalid: signal is "xilinx.com:interface:aximm:1.0 S_AXI BVALID";
    attribute X_INTERFACE_INFO of s_axi_bready: signal is "xilinx.com:interface:aximm:1.0 S_AXI BREADY";
    attribute X_INTERFACE_INFO of s_axi_araddr: signal is "xilinx.com:interface:aximm:1.0 S_AXI ARADDR";
    attribute X_INTERFACE_INFO of s_axi_arprot: signal is "xilinx.com:interface:aximm:1.0 S_AXI ARPROT";
    attribute X_INTERFACE_INFO of s_axi_arvalid: signal is "xilinx.com:interface:aximm:1.0 S_AXI ARVALID";
    attribute X_INTERFACE_INFO of s_axi_arready: signal is "xilinx.com:interface:aximm:1.0 S_AXI ARREADY";
    attribute X_INTERFACE_INFO of s_axi_rdata: signal is "xilinx.com:interface:aximm:1.0 S_AXI RDATA";
    attribute X_INTERFACE_INFO of s_axi_rresp: signal is "xilinx.com:interface:aximm:1.0 S_AXI RRESP";
    attribute X_INTERFACE_INFO of s_axi_rvalid: signal is "xilinx.com:interface:aximm:1.0 S_AXI RVALID";
    attribute X_INTERFACE_INFO of s_axi_rready: signal is "xilinx.com:interface:aximm:1.0 S_AXI RREADY";
    attribute X_INTERFACE_PARAMETER of s_axi_awaddr: signal is "PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 12, READ_WRITE_MODE READ_WRITE";

    type event_array is array (0 to EVENT_DEPTH-1) of std_logic_vector(63 downto 0);
    signal events: event_array;
    signal wr, rd: natural range 0 to EVENT_DEPTH-1 := 0;
    signal used: natural range 0 to EVENT_DEPTH := 0;
    signal lost, ticks: unsigned(31 downto 0) := (others=>'0');
    signal last_status, last_control: std_logic_vector(15 downto 0) := (others=>'0');
    signal first: boolean := true;
    signal held_event: std_logic_vector(63 downto 0) := (others=>'0');
    signal snap_status, snap_control: std_logic_vector(15 downto 0) := (others=>'0');
    signal snap_counters: std_logic_vector(319 downto 0) := (others=>'0');
    signal snap_time: std_logic_vector(31 downto 0) := (others=>'0');
    signal rv, bv, aw_pending, w_pending: std_logic := '0';
    -- Internal ready nets keep the BD module reference compatible with VHDL-93.
    signal arready_i, awready_i, wready_i: std_logic;
    function next_ptr(p: natural) return natural is
    begin if p=EVENT_DEPTH-1 then return 0; else return p+1; end if; end;
begin
    arready_i <= not rv and aresetn;
    s_axi_arready <= arready_i;
    s_axi_rvalid <= rv;
    awready_i <= not aw_pending and not bv and aresetn;
    wready_i <= not w_pending and not bv and aresetn;
    s_axi_awready <= awready_i;
    s_axi_wready <= wready_i;
    s_axi_bvalid <= bv;
    s_axi_bresp <= "10"; -- All writes rejected with SLVERR, never stalled forever.
    process(aclk)
        variable n: natural range 0 to EVENT_DEPTH;
        variable address: natural;
        variable aw_seen, w_seen: boolean;
    begin
        if rising_edge(aclk) then
            if aresetn='0' then
                rv<='0'; bv<='0'; aw_pending<='0'; w_pending<='0';
                s_axi_rdata<=(others=>'0'); s_axi_rresp<="00";
                wr<=0; rd<=0; used<=0; lost<=(others=>'0'); ticks<=(others=>'0'); first<=true;
                last_status<=(others=>'0'); last_control<=(others=>'0'); held_event<=(others=>'0');
                snap_status<=(others=>'0'); snap_control<=(others=>'0');
                snap_counters<=(others=>'0'); snap_time<=(others=>'0');
            else
                ticks<=ticks+1;
                n:=used;
                if rv='1' and s_axi_rready='1' then rv<='0'; end if;
                if bv='1' and s_axi_bready='1' then bv<='0'; end if;
                aw_seen:=aw_pending='1' or (s_axi_awvalid='1' and awready_i='1');
                w_seen:=w_pending='1' or (s_axi_wvalid='1' and wready_i='1');
                if aw_seen then aw_pending<='1'; end if;
                if w_seen then w_pending<='1'; end if;
                if aw_seen and w_seen and bv='0' then
                    bv<='1'; aw_pending<='0'; w_pending<='0';
                end if;
                if s_axi_arvalid='1' and arready_i='1' then
                    rv<='1'; s_axi_rdata<=(others=>'0'); s_axi_rresp<="00";
                    address:=to_integer(unsigned(s_axi_araddr));
                    case address is
                        when 16#000# =>
                            s_axi_rdata<=x"53505731"; -- SPW1; reading atomically snapshots all counters.
                            snap_status<=status; snap_control<=control;
                            snap_counters<=counters; snap_time<=std_logic_vector(ticks);
                        when 16#004# => s_axi_rdata<=x"0000" & snap_status;
                        when 16#008# => s_axi_rdata<=x"0000" & snap_control;
                        when 16#00C# => s_axi_rdata<=snap_time;
                        when 16#010# => s_axi_rdata<=x"00010000";
                        when 16#100# =>
                            if used>0 then
                                held_event<=events(rd); s_axi_rdata<=events(rd)(31 downto 0);
                                rd<=next_ptr(rd); n:=n-1;
                            else s_axi_rresp<="10"; end if;
                        when 16#104# => s_axi_rdata<=held_event(63 downto 32);
                        when 16#108# => s_axi_rdata<=std_logic_vector(to_unsigned(used,32));
                        when 16#10C# => s_axi_rdata<=std_logic_vector(lost);
                        when others =>
                            if address>=16#020# and address<=16#044# and address mod 4=0 then
                                s_axi_rdata<=snap_counters(8*(address-16#020#)+31 downto 8*(address-16#020#));
                            else s_axi_rresp<="10"; end if;
                    end case;
                end if;
                -- Exclude RX-valid/FIFO levels/time-code pulses from change events;
                -- those high-rate signals are available through ILA and snapshots.
                if first or (status(7 downto 0) and x"F7")/=(last_status(7 downto 0) and x"F7") or control/=last_control then
                    if n<EVENT_DEPTH then
                        events(wr)<=std_logic_vector(ticks) & control & status;
                        wr<=next_ptr(wr); n:=n+1;
                    elsif lost/=x"FFFFFFFF" then lost<=lost+1;
                    end if;
                end if;
                first<=false; last_status<=status; last_control<=control; used<=n;
            end if;
        end if;
    end process;
end;
