library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
entity tb_endpoint is
    generic (PHASE_PS: natural := 700; SKEW_PS: natural := 200);
end;
architecture test of tb_endpoint is
    signal aclk: std_logic := '0';
    signal bclk: std_logic := '0';
    signal rst: std_logic := '1';
    signal cut: std_logic := '0';
    signal ado, aso, bdo, bso, adi, asi, bdi, bsi: std_logic := '0';
    signal delayed_bd, delayed_bs: std_logic := '0';
    signal a_status, b_status: std_logic_vector(15 downto 0);
    signal a_counts, b_counts: std_logic_vector(319 downto 0);
    signal send_enable: std_logic := '0';
    signal ardy, brdy, arv, brv, arf, brf: std_logic;
    signal ard, brd, atd, btd: std_logic_vector(7 downto 0);
    signal atv, btv, atf, btf: std_logic;
    signal brxready: std_logic := '0';
    signal atick: std_logic := '0';
    signal btick: std_logic;
    signal btime: std_logic_vector(5 downto 0);
    signal bctrl: std_logic_vector(1 downto 0);
    signal atx_index: natural := 0;
    signal btx_index: natural := 0;
    signal arx_count: natural := 0;
    signal brx_count: natural := 0;
    signal time_count: natural := 0;
    signal stall_seen: boolean := false;
    signal expect_traffic: boolean := true;
