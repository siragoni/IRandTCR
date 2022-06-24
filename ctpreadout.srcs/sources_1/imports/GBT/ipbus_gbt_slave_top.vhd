--==================================================================
--== Name:  Top
--== Date: July 18th 2018
--== Description:   IPbus Slave to GBT configuration and control 
--==================================================================
 library  IEEE; 
 use ieee.std_logic_1164.all;
 use ieee.std_logic_unsigned.all;
 use ieee.numeric_std.all; 
 
 --==========================================================================
 Library UNISIM;
 use UNISIM.vcomponents.all;

 --============================================
 library  work; 
 use work.all; 
 --=============================================
 --==  Custom    Library                      ==
 --=============================================
 use work.ipbus.all;                                -- Comment:   IPbus control     
 use work.system_package.all;                       -- Comment:   IPbus  data size definitions
 use work.ipbus_decode_ltu_logic.all;               -- Comment:   IPbus  address table 
 use work.ipbus_reg_types.all;
-- 
--   TTC-PON OLT  Package 
 --use work.pon_olt_package.all;
  --==============================================================================
--                           E N T I T Y                                        ==
-- ===============================================================================   
  entity  ipbus_gbt_slave_top is 
        generic (  width_gbt_frame    : integer := 84; 
                   pon_olt_reg_width  : integer := 32;
                   g_DATA_USR_WIDTH   : integer := 200             -- Comment: Check this value en olt_tx and ttc_pon_olt_gearbox, must be equals.                                                                       
             );                                               
     port ( 
           --*********************************
           --  C O N T R O L  S I G N A L  --
           --*********************************
           ipb_clk       : in  std_logic;               -- Comment: 32 MHz. 
           reset_i       : in  std_logic; 
           --===================================
           --  IPBus  SLave  Controls                    
           --==============================
            -- 
           -- IPbus  In/Out             ===
           --==============================
           ipbus_i    : in  ipb_wbus; 
           ipbus_o    : out ipb_rbus;
           --
           -- ==================================
           --  GENERAL IN/OUT 
           -------
           --  
           sys_clock_i                                   : in std_logic;   -- Comment. Free Running Clock 
          
           -- Clock Signa
            ttcpon_clock_i                                 : in  std_logic;   -- Comment: 240 MHz.  CDC 
            mgt_olt_ref_clock_i                            : in  std_logic;   -- Comment  240 MHZ  TTC_PON and GBT    
            ibds_gte_240_i                                 : in  std_logic;   -- Comment  TX PLL Aligner 
            
           -- ===============================
           -- == ALICE CTP DATA and CLOCKs ==
           -- ===============================
            ctp_ttc_message_i                                : in std_logic_vector (g_DATA_USR_WIDTH-1 downto 0); 
           --  Comment:  Must be sync with TTC_PON data.         
           tx_frameclk_ctp_i                            : in std_logic;   -- Comment. 240 Mhz CLK  (could be ttc-pon ref clock.)
           tx_clken_ctp_i                               : in std_logic;   -- Comment. Tick, sync w.r.t  TTC_PON CLOCK 
           --
           --     tx_wordclk_o                                 : out std_logic; 
           -- 
           -- GBT TX READY --           
           -- gbtbank_gbttx_ready_o 					     : out std_logic;    -- Comment: Added by LPM (Sync Data)
		   --
           --  RESET TX 
            reset_tx_o                                   : out std_logic;     -- Comment: Could be used to sync  Data. 
           -- Serial lanes.  
              SFP_TX_P_o                                 : out std_logic;
              SFP_TX_N_o                                 : out std_logic;
              SFP_RX_P_i                                 : in  std_logic;
              SFP_RX_N_i                                 : in  std_logic;    
  
           -- SFP Control                                
              SFP_TX_DISABLE_o                           : out std_logic; 

           -- CLOCK  Monitor/Match Flag                  
              USER_SMA_GPIO_N_o                          : out std_logic; 
              USER_SMA_GPIO_P_o                          : out std_logic
           
          );
    end ipbus_gbt_slave_top; 
      
