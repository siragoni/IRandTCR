----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/01/2022 05:19:53 PM
-- Design Name: 
-- Module Name: ctpreadout_tb - Behavioral
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

use ieee.std_logic_textio.all;
library std;
use std.textio.all;



entity ctpreadout_tb is
--  Port ( );
end ctpreadout_tb;

architecture Behavioral of ctpreadout_tb is



    signal olt_clk_trxusr240_s            : std_logic := '0';
    signal olt_tx_data_strobe_s           : std_logic := '0';
    signal ipb_rst                        : std_logic := '0';
    signal gbt_rx_clk240_en_s             : std_logic_vector (1 to 2) := (others => '0');
    signal gbt_rx_data_s                  : gbt_reg84_A(1 to 2);
    signal gbt_rx_wordclk_s               : std_logic_vector (1 to 2) := (others => '0'); 
    signal gbtRxReady_from_gbtExmplDsgn_s : std_logic_vector (1 to 2) := (others => '0');  
    
    signal gbt1_tx_data                   : std_logic_vector (79 downto 0) := (others => '0');
    signal gbt1_txIsDataSel               : std_logic := '0';
    signal gbt2_tx_data                   : std_logic_vector (79 downto 0) := (others => '0');
    signal gbt2_txIsDataSel               : std_logic := '0';

    signal rst_ir_buffer                  : std_logic := '0';
    signal rst_ir_state_machine           : std_logic := '0';
    signal rst_tcr_buffer                 : std_logic := '0';
    signal rst_tcr_state_machine          : std_logic := '0';

    signal d_i_sel_ir                     : std_logic_vector(31 downto 0)  := (others => '0');
    signal d_i_sel_tcr                    : std_logic_vector(31 downto 0)  := (others => '0');
    signal orbitid                        : std_logic_vector(31 downto 0)  := (others => '0');

    signal trigger_inputs_sync            : std_logic_vector (47 downto 0) := (others => '0'); 
    signal l1_class_a                     : std_logic_vector (63 downto 0) := (others => '0'); 
    signal d_o_ir                         : std_logic_vector (79 downto 0) := (others => '0');
    signal dv_o_ir                        : std_logic := '0';
    signal d_o_tcr                        : std_logic_vector (79 downto 0) := (others => '0');
    signal dv_o_tcr                       : std_logic := '0';                      


    type   ipbus_stat_register is array(0 to 1) of std_logic_vector(31 downto 0); 
    signal ctpreadout_stat_s               : ipbus_stat_register;
    signal ctpreadout_ctrl_s               : ipbus_stat_register;
--    signal ctpreadout_stat_s               : std_logic_vector(31 downto 0) := (others => '0');

    signal sn                             : std_logic_vector ( 7 downto 0) := (others => '0');
    signal threshold_ir                   : std_logic_vector (31 downto 0) := (others => '0');
    signal threshold_tcr                  : std_logic_vector (31 downto 0) := (others => '0');

	file   out_file         : text open write_mode is "output2.txt";
    file   in_file          : text;
    signal s_state_num      : std_logic_vector(31 downto 0);
    signal s_state_num_1    : std_logic_vector(3  downto 0);


    component ctpreadout is
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
        swt_monitoring            : out std_logic_vector(31 downto 0); 
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
    end component;