begin
    aclk <= not aclk after 1250 ps;
    process begin
        wait for PHASE_PS*1 ps;
        loop bclk <= not bclk; wait for 1251 ps; end loop;
    end process;
    -- Independent clock frequency/phase, propagation delay and D/S skew.
    bdi <= transport ado after 7 ns;
    bsi <= transport aso after 7 ns + SKEW_PS*1 ps;
    delayed_bd <= transport bdo after 9 ns;
    delayed_bs <= transport bso after 9 ns + SKEW_PS*1 ps;
    -- Freeze at the last line levels: no fabricated edge at fault injection.
    -- Forcing both wires low can instead produce a parity error before timeout.
    process(delayed_bd, delayed_bs, cut) begin
        if cut='0' then adi<=delayed_bd; asi<=delayed_bs; end if;
    end process;
    atv <= '1' when send_enable='1' and atx_index<514 else '0';
    btv <= '1' when send_enable='1' and btx_index<129 else '0';
    atf <= '1' when atx_index>=512 else '0';
    btf <= '1' when btx_index=128 else '0';
    atd <= x"00" when atx_index=512 else x"01" when atx_index=513
           else std_logic_vector(to_unsigned(atx_index mod 256,8));
    btd <= x"00" when btx_index=128 else std_logic_vector(to_unsigned((255-btx_index) mod 256,8));

    a: entity work.spw_endpoint generic map(CLOCK_HZ=>400.0e6, FIFO_BITS=>6)
        port map(clk=>aclk,rst=>rst,link_start=>'1',auto_start=>'1',link_disable=>'0',rate_divider=>x"01",
          tx_valid=>atv,tx_flag=>atf,tx_data=>atd,tx_ready=>ardy,
          rx_valid=>arv,rx_flag=>arf,rx_data=>ard,rx_ready=>'1',
          tick_in=>atick,time_in=>"000001",ctrl_in=>"00",tick_out=>open,time_out=>open,ctrl_out=>open,
          data_in=>adi,strobe_in=>asi,data_out=>ado,strobe_out=>aso,status=>a_status,counters=>a_counts);
    b: entity work.spw_endpoint generic map(CLOCK_HZ=>399680255.795, FIFO_BITS=>6)
        port map(clk=>bclk,rst=>rst,link_start=>'0',auto_start=>'1',link_disable=>'0',rate_divider=>x"01",
          tx_valid=>btv,tx_flag=>btf,tx_data=>btd,tx_ready=>brdy,
          rx_valid=>brv,rx_flag=>brf,rx_data=>brd,rx_ready=>brxready,
          tick_in=>'0',time_in=>"000000",ctrl_in=>"00",tick_out=>btick,time_out=>btime,ctrl_out=>bctrl,
          data_in=>bdi,strobe_in=>bsi,data_out=>bdo,strobe_out=>bso,status=>b_status,counters=>b_counts);

    process(aclk) begin
        if rising_edge(aclk) then
            if atv='1' and ardy='1' then atx_index<=atx_index+1; end if;
            if atv='1' and ardy='0' and a_status(2)='1' then stall_seen<=true; end if;
            if arv='1' and expect_traffic then
                if arx_count<128 then
                    assert arf='0' and ard=std_logic_vector(to_unsigned(255-arx_count,8))
                        report "A received incorrect data" severity failure;
                else
                    assert arx_count=128 and arf='1' and ard=x"00"
                        report "A received incorrect EOP or extra character" severity failure;
                end if;
                arx_count<=arx_count+1;
            end if;
        end if;
    end process;
    process(bclk) begin
        if rising_edge(bclk) then
            if btv='1' and brdy='1' then btx_index<=btx_index+1; end if;
            if brv='1' and brxready='1' and expect_traffic then
                if brx_count<512 then
                    assert brf='0' and brd=std_logic_vector(to_unsigned(brx_count mod 256,8))
                        report "B received incorrect data" severity failure;
                elsif brx_count=512 then
                    assert brf='1' and brd=x"00" report "Missing EOP" severity failure;
                else
                    assert brx_count=513 and brf='1' and brd=x"01"
                        report "Missing EEP or extra character" severity failure;
                end if;
                brx_count<=brx_count+1;
            end if;
            if btick='1' then
                assert btime="000001" and bctrl="00" report "Incorrect time code" severity failure;
                time_count<=time_count+1;
            end if;
        end if;
    end process;
    process begin
        wait for 200 ns;
        wait until falling_edge(aclk); rst<='0';
        wait until a_status(2)='1' and b_status(2)='1';
        report "Both endpoints reached Run; peer B used autostart";
        wait until falling_edge(aclk); send_enable<='1';
        wait for 20 us;
        assert stall_seen report "Backpressure did not reach the sender" severity failure;
        assert atx_index<514 report "Unexpectedly queued the whole packet during receiver stall" severity failure;
        assert a_status(2)='1' and b_status(2)='1' report "Flow-control stall lost the link" severity failure;
        wait until falling_edge(bclk); brxready<='1';
        wait until brx_count=514 and arx_count=129;
        wait for 1 us;
        assert unsigned(a_counts(31 downto 0))=514 report "Wrong A queued count" severity failure;
        assert unsigned(b_counts(31 downto 0))=129 report "Wrong B queued count" severity failure;
        assert unsigned(a_counts(95 downto 64))=129 report "Wrong A receive count" severity failure;
        assert unsigned(a_counts(63 downto 32))=2 and unsigned(b_counts(63 downto 32))=1
            report "Wrong queued packet-end counts" severity failure;
        assert unsigned(b_counts(95 downto 64))=514 report "Wrong B receive count" severity failure;
        assert unsigned(b_counts(127 downto 96))=2 report "Wrong packet-end count" severity failure;
        assert unsigned(b_counts(159 downto 128))=1 report "Wrong EEP count" severity failure;
        assert unsigned(a_counts(287 downto 160))=0 and unsigned(b_counts(287 downto 160))=0
            report "Unexpected errors during data transfer" severity failure;
        wait until falling_edge(aclk); atick<='1';
        wait until falling_edge(aclk); atick<='0';
        wait until time_count=1;
        expect_traffic<=false;
        wait for 2 us; cut<='1';
        wait until a_status(2)='0';
        wait for 3 us;
        assert unsigned(a_counts(223 downto 192))>=1 report "Lost link did not increment disconnect counter" severity failure;
        cut<='0';
        wait until a_status(2)='1' and b_status(2)='1';
        wait for 1 us;
        assert unsigned(a_counts(319 downto 288))>=1 report "Reconnect was not counted" severity failure;
        assert unsigned(b_counts(319 downto 288))>=1 report "Peer reconnect was not counted" severity failure;
        wait until falling_edge(aclk); rst<='1';
        wait for 100 ns;
        assert unsigned(a_counts)=0 and unsigned(b_counts)=0 report "Reset did not clear counters" severity failure;
        report "TEST_PASS: endpoint bidirectional data, EOP/EEP, backpressure, autostart, timecode, loss/reconnect and counters";
        stop;
        wait;
    end process;
    process begin
        wait for 1 ms;
        assert false report "Endpoint watchdog expired" severity failure;
    end process;
end;
