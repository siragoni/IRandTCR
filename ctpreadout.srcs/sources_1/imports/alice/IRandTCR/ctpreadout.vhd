----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/01/2022 08:45:03 AM
-- Design Name: 
-- Module Name: ctpreadout - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.gbt_bank_package.all; 
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_exampledesign_package.all;


entity ctpreadout is
    port (
    --------------------------------------------------------------------------------
    -- RESET
    --------------------------------------------------------------------------------
    ipb_rst                   : in  std_logic;          --  General Reset
	--------------------------------------------------------------------------------
    -- TIMING 
    --------------------------------------------------------------------------------
    clk_bc_240                : in  std_logic;
    tick_bc                   : in  std_logic;
    --------------------------------------------------------------------------------
    -- GBT monitoring
    --------------------------------------------------------------------------------
    gbt_rx_clk240_en_s             : in std_logic_vector (1 to 2);
    gbt_rx_data_s                  : in gbt_reg84_A(1 to 2); 
    gbt_rx_wordclk_s               : in std_logic_vector (1 to 2);   -- Comment. Tick, sync w.r.t GBT Clock Domain
    gbtRxReady_from_gbtExmplDsgn_s : in std_logic_vector (1 to 2); 
    
    gbt1_tx_data                   : out std_logic_vector (79 downto 0);
    gbt1_txIsDataSel               : out std_logic;
    gbt2_tx_data                   : out std_logic_vector (79 downto 0);
    gbt2_txIsDataSel               : out std_logic;

   	--------------------------------------------------------------------------------
    -- Resets
    --------------------------------------------------------------------------------
    rst_ir_buffer_i           : in std_logic;
    rst_ir_state_machine_i    : in std_logic;
    rst_tcr_buffer_i          : in std_logic;
    rst_tcr_state_machine_i   : in std_logic;
    --------------------------------------------------------------------------------
    -- Data to GBT		
    --------------------------------------------------------------------------------
    d_i_sel_ir                   : in  std_logic_vector(31 downto 0);
    d_i_sel_tcr                  : in  std_logic_vector(31 downto 0);
    global_orbit                 : in  std_logic_vector (31 downto 0);
--    s_TTC_RXD	                 : in  std_logic_vector(119 downto 0);
    d_i_ir                       : in  std_logic_vector (47 downto 0); -->    
    d_i_tcr                      : in  std_logic_vector (63 downto 0); -->   
    d_o_ir                       : out std_logic_vector (79 downto 0); -- GBT data
    dv_o_ir                      : out std_logic;                      -- GBT data flag
    d_o_tcr                      : out std_logic_vector (79 downto 0); -- GBT data
    dv_o_tcr                     : out std_logic;                      -- GBT data flag
    --------------------------------------------------------------------------------
    -- start/stop monitoring
    --------------------------------------------------------------------------------
--    start_ir_data_taking_o    : out std_logic;
--    stop_ir_data_taking_o     : out std_logic; 
--    start_tcr_data_taking_o   : out std_logic;
--    stop_tcr_data_taking_o    : out std_logic; 
    swt_monitoring            : inout std_logic_vector(31 downto 0); 
    --------------------------------------------------------------------------------
    -- State machine coders 
    --------------------------------------------------------------------------------
    ir_state_machine_codes_o  : out std_logic_vector (31 downto 0);
    tcr_state_machine_codes_o : out std_logic_vector (31 downto 0);
    --------------------------------------------------------------------------------
    -- Miscellaneous
    --------------------------------------------------------------------------------
    sn                        : in  std_logic_vector ( 7 downto 0);
    threshold_ir              : in  std_logic_vector (31 downto 0);
    threshold_tcr             : in  std_logic_vector (31 downto 0)
        
        );
end ctpreadout;