begin

	olt_clk_trxusr240_s <= not(olt_clk_trxusr240_s) after (1 us/240);

	process(olt_clk_trxusr240_s)                          -- process for clk_en
        variable count  : integer := 0;
        begin
        -- Clk Enable
                if rising_edge(olt_clk_trxusr240_s) then
                        olt_tx_data_strobe_s <='0';
                        if(count = 6) then
                                olt_tx_data_strobe_s <='1';
                                count:=0;
                        end if;
                        count:=count+1;
                end if;
        end process;
        
        
        
   ctpreadout_top: ctpreadout
        port map (
        --------------------------------------------------------------------------------
        -- RESET
        --------------------------------------------------------------------------------
        ipb_rst                         => ipb_rst,          --  General Reset
        --------------------------------------------------------------------------------
        -- TIMING 
        --------------------------------------------------------------------------------
        clk_bc_240                     => olt_clk_trxusr240_s,
        tick_bc                        => olt_tx_data_strobe_s,
        --------------------------------------------------------------------------------
        -- GBT monitoring
        --------------------------------------------------------------------------------
        gbt_rx_clk240_en_s             => gbt_rx_clk240_en_s, 
        gbt_rx_data_s                  => gbt_rx_data_s,  
        gbt_rx_wordclk_s               => gbt_rx_wordclk_s,    
        gbtRxReady_from_gbtExmplDsgn_s => gbtRxReady_from_gbtExmplDsgn_s,        
        gbt1_tx_data                   => gbt1_tx_data,
        gbt1_txIsDataSel               => gbt1_txIsDataSel,    
        gbt2_tx_data                   => gbt2_tx_data,    
        gbt2_txIsDataSel               => gbt2_txIsDataSel,    
    
        --------------------------------------------------------------------------------
        -- Resets
        --------------------------------------------------------------------------------
        rst_ir_buffer_i                => rst_ir_buffer,
        rst_ir_state_machine_i         => rst_ir_state_machine,
        rst_tcr_buffer_i               => rst_tcr_buffer,
        rst_tcr_state_machine_i        => rst_tcr_state_machine,
        --------------------------------------------------------------------------------
        -- Data to GBT		
        --------------------------------------------------------------------------------
        d_i_sel_ir                     => ctpreadout_ctrl_s(0),
        d_i_sel_tcr                    => ctpreadout_ctrl_s(0),
        global_orbit                   => orbitid,
        d_i_ir                         => trigger_inputs_sync,   
        d_i_tcr                        => l1_class_a, 
        d_o_ir                         => gbt1_tx_data,
        dv_o_ir                        => gbt1_txIsDataSel,
        d_o_tcr                        => gbt2_tx_data,
        dv_o_tcr                       => gbt2_txIsDataSel,
        --------------------------------------------------------------------------------
        -- start/stop monitoring
        --------------------------------------------------------------------------------
        swt_monitoring                 => ctpreadout_stat_s(0),
        --------------------------------------------------------------------------------
        -- State machine coders 
        --------------------------------------------------------------------------------
        ir_state_machine_codes_o       => s_state_num,
        tcr_state_machine_codes_o      => open,
        --------------------------------------------------------------------------------
        -- Miscellaneous
        --------------------------------------------------------------------------------
        sn                             => sn,
        threshold_ir                   => ctpreadout_ctrl_s(1), -- ctpreadout.irrate
        threshold_tcr                  => ctpreadout_ctrl_s(2) -- ctpreadout.tcrate

        );
 
 
 
 
 
 
 	p_main:process
	begin
    		rst_ir_buffer          <= '1';	
    		rst_tcr_buffer         <= '1';	
    		rst_ir_state_machine   <= '1';	
    		rst_tcr_state_machine  <= '1';	
    		wait for 200 ns;           --change time if needed
    		rst_ir_buffer          <= '0';	
    		rst_tcr_buffer         <= '0';	
    		rst_ir_state_machine   <= '0';	
    		rst_tcr_state_machine  <= '0';	
--    		gbt_rx_s <= (others => '0');
--		    wait for 1000 ns;
--		    wait until CLK_0 = '1';
--		    gbt_rx_s <= x"300000000000DEADBEEF";
--    		wait for 130 ns;           --change time if needed
--		    gbt_rx_s <= (others => '0');


--    		wait for 4000 ns;           --change time if needed
--		    gbt_rx_s <= x"300000000000DEADBEEF";
		    wait for 300 ms;
	
	end process;

       
        
        -- ==================================
        -- Saving to TXT
        -- ==================================
        p_file_write:process(olt_clk_trxusr240_s)
                variable v_oline : line;
                variable s_state_num_1: std_logic_vector(3 downto 0);
        begin
                if rising_edge(olt_tx_data_strobe_s) then
                        s_state_num_1 := s_state_num(3 downto 0);
                        hwrite(v_oline, gbt1_tx_data);      -- original 
                        write(v_oline, string'("             "));
                        case s_state_num_1 is
                          when "1000" =>
                            write(v_oline, string'("IDLE/WAIT_TRIGG/SEND_IDLE/NEW_RDH"));
                          when "0001" =>
                            write(v_oline, string'("SEND_SOP"));
                          when "0010" =>
                            write(v_oline, string'("SEND_RDH_WORD0"));
                          when "0011" =>
                            write(v_oline, string'("SEND_RDH_WORD1"));
                          when "0100" =>
                            write(v_oline, string'("SEND_RDH_WORD2"));
                          when "0101" =>
                            write(v_oline, string'("SEND_RDH_WORD3"));
                          when "0110" =>
                            write(v_oline, string'("SEND_DATA"));
                          when "0111" =>
                            write(v_oline, string'("SEND_EOP"));
                          when others =>
                            write(v_oline, string'("ERR"));
                        end case;
                        writeline(out_file,v_oline);
                end if;
        end process;
        


end Behavioral;
