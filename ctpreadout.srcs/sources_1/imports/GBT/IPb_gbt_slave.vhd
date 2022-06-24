--====================================================         
--== Name:        ipb_gbt_slave                     ==
--== Start Date:   June   18th   2018               ==
--== Description:  Slave IPbus to  GBT              ==
-- ===================================================
--  Last Modification:  June 18th 2019              ==
--====================================================
--==       System Library                          ===
--====================================================
library  IEEE; 
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; 

------------------------------------------------------
Library UNISIM;  
use UNISIM.vcomponents.all; 

use      work.all; 

--====================================================
--==       Custom libraries and packages            ==
--====================================================
use work.ipbus.all; 
use work.system_package.all;
use work.ipbus_reg_types.all;
-----------------------------------------------------
--              E N T I T Y                        --
-----------------------------------------------------
 entity ipb_gbt_slave is 
     generic ( g_NUMBER_OLT_LANES       : integer := 9; 
               GBT_WIDTH                : integer := 84; 
               N_REG                    : natural := 4                 -- Comment:  Number of the user registers  defined by User
              );       
     port ( 
           -------------------------------
           --    Ipbus Protocol         --
           -------------------------------
            clk         :in  std_logic;           -- Comment: IPb_clock  
            reset       :in  std_logic; 
            
         -- 
            reg_resets_i:   in  std_logic_vector (31 downto 0) := (others => '0'); 
            reg_tx_ctrl_i:  in  std_logic_vector (31 downto 0) := (others => '0');  -- Comment
            reg_rx_ctrl_i:  in  std_logic_vector (31 downto 0) := (others => '0');  -- Comment
            reg_stat_o:     out std_logic_vector (31 downto 0) := (others => '0');  -- Comment


            --  Different clock domain 
            --ttcpon_clock      :in    std_logic;   -- Comment: TTC_PON Clock  240 MHz 
            --------------------------------
            --  GBT _FPGA 
            ----------------
            -- General Outputs  (IPbus to GBT)
            CPU_RESET_o                                  : out  std_logic; 
            manualResetTx_from_user_o                   : out std_logic; 
            manualResetRx_from_user_o                   : out std_logic; 
            
            --Tx Ctrl  (IPbus to GBT) 
            clkMuxSel_from_user_o                     : out std_logic;  
            txEncoding_from_vio_o                        : out std_logic; 
            txIsDataSel_from_user_o                     : out std_logic; 
            testPatterSel_from_user_o                   : out std_logic_vector(1 downto 0); 
            shiftTxClock_from_vio_o                     : out std_logic; 
            txShiftCount_from_vio_o                     : out std_logic_vector(7 downto 0);
            gbt_tx_pol_o                                : out std_logic; 
     
             --==============--
             
           -- RX ctrl  (IPbus to GBT)
           ----------------------------  
            rxEncoding_from_vio_o                       : out   std_logic;
            resetGbtRxReadyLostFlag_from_user_o         : out   std_logic; 
            resetDataErrorSeenFlag_from_user_o          : out   std_logic; 
           --                                                 
            DEBUG_CLK_ALIGNMENT_debug_o                 : out  std_logic_vector(2 downto 0);
            rxBitSlipRstOnEvent_from_user_o             : out  std_logic;
            --                                               
            loopBack_from_user_o                         : out   std_logic_vector(2 downto 0);
            gbt_rx_pol_o                                 : out std_logic;
              
           
           --  TX Status  (GBT to IPbus)   -- 
           -- --------------------------------
             mgtReady_from_gbtExmplDsgn_i                  : in  std_logic; 
             txAligned_from_gbtbank_i                      : in   std_logic; 
             txAlignComputed_from_gbtbank_i                : in  std_logic;
           
           --   RX Status  (GBT_to IPbus) --
           -- ----------------------------------- --
             
             gbtbank_gbttx_ready_i                          :in std_logic; 
             gbtRxReady_from_gbtExmplDsgn_i                 :in std_logic; 
             gbtRxReadyLostFlag_from_gbtExmplDsgn_i         :in std_logic; 
             rxDataErrorSeen_from_gbtExmplDsgn_i            :in std_logic; 
             rxExtrDataWidebusErSeen_from_gbtExmplDsgn_i    :in std_logic; 
             rxIsData_from_gbtExmplDsgn_i                   :in std_logic; 
             gbtErrorDetected_i                             :in std_logic;
             rxFrameClkReady_from_gbtExmplDsgn_i            :in std_logic; 
             rxBitSlipRstCount_from_gbtExmplDsgn_i          :in std_logic_vector (7 downto 0)
             
       
         ); 
  end ipb_gbt_slave; 