architecture Behavioral of ctpreadout is


   -- Start/Stop
   signal start_ir_data_taking_i  : std_logic := '0'; 
   signal start_tcr_data_taking_i : std_logic := '0'; 
   signal stop_ir_data_taking_i   : std_logic := '0'; 
   signal stop_tcr_data_taking_i  : std_logic := '0'; 
   signal counter_SWT             : unsigned(31 downto 0) := (others => '0');
   
    
   signal count       : std_logic_vector (67 downto 0) := (others => '0');
   signal orbit_reg   : std_logic_vector (31  downto 0) := (others => '0');
   signal tcr_s_ttcrx : std_logic_vector (119 downto 0) := (others => '0');
   signal tcr_data    : std_logic_vector (67  downto 0) := (others => '0');
   signal ir_data     : std_logic_vector (67  downto 0) := (others => '0');

   -- CDC GBT to OLT
   signal dc_fifo1_gbt2olt_din, gbt1_rx_data : std_logic_vector(85 downto 0);
   signal dc_fifo1_gbt2olt_rd_en, dc_fifo1_gbt2olt_empty : std_logic;
   signal dc_fifo2_gbt2olt_din, gbt2_rx_data : std_logic_vector(85 downto 0);
   signal dc_fifo2_gbt2olt_rd_en, dc_fifo2_gbt2olt_empty : std_logic;
   signal rxIsData_from_gbtExmplDsgn_s                   : std_logic_vector (1 to 2) := (others => '0'); 


component dc_fifo_gbt2olt
    port (rst        : in  std_logic;
          wr_clk     : in  std_logic;
          rd_clk     : in  std_logic;
          din        : in  std_logic_vector(85 downto 0);
          wr_en      : in  std_logic;
          rd_en      : in  std_logic;
          dout       : out std_logic_vector(85 downto 0);
          full       : out std_logic;
          empty      : out std_logic;
          wr_rst_busy: out std_logic;
          rd_rst_busy: out std_logic
          );
end component;     


begin


--========================
-- GBT for IR
--========================

dc_fifo1_gbt2olt_din(85) <= gbt_rx_clk240_en_s(1);
dc_fifo1_gbt2olt_din(84) <= rxIsData_from_gbtExmplDsgn_s(1);
dc_fifo1_gbt2olt_din(83 downto 0) <= gbt_rx_data_s(1);

cdc1_gbt2olt : dc_fifo_gbt2olt
    port map (
        rst     => ipb_rst,
        wr_clk  => gbt_rx_wordclk_s(1), -- 240 Mhz GBT Rx clock
        rd_clk  => clk_bc_240, -- 240 Mhz OLT TRx clock 
        din     => dc_fifo1_gbt2olt_din, -- 86 bits
        wr_en   => gbtRxReady_from_gbtExmplDsgn_s(1),                      -- gbt_rx_clk240_en_s(1),
        rd_en   => dc_fifo1_gbt2olt_rd_en,
        dout    => gbt1_rx_data, -- 86 bits
        full    => open,
        empty   => dc_fifo1_gbt2olt_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
          );     

dc_fifo1_gbt2olt_rd_en <= not dc_fifo1_gbt2olt_empty;



--========================
-- GBT for IR
--========================

dc_fifo2_gbt2olt_din(85) <= gbt_rx_clk240_en_s(2);
dc_fifo2_gbt2olt_din(84) <= rxIsData_from_gbtExmplDsgn_s(2);
dc_fifo2_gbt2olt_din(83 downto 0) <= gbt_rx_data_s(2);

cdc2_gbt2olt : dc_fifo_gbt2olt
    port map (
        rst     => ipb_rst,
        wr_clk  => gbt_rx_wordclk_s(2), -- 240 Mhz GBT Rx clock
        rd_clk  => clk_bc_240, -- 240 Mhz OLT TRx clock 
        din     => dc_fifo2_gbt2olt_din, -- 86 bits
        wr_en   => gbtRxReady_from_gbtExmplDsgn_s(2),                      -- gbt_rx_clk240_en_s(1),
        rd_en   => dc_fifo2_gbt2olt_rd_en,
        dout    => gbt2_rx_data, -- 86 bits
        full    => open,
        empty   => dc_fifo2_gbt2olt_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
          );      

dc_fifo2_gbt2olt_rd_en <= not dc_fifo2_gbt2olt_empty;



--==============================
-- START/STOP
--==============================
ctrl_ir: process (clk_bc_240)
          begin 
          if (rising_edge(clk_bc_240)) then -- 240 MHz !!!
             if (gbt1_rx_data(85) = '1') then
                         
                if (gbt1_rx_data(84) = '0' and gbt1_rx_data(79 downto 0) = x"300000000000DEADBEEF") then -- SWT word is when GBT bits 79:76 = 0x3
                   start_ir_data_taking_i <= '1';
                elsif (gbt1_rx_data(84) = '0' and gbt1_rx_data(79 downto 0) = x"300000000000BEEFDEAD") then -- SWT word is when GBT bits 79:76 = 0x3
                   stop_ir_data_taking_i <= '1';
                else
                   start_ir_data_taking_i <= '0';
                   stop_ir_data_taking_i <= '0';
             end if;
             end if;
         end if;
         end process;