----------------------------------------------------------
--          A R C H I T E C T U R E                    ---
----------------------------------------------------------
  architecture ipbus_gbt_slave_top_beha  of ipbus_gbt_slave_top is 
  
     ----------------------------------------------
     --          Auxiliaries  siganals           --           
     ----------------------------------------------
     --... IPbus  Signals.. 
      signal   ipbw : ipb_wbus_array(N_SLAVES -1 downto 0);
      signal   ipbr : ipb_rbus_array(N_SLAVES -1 downto 0); 
     --
      signal   sel  :  integer := 0;    
     --
      signal   ipbw_zero: ipb_wbus; 
      signal   ipbr_zero: ipb_rbus;
      --
      
      -- 
      -- Signal of GBT 
        -- General Outputs  (IPbus to GBT)
       signal CPU_RESET_s                                 : std_logic :='0'; 
       signal manualResetTx_from_user_s                   : std_logic :='0'; 
       signal manualResetRx_from_user_s                   : std_logic :='0';   
     
       --Tx Ctrl  (IPbus to GBT) 
       signal clkMuxSel_from_user_s                       : std_logic := '0';
       signal txEncoding_from_vio_s                       : std_logic := '0' ; 
       signal txIsDataSel_from_user_s                     : std_logic := '0'; 
       signal testPatterSel_from_user_s                   : std_logic_vector(1 downto 0):= (others =>'0'); 
       signal shiftTxClock_from_vio_s                     : std_logic := '0'; 
       signal txShiftCount_from_vio_s                     : std_logic_vector(7 downto 0):= (others => '0');
       signal gbt_tx_pol_s                                : std_logic := '0'; 
       
       -- RX ctrl  (IPbus to GBT)
       ----------------------------  
       signal rxEncoding_from_vio_s                          : std_logic := '0';
       signal resetGbtRxReadyLostFlag_from_user_s            : std_logic := '0'; 
       signal resetDataErrorSeenFlag_from_user_s             : std_logic := '0'; 
                                                       
       signal  DEBUG_CLK_ALIGNMENT_debug_s                   : std_logic_vector(2 downto 0) := (others => '0');
       signal  rxBitSlipRstOnEvent_from_user_s               : std_logic := '0';
                                                      
       signal loopBack_from_user_s                           : std_logic_vector(2 downto 0) := (others => '0');
       signal gbt_rx_pol_s                                   : std_logic := '0';    
       --  TX Status  (GBT to IPbus)   -- 
       -- --------------------------------
       signal  mgtReady_from_gbtExmplDsgn_s                  : std_logic := '0'; 
       signal  txAligned_from_gbtbank_s                      : std_logic := '0'; 
       signal  txAlignComputed_from_gbtbank_s                : std_logic := '0';
       
       --   RX Status  (GBT_to IPbus) --
       -- ----------------------------------- --
       signal  gbtRxReady_from_gbtExmplDsgn_s                 : std_logic:= '0'; 
       signal  gbtRxReadyLostFlag_from_gbtExmplDsgn_s         : std_logic:= '0'; 
       signal  rxDataErrorSeen_from_gbtExmplDsgn_s            : std_logic:= '0'; 
       signal  rxExtrDataWidebusErSeen_from_gbtExmplDsgn_s    : std_logic:= '0'; 
       signal  rxIsData_from_gbtExmplDsgn_s                   : std_logic:= '0'; 
       signal  gbtErrorDetected_s                             : std_logic:= '0';
       signal  rxFrameClkReady_from_gbtExmplDsgn_s            : std_logic:= '0'; 
       signal  rxBitSlipRstCount_from_gbtExmplDsgn_s          : std_logic_vector (7 downto 0) :=  (others => '0'); 
              
      -- CDC  TTC-PON to GBT 
       signal   tx_wordclk_s                              : std_logic:= '0';   -- Comment. Tick, sync w.r.t GBT Clock Domain
       signal   tx_clken_ctp_s                              : std_logic:= '0';   -- Comment. Tick, sync w.r.t GBT Clock Domain
       signal   gbt_data_user_s                             : std_logic_vector (width_gbt_frame -1 downto 0) := (others => '0');
       signal   gbtbank_gbttx_ready_s                       : std_logic :='0'; 
      
    constant  active_s: boolean := true;    

     ---
     -- ========================================== --
     -- ............. BEGIN....................... --
     -- ========================================== --
     begin 
          
         -- ======================================
         --...... SLAVE  UNDER  TEST  .......---
         -- =====================================
   

    gbt_unified_inst: entity work.kcu105_gbt_example_design
            port map (               
                     CPU_RESET                                 => CPU_RESET_s,                                    
                     sys_clock_i                               => sys_clock_i , 
                     ttcpon_clock_i                            => mgt_olt_ref_clock_i,
                     ibds_gte_240_i                            => ibds_gte_240_i,                        
                     SFP_TX_P                                  => SFP_TX_P_o,                                   
                     SFP_TX_N                                  => SFP_TX_N_o,                                   
                     SFP_RX_P                                  => SFP_RX_P_i,                                   
                     SFP_RX_N                                  => SFP_RX_N_i,                                   
                     SFP_TX_DISABLE                            => SFP_TX_DISABLE_o,                             
                     USER_SMA_GPIO_P                           => USER_SMA_GPIO_P_o,                            
                     USER_SMA_GPIO_N                           => USER_SMA_GPIO_N_o,                            
                     txEncoding_from_vio                       => txEncoding_from_vio_s,                        
                     txIsDataSel_from_user                     => txIsDataSel_from_user_s,                      
                     testPatterSel_from_user                   => testPatterSel_from_user_s,                    
                     shiftTxClock_from_vio                     => shiftTxClock_from_vio_s,                      
                     txShiftCount_from_vio                     => txShiftCount_from_vio_s, 
                     clkMuxSel_from_user_i                     => clkMuxSel_from_user_s,     
                     gbt_tx_pol_i                              => gbt_tx_pol_s, 
                     mgtReady_from_gbtExmplDsgn                => mgtReady_from_gbtExmplDsgn_s,                 
                     txAligned_from_gbtbank_o                  => txAligned_from_gbtbank_s,                   
                     txAlignComputed_from_gbtbank_o            => txAlignComputed_from_gbtbank_s,  
                     gbtbank_gbttx_ready_o                     => gbtbank_gbttx_ready_s,
                     gbt_data_user_i                           => gbt_data_user_s,
                     TX_FRAMECLK_CTP_I                         => tx_frameclk_ctp_i,
                     TX_CLKEN_CTP_I                            => tx_clken_ctp_s, 
                     TX_WORDCLK_MGT_O                          => tx_wordclk_s ,  
                     RESET_TX_O                                => reset_tx_o,                            
                     rxEncoding_from_vio                       => rxEncoding_from_vio_s,                       
                     resetGbtRxReadyLostFlag_from_user         => resetGbtRxReadyLostFlag_from_user_s,         
                     resetDataErrorSeenFlag_from_user          => resetDataErrorSeenFlag_from_user_s,          
                     DEBUG_CLK_ALIGNMENT_debug                 => DEBUG_CLK_ALIGNMENT_debug_s,                
                     rxBitSlipRstOnEvent_from_user             => rxBitSlipRstOnEvent_from_user_s,            
                     loopBack_from_user                        => loopBack_from_user_s,
                     gbt_rx_pol_i                              => gbt_rx_pol_s,                     
                     gbtRxReady_from_gbtExmplDsgn_o            => gbtRxReady_from_gbtExmplDsgn_s,            
                     gbtRxReadyLostFlag_from_gbtExmplDsgn      => gbtRxReadyLostFlag_from_gbtExmplDsgn_s,      
                     rxDataErrorSeen_from_gbtExmplDsgn         => rxDataErrorSeen_from_gbtExmplDsgn_s,         
                     rxExtrDataWidebusErSeen_from_gbtExmplDsgn => rxExtrDataWidebusErSeen_from_gbtExmplDsgn_s, 
                     rxIsData_from_gbtExmplDsgn                => rxIsData_from_gbtExmplDsgn_s,                
                     gbtErrorDetected_o                        => gbtErrorDetected_s,                        
                     rxFrameClkReady_from_gbtExmplDsgn         => rxFrameClkReady_from_gbtExmplDsgn_s,        
                     rxBitSlipRstCount_from_gbtExmplDsgn       => rxBitSlipRstCount_from_gbtExmplDsgn_s,       
                     manualResetTx_from_user                   => manualResetTx_from_user_s,                   
                     manualResetRx_from_user                   => manualResetRx_from_user_s 
                 );                     
    
    
   
         IPbus_gbt_usr_inst: entity work.ipb_gbt_slave
            port map (
                    -------------------------------
                    --    Ipbus Protocol         --
                    -------------------------------
                     clk                    => ipb_clk,
                     reset                  => reset_i, 
                     ipbus_in               => ipbus_i,
                     ipbus_out              => ipbus_o,
             
                     CPU_RESET_o                 =>  CPU_RESET_s,                               
                     manualResetTx_from_user_o   =>  manualResetTx_from_user_s,               
                     manualResetRx_from_user_o   =>  manualResetRx_from_user_s,               
            
                     txEncoding_from_vio_o       => txEncoding_from_vio_s,                        
                     txIsDataSel_from_user_o     => txIsDataSel_from_user_s,                      
                     testPatterSel_from_user_o   => testPatterSel_from_user_s,                    
                     shiftTxClock_from_vio_o     => shiftTxClock_from_vio_s,                      
                     txShiftCount_from_vio_o     => txShiftCount_from_vio_s,  
                     clkMuxSel_from_user_o       => clkMuxSel_from_user_s,      
                     gbt_tx_pol_o                => gbt_tx_pol_s,                     
                   
                     rxEncoding_from_vio_o                => rxEncoding_from_vio_s,                     
                     resetGbtRxReadyLostFlag_from_user_o  => resetGbtRxReadyLostFlag_from_user_s,       
                     resetDataErrorSeenFlag_from_user_o   => resetDataErrorSeenFlag_from_user_s,        
                     --                                           
                     DEBUG_CLK_ALIGNMENT_debug_o          =>  DEBUG_CLK_ALIGNMENT_debug_s,         
                     rxBitSlipRstOnEvent_from_user_o      =>  rxBitSlipRstOnEvent_from_user_s,     
                     --                                          
                     loopBack_from_user_o                 =>  loopBack_from_user_s,                 
                      gbt_rx_pol_o                         =>  gbt_rx_pol_s,
                      
                     mgtReady_from_gbtExmplDsgn_i          => mgtReady_from_gbtExmplDsgn_s,       
                     txAligned_from_gbtbank_i              => txAligned_from_gbtbank_s,           
                     txAlignComputed_from_gbtbank_i        => txAlignComputed_from_gbtbank_s,     
                     
                     --   RX Status  (GBT_to IPbus) --
                     -- ----------------------------------- --
                     gbtbank_gbttx_ready_i                      => gbtbank_gbttx_ready_s,                                                                   
                     gbtRxReady_from_gbtExmplDsgn_i             => gbtRxReady_from_gbtExmplDsgn_s,             
                     gbtRxReadyLostFlag_from_gbtExmplDsgn_i     => gbtRxReadyLostFlag_from_gbtExmplDsgn_s,     
                     rxDataErrorSeen_from_gbtExmplDsgn_i        => rxDataErrorSeen_from_gbtExmplDsgn_s,        
                     rxExtrDataWidebusErSeen_from_gbtExmplDsgn_i=> rxExtrDataWidebusErSeen_from_gbtExmplDsgn_s,
                     rxIsData_from_gbtExmplDsgn_i               => rxIsData_from_gbtExmplDsgn_s,               
                     gbtErrorDetected_i                         => gbtErrorDetected_s,                         
                     rxFrameClkReady_from_gbtExmplDsgn_i        => rxFrameClkReady_from_gbtExmplDsgn_s,        
                     rxBitSlipRstCount_from_gbtExmplDsgn_i      => rxBitSlipRstCount_from_gbtExmplDsgn_s      
                    );              
                    
           ctp_cdc_gbt_inst: entity work. ctp_cdc_gbt  
                port map (
                 reset_i               => reset_i,
                 gbt_tx_clk_i          => tx_wordclk_s,
                 emu_clock_i           => ttcpon_clock_i,
                 ctp_message_strobe_i  => tx_clken_ctp_i,
                 ctp_message_i         => ctp_ttc_message_i,
                 gbtbank_gbttx_ready_i => gbtbank_gbttx_ready_s, 
                 gbt_frame_o           => gbt_data_user_s,
                 gbt_strobe_o          => tx_clken_ctp_s
                );
                    
                    
                    
                    
                    
   end ipbus_gbt_slave_top_beha; 