----------------------------------------------------------
--          A R C H I T E C T U R E                    ---
----------------------------------------------------------
 architecture ipb_gbt_slave_beha  of  ipb_gbt_slave is 
    
    ----------------------------------------------
    --          Auxiliaries  siganals           --           
    --------------------------------------------- 
     -------------------------------------
    -- 
     signal  gbt_cpu_reset_aux1 : std_logic := '0'; 
     signal  gbt_cpu_reset_aux2 : std_logic := '0'; 
    --
     signal  manualResetTx_from_user_o_aux1    : std_logic := '0'; 
     signal  manualResetTx_from_user_o_aux2    : std_logic := '0'; 
     --    
     signal  manualResetRx_from_user_o_aux1    : std_logic := '0'; 
     signal  manualResetRx_from_user_o_aux2    : std_logic := '0'; 
     --    
     signal  resetGbtRxReadyLostFlag_from_user_aux1    : std_logic := '0'; 
     signal  resetGbtRxReadyLostFlag_from_user_aux2    : std_logic := '0';  
     --
     signal  resetDataErrorSeenFlag_from_user_aux1    : std_logic := '0'; 
     signal  resetDataErrorSeenFlag_from_user_aux2    : std_logic := '0';  
     --
     signal  shiftTxClock_from_vio_aux1    : std_logic := '0'; 
     signal  shiftTxClock_from_vio_aux2   : std_logic := '0';

   begin
       -------------------------------------
         -----------------------------------------
           -- Define Action 
           ----------------------------------------
          -------------------------------
          --    CPU RESET    ---
          -------------------------------
            cpu_reset_proc: process (clk)
                begin 
                    if (rising_edge(clk)) then
                        gbt_cpu_reset_aux1 <= reg_resets_i(0);
                         gbt_cpu_reset_aux2 <= gbt_cpu_reset_aux1;
                      
                    end if; 
                  end process;
            
                CPU_RESET_o <= gbt_cpu_reset_aux1 and not gbt_cpu_reset_aux2;
            
         -------------------------------
         --  TX_RESET _USER    ---
         -------------------------------
           tx_reset_proc: process (clk)
                begin 
                    if (rising_edge(clk)) then
                         manualResetTx_from_user_o_aux1<= reg_resets_i(1);
                          manualResetTx_from_user_o_aux2    <= manualResetTx_from_user_o_aux1;
                      
                    end if; 
                  end process;
          manualResetTx_from_user_o    <= manualResetTx_from_user_o_aux1 and not manualResetTx_from_user_o_aux2;        
  
        -------------------------------
         --  RX_RESET _USER    ---
         -------------------------------
           rx_reset_proc: process (clk)
                begin 
                    if (rising_edge(clk)) then
                         manualResetRx_from_user_o_aux1<= reg_resets_i(2);
                          manualResetRx_from_user_o_aux2    <= manualResetRx_from_user_o_aux1;
                      
                    end if; 
                  end process;
          manualResetRx_from_user_o    <= manualResetRx_from_user_o_aux1 and not manualResetRx_from_user_o_aux2;    
          
          --------------------------------------------
          ---  RESET GBT RX READY LOST FLAG USER   ---
          -------------------------------------------- 
               reset_gbt_rx_ready: process (clk)
                begin 
                    if (rising_edge(clk)) then
                          resetGbtRxReadyLostFlag_from_user_aux1<= reg_resets_i(3);
                          resetGbtRxReadyLostFlag_from_user_aux2    <=  resetGbtRxReadyLostFlag_from_user_aux1;
                      
                    end if; 
                  end process;
            resetGbtRxReadyLostFlag_from_user_o  <=  resetGbtRxReadyLostFlag_from_user_aux1 and not resetGbtRxReadyLostFlag_from_user_aux2;  
            
          --------------------------------------------
          ---  RESET DATA ERROR SEEN FLAG  USER   ---
          --------- -----------------------------------
             reset_data_error: process (clk)
                begin 
                    if (rising_edge(clk)) then
                          resetDataErrorSeenFlag_from_user_aux1<= reg_resets_i(4);
                          resetDataErrorSeenFlag_from_user_aux2    <=  resetDataErrorSeenFlag_from_user_aux1;
                      
                    end if; 
                  end process;
           resetDataErrorSeenFlag_from_user_o  <=  resetDataErrorSeenFlag_from_user_aux1 and not resetDataErrorSeenFlag_from_user_aux2; 
        
          --------------------------------------------
          ---   SHIFT  TX  CLOCK  FROM USER      ---
          --------- -----------------------------------
             shift_tx_clock: process (clk)
                begin 
                    if (rising_edge(clk)) then
                          shiftTxClock_from_vio_aux1<= reg_resets_i(5);
                          shiftTxClock_from_vio_aux2    <=  shiftTxClock_from_vio_aux1;
                      
                    end if; 
                  end process;
           shiftTxClock_from_vio_o  <=  shiftTxClock_from_vio_aux1 and not shiftTxClock_from_vio_aux2;
           
         --                +----------------------------+     
         ------------------|  IPb Register  TX_CONTROL  |-----------------------------
         --                +----------------------------+
         -- TX_CONTROL...      
            txShiftCount_from_vio_o    <= reg_tx_ctrl_i (7 downto 0);
          ---  TX Encoding 
          txEncoding_from_vio_o      <= reg_tx_ctrl_i(8);   
          -- TX  Data Sel _ from User 
            txIsDataSel_from_user_o    <= reg_tx_ctrl_i (9);   
          -- TX test Patter Sel from user 
            testPatterSel_from_user_o <= reg_tx_ctrl_i (11 downto 10);    
          -- 
            clkMuxSel_from_user_o <= reg_tx_ctrl_i (12);  
          --
            gbt_tx_pol_o  <= reg_tx_ctrl_i (13); 
             
         --                +----------------------------+     
         ------------------|  IPb Register  RX_CONTROL  |-----------------------------
         --                +----------------------------+
          -- RX_CONTROL 
             rxEncoding_from_vio_o   <= reg_rx_ctrl_i (0);
               
             DEBUG_CLK_ALIGNMENT_debug_o <= reg_rx_ctrl_i (3 downto 1); 
          -- 
             rxBitSlipRstOnEvent_from_user_o <= reg_rx_ctrl_i(4);
          -- 
             loopBack_from_user_o <= reg_rx_ctrl_i (7 downto 5);
          -- 
             gbt_rx_pol_o        <=  reg_rx_ctrl_i (8);
             
          --------------------------------------
          --  GBT  STATUS    
          ---------------------------------                        
           reg_stat_o <=   "0000000000000" &
                         gbtbank_gbttx_ready_i                       &    -- Comment 1b
                         gbtRxReady_from_gbtExmplDsgn_i              &    -- Comment 1b
                         gbtRxReadyLostFlag_from_gbtExmplDsgn_i      &    -- Comment 1b
                         rxDataErrorSeen_from_gbtExmplDsgn_i         &    -- Comment 1b
                         rxExtrDataWidebusErSeen_from_gbtExmplDsgn_i &    -- Comment 1b
                         rxIsData_from_gbtExmplDsgn_i                &    -- Comment 1b
                         gbtErrorDetected_i                          &    -- Comment 1b
                         rxFrameClkReady_from_gbtExmplDsgn_i         &    -- Comment 1b
                         rxBitSlipRstCount_from_gbtExmplDsgn_i       &    -- Comment 8b
                         mgtReady_from_gbtExmplDsgn_i                &    -- Comment 1b
                         txAligned_from_gbtbank_i                    &    -- Comment 1b
                         txAlignComputed_from_gbtbank_i;                  -- Comment 1b
                        
     end ipb_gbt_slave_beha;                       
                          
        