ctrl_tcr: process (clk_bc_240)
          begin 
          if (rising_edge(clk_bc_240)) then -- 240 MHz !!!
             if (gbt2_rx_data(85) = '1') then
                         
                if (gbt2_rx_data(84) = '0' and gbt2_rx_data(79 downto 0) = x"300000000000DEADBEEF") then -- SWT word is when GBT bits 79:76 = 0x3
                   start_tcr_data_taking_i <= '1';
                elsif (gbt2_rx_data(84) = '0' and gbt2_rx_data(79 downto 0) = x"300000000000BEEFDEAD") then -- SWT word is when GBT bits 79:76 = 0x3
                   stop_tcr_data_taking_i <= '1';
                else
                   start_tcr_data_taking_i <= '0';
                   stop_tcr_data_taking_i <= '0';
             end if;
             end if;
         end if;
         end process;


 -- ===========
 -- Counter SWT
 -- ===========
  p_bc_cnt : process(clk_bc_240)
  begin
    if rising_edge(clk_bc_240) then
      if (start_tcr_data_taking_i = '1' or start_ir_data_taking_i = '1' or stop_tcr_data_taking_i = '1' or stop_ir_data_taking_i = '1')  then
          counter_SWT <= counter_SWT + 1;
      end if;
    end if;
  end process p_bc_cnt;

swt_monitoring <= std_logic_vector(counter_SWT);


--==============================
-- Generate HB trigger
--==============================
generate_HB_trigger: process(clk_bc_240, global_orbit)
        variable helper_orbit_p : std_logic_vector(31 downto 0) := (others => '0');
    begin
        if (rising_edge(clk_bc_240)) then
            if (tick_bc = '1') then
                  helper_orbit_p := global_orbit;
                  if (unsigned(helper_orbit_p) = unsigned(orbit_reg)) then
                    tcr_s_ttcrx(1 downto 1) <= "0";
                    orbit_reg    <= global_orbit;
--                    helper_orbit <= orbitid;
                  else
                    tcr_s_ttcrx(1 downto 1) <= "1";
                    orbit_reg    <= global_orbit;
--                    helper_orbit <= orbitid;
                  end if;
            end if;
        end if;
    end process generate_HB_trigger;

--==============================
-- Counter Mode
--==============================
process (clk_bc_240)
    begin
        if (rising_edge(clk_bc_240)) then
            if (tick_bc = '1') then
--                count_tcr <= count_tcr + '1';   -- counting up
                count <= std_logic_vector(unsigned(count) + '1');   -- counting up
                if count(11 downto 0) = "111111111111" then
                  count <= (others => '0');
                end if;
            end if;
        end if;
    end process;


--==============================
-- IR with Zeroes Suppression
--==============================
ir_data (47 downto 0) <= d_i_ir;

ir2: entity work.top_ir_statemachine 
         generic map ( g_NUM_BITS_ON_GBT_WORD => 48 )
         port map (      
            --------------------------------------------------------------------------------
            -- RESET
            --------------------------------------------------------------------------------
            ipb_rst                   => ipb_rst,          --  General Reset
            --------------------------------------------------------------------------------
            -- TIMING 
            --------------------------------------------------------------------------------
            clk_bc_240                => clk_bc_240,
            tick_bc                   => tick_bc,
            --------------------------------------------------------------------------------
            -- GBT monitoring
            --------------------------------------------------------------------------------
            gbt_rx_clk240_en          => gbt1_rx_data(85),
            gbt_rx_data_flag          => gbt1_rx_data(84),
            gbt_rx_data               => gbt1_rx_data(79 downto 0), -- GBT Rx 1
            --------------------------------------------------------------------------------
            -- TCR resets
            --------------------------------------------------------------------------------
            rst_ir_buffer_i          => rst_ir_buffer_i, 
            rst_ir_state_machine_i   => rst_ir_state_machine_i, 
            --------------------------------------------------------------------------------
            -- Data to GBT		
            --------------------------------------------------------------------------------
            d_i_sel                   => d_i_sel_ir,
            global_orbit              => global_orbit,
            s_TTC_RXD	              => tcr_s_ttcrx,
            count                     => count,
            d_i                       => ir_data,  -- [67:0], 48 trigger input + 20 zeros   
            d_o                       => gbt1_tx_data, -- GBT data
            dv_o                      => gbt1_txIsDataSel,  
            --------------------------------------------------------------------------------
            -- TCR start/stop
            --------------------------------------------------------------------------------
            start_ir_data_taking_i   => start_ir_data_taking_i or start_tcr_data_taking_i,
            stop_ir_data_taking_i    => stop_ir_data_taking_i or stop_tcr_data_taking_i,
            --------------------------------------------------------------------------------
            -- TCR state machine coders (same interface as IR)
            --------------------------------------------------------------------------------
            ir_state_machine_codes_o => open,
             --------------------------------------------------------------------------------
            -- Miscellaneous
            --------------------------------------------------------------------------------
            sn        => sn,
            threshold => threshold_ir -- ctpreadout.irrate
                  );







