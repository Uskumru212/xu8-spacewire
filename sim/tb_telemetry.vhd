library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity tb_telemetry is end;
architecture test of tb_telemetry is
    signal clk: std_logic:='0'; signal resetn: std_logic:='0';
    signal status, control: std_logic_vector(15 downto 0):=(others=>'0');
    signal counters: std_logic_vector(319 downto 0):=(others=>'0');
    signal araddr, awaddr: std_logic_vector(11 downto 0):=(others=>'0');
    signal arvalid, rready, awvalid, wvalid, bready: std_logic:='0';
    signal arready, rvalid, awready, wready, bvalid: std_logic;
    signal rdata: std_logic_vector(31 downto 0);
    signal rresp, bresp: std_logic_vector(1 downto 0);
begin
    clk<=not clk after 1250 ps;
    dut: entity work.spw_telemetry_axi generic map(EVENT_DEPTH=>4)
        port map(clk,resetn,status,control,counters,awaddr,"000",awvalid,awready,
            x"DEADBEEF","1111",wvalid,wready,bresp,bvalid,bready,
            araddr,"000",arvalid,arready,rdata,rresp,rvalid,rready);
    process
        variable value, held: std_logic_vector(31 downto 0);
        procedure read_reg(address: natural; variable result: out std_logic_vector(31 downto 0);
                           response: std_logic_vector(1 downto 0):="00"; stalls: natural:=0) is
        begin
            wait until falling_edge(clk); araddr<=std_logic_vector(to_unsigned(address,12)); arvalid<='1';
            loop wait until rising_edge(clk); exit when arready='1'; end loop;
            wait until falling_edge(clk); arvalid<='0';
            assert rvalid='1' and rresp=response report "Bad AXI read response" severity failure;
            result:=rdata;
            for i in 1 to stalls loop
                wait until falling_edge(clk);
                assert rvalid='1' and rdata=result and rresp=response report "Read changed under stall" severity failure;
            end loop;
            rready<='1'; wait until falling_edge(clk); rready<='0';
        end;
        procedure set_status(v: natural) is
        begin wait until falling_edge(clk); status<=std_logic_vector(to_unsigned(v,16));
            wait until falling_edge(clk); end;
    begin
        wait until falling_edge(clk); resetn<='1';
        set_status(1); set_status(2); set_status(4); set_status(16);
        read_reg(16#108#,value); assert unsigned(value)=4 report "Event FIFO not full" severity failure;
        read_reg(16#10C#,value); assert unsigned(value)=1 report "Overflow not counted" severity failure;
        read_reg(16#100#,value,"00",5); assert value=x"00000000" report "Initial event missing" severity failure;
        read_reg(16#104#,value); held:=value;
        read_reg(16#104#,value); assert value=held report "Timestamp latch changed" severity failure;
        for i in 0 to 2 loop
            read_reg(16#100#,value);
            assert unsigned(value)=2**i report "Event order wrong" severity failure;
        end loop;
        read_reg(16#100#,value,"10"); -- Empty pop is an explicit error.
        for i in 0 to 9 loop counters(32*i+31 downto 32*i)<=std_logic_vector(to_unsigned(100+i,32)); end loop;
        read_reg(0,value); assert value=x"53505731" report "Identity wrong" severity failure;
        counters<=(others=>'1');
        for i in 0 to 9 loop
            read_reg(16#20#+4*i,value);
            assert unsigned(value)=100+i report "Counter snapshot was torn" severity failure;
        end loop;
        read_reg(4,value); assert value=x"00000010" report "Status snapshot wrong" severity failure;
        read_reg(3,value,"10"); read_reg(16#200#,value,"10");
        -- AW and W can arrive in either order; the read-only block must respond.
        for order in 0 to 1 loop
            wait until falling_edge(clk);
            if order=0 then awvalid<='1'; else wvalid<='1'; end if;
            wait until falling_edge(clk); awvalid<='0'; wvalid<='0';
            wait until falling_edge(clk);
            assert bvalid='0' report "Write response before both channels" severity failure;
            if order=0 then wvalid<='1'; else awvalid<='1'; end if;
            wait until falling_edge(clk); awvalid<='0'; wvalid<='0';
            assert bvalid='1' and bresp="10" report "Write not rejected" severity failure;
            for i in 1 to 3 loop wait until falling_edge(clk); assert bvalid='1' severity failure; end loop;
            bready<='1'; wait until falling_edge(clk); bready<='0';
        end loop;
        -- RX-valid bit changes do not fill the event FIFO.
        set_status(24); read_reg(16#108#,value); assert unsigned(value)=0 severity failure;
        control<=x"010C"; wait until falling_edge(clk); wait until falling_edge(clk);
        read_reg(16#100#,value); assert value=x"010C0018" report "Control event missing" severity failure;
        resetn<='0'; wait until falling_edge(clk); wait until falling_edge(clk); resetn<='1';
        read_reg(16#10C#,value); assert unsigned(value)=0 report "Reset did not clear lost counter" severity failure;
        report "TEST_PASS: AXI stalls, snapshot coherence, event order/overflow, empty/error reads, write ordering and reset";
        stop;
    end process;
    process begin wait for 100 us; assert false report "Telemetry watchdog" severity failure; end process;
end;