--===============================
-- TCR with Zeroes Suppression
--===============================
tcr: entity work.top_tc_statemachine 
         generic map ( g_NUM_BITS_ON_GBT_WORD => 76 )
         port map (      
            --------------------------------------------------------------------------------
            -- RESET
            --------------------------------------------------------------------------------
            ipb_rst                   => ipb_rst,          --  General Reset
            --------------------------------------------------------------------------------
            -- TIMING 
            --------------------------------------------------------------------------------
            clk_bc_240                => clk_bc_240,
            tick_bc                   => tick_bc,
            --------------------------------------------------------------------------------
            -- GBT monitoring
            --------------------------------------------------------------------------------
            gbt_rx_clk240_en          => gbt2_rx_data(85),
            gbt_rx_data_flag          => gbt2_rx_data(84),
            gbt_rx_data               => gbt2_rx_data(79 downto 0), -- GBT Rx 1
            --------------------------------------------------------------------------------
            -- TCR resets
            --------------------------------------------------------------------------------
            rst_tcr_buffer_i          => rst_tcr_buffer_i, 
            rst_tcr_state_machine_i   => rst_tcr_state_machine_i, 
            --------------------------------------------------------------------------------
            -- Data to GBT		
            --------------------------------------------------------------------------------
            d_i_sel                   => d_i_sel_tcr,
--            d_i_sel                   => '1',
            global_orbit              => global_orbit,
            s_TTC_RXD	              => tcr_s_ttcrx,
            count                     => count,   
            d_i                       => tcr_data,   
--            bc_number_i               => bcid, -- BC ID
            d_o                       => gbt2_tx_data, -- GBT data
            dv_o                      => gbt2_txIsDataSel,  
            --------------------------------------------------------------------------------
            -- TCR start/stop
            --------------------------------------------------------------------------------
            start_tcr_data_taking_i   => start_tcr_data_taking_i or start_ir_data_taking_i,
            stop_tcr_data_taking_i    => stop_tcr_data_taking_i or stop_ir_data_taking_i,
            --------------------------------------------------------------------------------
            -- TCR state machine coders (same interface as IR)
            --------------------------------------------------------------------------------
            tcr_state_machine_codes_o => open,
             --------------------------------------------------------------------------------
            -- Miscellaneous
            --------------------------------------------------------------------------------
            sn        => sn,
            threshold => threshold_tcr -- ctpreadout.tcrate
                  );






--===============================
-- IR without zeroes suppression
--===============================
--ir: entity work.ir_top 
--         port map (      
--           ipb_rst        => ipb_rst,
--           clk_bc_240     => olt_clk_trxusr240_s,
--           tick_bc        => olt_tx_data_strobe_s,    -- TICK
--           --
--           gbt_rx_clk240_en => gbt1_rx_data(85),
--           gbt_rx_data_flag => gbt1_rx_data(84),
--           gbt_rx_data      => gbt1_rx_data(79 downto 0), -- GBT Rx 1
--           --
--           rst_ir_buffer_i => rst_ir_buffer,
--           rst_ir_state_machine_i => rst_ir_state_machine,
--           d_i_sel        => ir_input_data_sel,
--           d_i            => trigger_inputs_sync,     -- 48 trigger inputs
--           bc_number_i    => bcid,     -- BC ID
--           orbit_number_i => orbitid,  -- Orbit ID
--           d_o            => gbt1_tx_data,    -- GBT Tx 1
--           dv_o           => gbt1_txIsDataSel, -- GBT Tx 1 data flag
--           -- test signals
--           start_ir_data_taking_o => start_ir_data_taking,
--           stop_ir_data_taking_o => stop_ir_data_taking,
--           -- IR state machine codes
--           ir_state_machine_codes_o => ir_state_machine_codes_s 
--                  );



end Behavioral;
