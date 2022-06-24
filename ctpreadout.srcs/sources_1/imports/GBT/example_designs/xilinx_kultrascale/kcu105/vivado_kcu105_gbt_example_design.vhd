--=================================================================================================--
--##################################   Module Information   #######################################--
--=================================================================================================--
--                                                                                         
-- Company:               CERN (PH-ESE-BE)                                                         
-- Engineer:              Manoel Barros Marin (manoel.barros.marin@cern.ch) (m.barros.marin@ieee.org)
--                                                                                                 
-- Project Name:          GBT-FPGA                                                                
-- Module Name:           KC705 - GBT Bank example design                                        
--                                                                                                 
-- Language:              VHDL'93                                                                  
--                                                                                                   
-- Target Device:         KC705 (Xilinx Kintex 7)                                                         
-- Tool version:          ISE 14.5, Vivado 2014.4                                                                
--                                                                                                   
-- Version:               3.1                                                                      
--
-- Description:            
--
-- Versions history:      DATE         VERSION   AUTHOR            DESCRIPTION
--
--                        28/10/2013   3.0       M. Barros Marin   First .vhd module definition   
--                        28/10/2013   3.1       J. Mendez         Vivado support           
--
-- Additional Comments:   Note!! Only ONE GBT Bank with ONE link can be used in this example design.     
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                                                                                           !!
-- !! * The different parameters of the GBT Bank are set through:                               !!  
-- !!   (Note!! These parameters are vendor specific)                                           !!                    
-- !!                                                                                           !!
-- !!   - The MGT control ports of the GBT Bank module (these ports are listed in the records   !!
-- !!     of the file "<vendor>_<device>_gbt_bank_package.vhd").                                !! 
-- !!     (e.g. xlx_v6_gbt_bank_package.vhd)                                                    !!
-- !!                                                                                           !!  
-- !!   - By modifying the content of the file "<vendor>_<device>_gbt_bank_user_setup.vhd".     !!
-- !!     (e.g. xlx_v6_gbt_bank_user_setup.vhd)                                                 !! 
-- !!                                                                                           !! 
-- !! * The "<vendor>_<device>_gbt_bank_user_setup.vhd" is the only file of the GBT Bank that   !!
-- !!   may be modified by the user. The rest of the files MUST be used as is.                  !!
-- !!                                                                                           !!  
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--                                                                                              
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--

-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Custom libraries and packages:
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_exampledesign_package.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity kcu105_gbt_example_design is
        generic (
                 NUM_LINKS		 : integer := 2;
                 GBT_DATA_WIDTH  : integer := 84
                );       
                
    port (  
      --===============--     
      -- General reset --     
      --===============--     

      CPU_RESET                                      : in  std_logic_vector (1 to NUM_LINKS);     
      
      --===============--
      -- Clocks scheme --
      --===============-- 
      
      -- System clock:
      ----------------
     -- SYSCLK_P                                     : in  std_logic;
     -- SYSCLK_N                                     : in  std_logic;   
            
      -- Fabric clock:
      ----------------     
      
       sys_clock_i                                   : in  std_logic;     -- Comment: 100 MHz   sys_clock  (TTC-PON)
      --USER_CLOCK_P                                   : in  std_logic;
      --USER_CLOCK_N                                   : in  std_logic;      
      
      -- MGT(GTX) reference clock:
      ----------------------------
      
      -- Comment: * The MGT reference clock MUST be provided by an external clock generator.
      --
      --          * The MGT reference clock frequency must be 120MHz for the latency-optimized GBT Bank.      
      
      --SMA_MGT_REFCLK_P                               : in  std_logic;
      --SMA_MGT_REFCLK_N                               : in  std_logic; 
       ttcpon_clock_i                                 : in  std_logic; 
       ibds_gte_240_i                                 : in  std_logic; 
     -- ttcpon_clock_i_p                                 : in  std_logic; 
     -- ttcpon_clock_i_n                                 : in  std_logic; 
       
      --
        txFrameClk_from_txPll_i                         : in std_logic;      
      
      --==========--
      -- MGT(GTX) --
      --==========--                   
      
      -- Serial lanes:
      ----------------
      
      SFP_TX_P                                       : out std_logic_vector(1 to NUM_LINKS);
      SFP_TX_N                                       : out std_logic_vector(1 to NUM_LINKS);
      SFP_RX_P                                       : in  std_logic_vector(1 to NUM_LINKS);
      SFP_RX_N                                       : in  std_logic_vector(1 to NUM_LINKS);    
      
      -- SFP control:
      ---------------
      
      SFP_TX_DISABLE                                 : out std_logic_vector (1 to NUM_LINKS);    
      
      --====================--
      -- Signals forwarding --
      --====================--
      
      -- SMA output:
      --------------
      USER_SMA_GPIO_P                                : out std_logic_vector (1 to NUM_LINKS);    
      USER_SMA_GPIO_N                                : out std_logic_vector (1 to NUM_LINKS);
    -- 
    --  S I M U  L A T I O N   
      --==============--
      -- TX ctrl      --
     --==============--    
      txEncoding_from_vio                           : in  std_logic_vector(1 to NUM_LINKS); 
      txIsDataSel_from_user                         : in  std_logic_vector(1 to NUM_LINKS);   
      testPatterSel_from_user                       : in  std_logic_vector(1 downto 0); 
      shiftTxClock_from_vio                         : in  std_logic;                                            -- Comment:  Not in use 
      txShiftCount_from_vio                         : in  std_logic_vector(7 downto 0);                         -- Comment   Not  in use 
      clkMuxSel_from_user_i                         : in  std_logic_vector(1 to NUM_LINKS);  
      gbt_tx_pol_i                                  : in  std_logic_vector(1 to NUM_LINKS); 
      
    -- =========================== -- 
    -- ==      TX Status        == -- 
    -- ========================== 
      mgtReady_from_gbtExmplDsgn                  : out  std_logic_vector(1 to NUM_LINKS); 
      txAligned_from_gbtbank_o                    : out  std_logic_vector(1 to NUM_LINKS); 
      txAlignComputed_from_gbtbank_o              : out  std_logic_vector(1 to NUM_LINKS);
      gbtbank_gbttx_ready_o 					  : out  std_logic_vector(1 to NUM_LINKS);    -- COmment: Added by LPM (Sync Data)
      
     -- ===============================
     -- == ALICE CTP DATA and CLOCKs ==
     -- =============================== 
      --  Comment: Add by LPM 
     gbt_data_user_i                              : in  gbt_reg84_A(1 to NUM_LINKS); 
     --  Comment:  Must be sync with TTC_PON data.         
     TX_FRAMECLK_CTP_I                            : in std_logic;   -- Comment. 240 Mhz CLK 
     TX_CLKEN_CTP_I                               : in std_logic_vector (1 to NUM_LINKS);   -- Comment. Tick, sync w.r.t  TTC_PON CLOCK 
     -- 
     TX_WORDCLK_MGT_O                            : out  std_logic_vector ( 1  to NUM_LINKS); 
        
     -- 
	 RESET_TX_O                                 : out  std_logic_vector (1 to NUM_LINKS);    -- Comment: Could be used to generate TX_CLKEN_CTP_I  
     --==============--
     -- RX ctrl      --
     --==============--  
      rxEncoding_from_vio                          : in  std_logic_vector (1 to NUM_LINKS);
      resetGbtRxReadyLostFlag_from_user            : in  std_logic_vector (1 to NUM_LINKS); 
      resetDataErrorSeenFlag_from_user             : in  std_logic_vector (1 to NUM_LINKS); 
     -- 
       DEBUG_CLK_ALIGNMENT_debug                   : in std_logic_vector (2 downto 0);
       rxBitSlipRstOnEvent_from_user               : in std_logic_vector (1 to NUM_LINKS);
      -- 
      loopBack_from_user                           : in gbt_devspec_reg3_A(1 to NUM_LINKS);
      -- 
      gbt_rx_pol_i                                 : in std_logic_vector(1 to NUM_LINKS); 
      -- =================== -- 
      --   RX Status         --
      -- =================== --
      gbtRxReady_from_gbtExmplDsgn_o               :out  std_logic_vector (1 to NUM_LINKS); 
      gbtRxReadyLostFlag_from_gbtExmplDsgn         :out  std_logic_vector (1 to NUM_LINKS); 
      rxDataErrorSeen_from_gbtExmplDsgn            :out  std_logic_vector (1 to NUM_LINKS); 
      rxExtrDataWidebusErSeen_from_gbtExmplDsgn    :out  std_logic_vector (1 to NUM_LINKS); 
      rxIsData_from_gbtExmplDsgn                   :out  std_logic_vector (1 to NUM_LINKS); 
      gbtErrorDetected_o                           :out  std_logic_vector (1 to NUM_LINKS);
      rxFrameClkReady_from_gbtExmplDsgn            :out  std_logic_vector (1 to NUM_LINKS); 
      rxBitSlipRstCount_from_gbtExmplDsgn          :out  gbt_reg8_A(1 to NUM_LINKS);     
       
     --==  Control 
       manualResetTx_from_user                      : in std_logic_vector (1 to NUM_LINKS); 
       manualResetRx_from_user                      : in std_logic_vector (1 to NUM_LINKS)  
   );
end kcu105_gbt_example_design;

--=================================================================================================--
--####################################   Architecture   ###########################################-- 
--=================================================================================================--

architecture structural of kcu105_gbt_example_design is
   
   --================================ Signal Declarations ================================--          
   
   --===============--
   -- General reset --     
   --===============--     

   signal reset_from_genRst                          : std_logic_vector (1 to NUM_LINKS) := (others => '0');    
   
   --===============--
   -- Clocks scheme -- 
   --===============--   
   
   -- Fabric clock:
   ----------------
   
   signal fabricClk_from_userClockIbufgds            : std_logic;     

   -- MGT(GTX) reference clock:     
   ----------------------------     
  
   signal mgtRefClk_from_smaMgtRefClkIbufdsGtxe2     : std_logic;   

    -- Frame clock:
    ---------------
    signal mgtClk_to_Buf                             : std_logic;
    signal mgtClkBuf_to_txPll                        : std_logic;
    --signal txFrameClk_from_txPll                     : std_logic;
    
   --=========================--
   -- GBT Bank example design --
   --=========================--
   
   -- Control:
   -----------   
   signal txPllReset                                 : std_logic;   
   signal resetgbtfpga_from_jtag                     : std_logic;
   signal resetgbtfpga_from_vio                      : std_logic;
   signal generalReset_from_user                     : std_logic_vector (1 to NUM_LINKS) := (others => '0');      
 
     
   --
   signal gbtErrorDetected                          :  std_logic_vector (1 to NUM_LINKS);
 
  
   --------------------------------------------------      
   signal latOptGbtBankTx_from_gbtExmplDsgn          : std_logic;      --  Comment: Lat_Opy  in TX in use 
   signal latOptGbtBankRx_from_gbtExmplDsgn          : std_logic;      --  Comment: Lat_Opt  in RX is in use
   signal txFrameClkPllLocked_from_gbtExmplDsgn      : std_logic;
   -- 
   signal gbtRxReady_from_gbtExmplDsgn               : std_logic_vector (1 to NUM_LINKS); 
 
  
  
   
   -- Data:
   --------
   
   signal GBTBANK_WB_DATA_s                          : gbt_reg116_A(1 to NUM_LINKS) := (others => (others => '0'));
   
   signal txData_from_gbtExmplDsgn                   : gbt_reg84_A(1 to NUM_LINKS);
   signal rxData_from_gbtExmplDsgn                   : gbt_reg84_A(1 to NUM_LINKS);
   --------------------------------------------------      
   signal txExtraDataWidebus_from_gbtExmplDsgn       : gbt_reg116_A(1 to NUM_LINKS);
   signal rxExtraDataWidebus_from_gbtExmplDsgn       : gbt_reg116_A(1 to NUM_LINKS);
   
   
    
   -- Vivado synthesis tool does not support mixed-language
   -- Solution: http://www.xilinx.com/support/answers/47454.html
      
   
   
   --===========--
   -- Chipscope --
   --===========--
   
   signal vioControl_from_icon           : std_logic_vector(35 downto 0); 
   signal txIlaControl_from_icon         : std_logic_vector(35 downto 0); 
   signal rxIlaControl_from_icon         : std_logic_vector(35 downto 0); 
   signal modifiedBitsCnt                : std_logic_vector(7 downto 0);
   signal countWordReceived              : std_logic_vector(31 downto 0);
   signal countBitsModified              : std_logic_vector(31 downto 0);
   signal countWordErrors                : std_logic_vector(31 downto 0);
   signal gbtModifiedBitFlagFiltered     : std_logic_vector(127 downto 0);
   signal gbtModifiedBitFlag             :gbt_reg84_A(1 to NUM_LINKS) := (others => (others => '0'));   -- Comment: Modified by LPM 
   
  
  
   signal txAligned_from_gbtbank         : std_logic_vector (1 to NUM_LINKS);
   signal txAlignComputed_from_gbtbank   : std_logic_vector (1 to NUM_LINKS);
   signal txAligned_from_gbtbank_latched : std_logic;
   
   --------------------------------------------------
   signal sync_from_vio                              : std_logic_vector(11 downto 0);
   signal async_to_vio                               : std_logic_vector(17 downto 0);
      

   
    
   --=====================--
   -- Latency measurement --
   --=====================--
   signal txFrameClk_from_gbtExmplDsgn               : std_logic_vector(1 to NUM_LINKS);
   signal txWordClk_from_gbtExmplDsgn                : std_logic_vector(1 to NUM_LINKS);
   signal rxFrameClk_from_gbtExmplDsgn               : std_logic_vector(1 to NUM_LINKS);
   signal rxWordClk_from_gbtExmplDsgn                : std_logic_vector(1 to NUM_LINKS);
   --------------------------------------------------                                    
   signal txMatchFlag_from_gbtExmplDsgn              : std_logic_vector(1 to NUM_LINKS);
   signal rxMatchFlag_from_gbtExmplDsgn              : std_logic_vector(1 to NUM_LINKS);
         
   --================--
   signal sysclk:                    std_logic;  
          
   --=====================================================================================--  
--=================================================================================================--
begin                 --========####   Architecture Body   ####========-- 
--=================================================================================================--
   --- Comment: Added  by LPM,  This signal could be used to generate TX_CLKEN_CTP_I. 
    genrst_gen: for i in 1 to NUM_LINKS generate 
      RESET_TX_O(i) <=  reset_from_genRst(i) or  manualResetTx_from_user(i) ; 
    end generate; 
   
   --==================================== User Logic =====================================--
   
   --=============--
   -- SFP control -- 
   --=============-- 
  sfp_dis_gen: for i in 1 to NUM_LINKS generate  
   SFP_TX_DISABLE(i)                                    <= '0';   
  end generate; 
   --===============--
   -- General reset -- 
   --===============--
 gen_Rst_gen: for i in 1 to NUM_LINKS generate  
   genRst: entity work.xlx_ku_reset
      generic map (
         CLK_FREQ                                    =>  100e6)
      port map (     
         CLK_I                                       => fabricClk_from_userClockIbufgds,
         RESET1_B_I                                  => not CPU_RESET(i), 
         RESET2_B_I                                  => not generalReset_from_user(i),
         RESET_O                                     => reset_from_genRst(i) 
      ); 
   end generate; 
   --===============--
   -- Clocks scheme -- 
   --===============--   
   
   -- Fabric clock:
   ----------------
   
   -- Comment: USER_CLOCK frequency: 100MHz 
   
     fabricClk_from_userClockIbufgds  <=  sys_clock_i;
   
      -- Comment: 
      mgtRefClk_from_smaMgtRefClkIbufdsGtxe2  <= ttcpon_clock_i;
      mgtClk_to_Buf   <= ibds_gte_240_i; 
    
    -- Frame clock
    
      -- Comment: Added  by LPM  (240 MHz) 
   --   txFrameClk_from_txPll <= mgtClkBuf_to_txPll ; 
      txFrameClkPllLocked_from_gbtExmplDsgn <= '1';   -- Comment: by LPM Clock unified 
     
          
    -- txPllBuf_inst: bufg_gt
      -- port map (
         -- O                                        => mgtClkBuf_to_txPll, 
         -- I                                        => mgtClk_to_Buf,
         -- CE                                       => '1',
         -- DIV                                      => "000",
         -- CLR                                      => '0',
         -- CLRMASK                                  => '0',
         -- CEMASK                                   => '0'
      -- ); 
      
  
   --=========================--
   -- GBT Bank example design --
   --=========================--	
 -- gbt_exmpl_desgn_gen: for i in 1 to NUM_LINKS generate 
   
   gbtExmplDsgn_inst: entity work.xlx_ku_gbt_example_design
       generic map(
          NUM_LINKS                                              => NUM_LINK_Conf,                 -- Up to 4
          TX_OPTIMIZATION                                        => TX_OPTIMIZATION_Conf,          -- LATENCY_OPTIMIZED or STANDARD
          RX_OPTIMIZATION                                        => RX_OPTIMIZATION_Conf,          -- LATENCY_OPTIMIZED or STANDARD
          TX_ENCODING                                            => TX_ENCODING_Conf,         -- GBT_FRAME or WIDE_BUS
          RX_ENCODING                                            => RX_ENCODING_Conf,         -- GBT_FRAME or WIDE_BUS
          
          DATA_GENERATOR_ENABLE                                  => DATA_GENERATOR_ENABLE_Conf,
          DATA_CHECKER_ENABLE                                    => DATA_CHECKER_ENABLE_Conf,
          MATCH_FLAG_ENABLE                                      => MATCH_FLAG_ENABLE_Conf,
          CLOCKING_SCHEME                                        => CLOCKING_SCHEME_Conf
       )
     port map (

       --==============--
       -- Clocks       --
       --==============--
       FRAMECLK_40MHZ                                             => txFrameClk_from_txPll_i,
       XCVRCLK                                                    => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
       
       TX_FRAMECLK_O                                              => txFrameClk_from_gbtExmplDsgn,        
       TX_WORDCLK_O                                               => txWordClk_from_gbtExmplDsgn,          
       RX_FRAMECLK_O                                              => rxFrameClk_from_gbtExmplDsgn,
       RX_WORDCLK_O                                               => rxWordClk_from_gbtExmplDsgn,      
       
       RX_FRAMECLK_RDY_O                                          => rxFrameClkReady_from_gbtExmplDsgn,
       
       --==============--
       -- Reset        --
       --==============--
       GBTBANK_GENERAL_RESET_I                                    => reset_from_genRst,
       GBTBANK_MANUAL_RESET_TX_I                                  => manualResetTx_from_user,
       GBTBANK_MANUAL_RESET_RX_I                                  => manualResetRx_from_user,
       
       --==============--
       -- Serial lanes --
       --==============--
       GBTBANK_MGT_RX_P                                           => SFP_RX_P,
       GBTBANK_MGT_RX_N                                           => SFP_RX_N,
       GBTBANK_MGT_TX_P                                           => SFP_TX_P,
       GBTBANK_MGT_TX_N                                           => SFP_TX_N,
       
       --==============--
       -- Data         --
       --==============--        
       GBTBANK_GBT_DATA_I                                      => gbt_data_user_i,--(others => '0'),
       GBTBANK_WB_DATA_I                                       => GBTBANK_WB_DATA_s,
       
       TX_DATA_O                                               => txData_from_gbtExmplDsgn,            
       WB_DATA_O                                               => txExtraDataWidebus_from_gbtExmplDsgn,
       
       GBTBANK_GBT_DATA_O                                      => rxData_from_gbtExmplDsgn,
       GBTBANK_WB_DATA_O                                       => rxExtraDataWidebus_from_gbtExmplDsgn,
       
       -- ===============================
       -- == ALICE CTP DATA and CLOCKs ==
       -- ===============================
       --  Comment:  Must be sync with TTC_PON data.         
       TX_FRAMECLK_CTP_I                                          => TX_FRAMECLK_CTP_I, 
       TX_CLKEN_CTP_I                                             => TX_CLKEN_CTP_I,                     -- Comment: OLT Strobe  TX 
		
       
       
       --==============--
       -- Reconf.         --
       --==============--
       GBTBANK_MGT_DRP_RST                                        => '0',
       GBTBANK_MGT_DRP_CLK                                        => fabricClk_from_userClockIbufgds,
       
       --==============--
       -- TX ctrl      --
       --==============--
       TX_ENCODING_SEL_i                                         => txEncoding_from_vio,
       GBTBANK_TX_ISDATA_SEL_I                                   => txIsDataSel_from_user,
       GBTBANK_TEST_PATTERN_SEL_I                                => testPatterSel_from_user, 
       
       --==============--
       -- RX ctrl      --
       --==============--
       RX_ENCODING_SEL_i                                       => rxEncoding_from_vio,
       GBTBANK_RESET_GBTRXREADY_LOST_FLAG_I                    => resetGbtRxReadyLostFlag_from_user,
       GBTBANK_RESET_DATA_ERRORSEEN_FLAG_I                     => resetDataErrorSeenFlag_from_user,
       GBTBANK_RXFRAMECLK_ALIGNPATTER_I                        => DEBUG_CLK_ALIGNMENT_debug,
       GBTBANK_RXBITSLIT_RSTONEVEN_I                           => rxBitSlipRstOnEvent_from_user,
       
       --==============--
       -- TX Status    --
       --==============--
       GBTBANK_GBTTX_READY_O                                  =>  GBTBANK_GBTTX_READY_O,
       -- 
       GBTBANK_LINK_READY_O                                   => mgtReady_from_gbtExmplDsgn,
       GBTBANK_TX_MATCHFLAG_O                                 => txMatchFlag_from_gbtExmplDsgn,
       GBTBANK_TX_ALIGNED_O                                   => txAligned_from_gbtbank,
       GBTBANK_TX_ALIGNCOMPUTED_O                             => txAlignComputed_from_gbtbank,
       
       --==============--
       -- RX Status    --
       --==============--
       GBTBANK_GBTRX_READY_O                                  => gbtRxReady_from_gbtExmplDsgn, --
       GBTBANK_GBTRXREADY_LOST_FLAG_O                         => gbtRxReadyLostFlag_from_gbtExmplDsgn, --
       GBTBANK_RXDATA_ERRORSEEN_FLAG_O                        => rxDataErrorSeen_from_gbtExmplDsgn, --
       GBTBANK_RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O           => rxExtrDataWidebusErSeen_from_gbtExmplDsgn, --
       GBTBANK_RX_MATCHFLAG_O                                 => rxMatchFlag_from_gbtExmplDsgn, --
       GBTBANK_RX_ISDATA_SEL_O                                => rxIsData_from_gbtExmplDsgn, --
       GBTBANK_RX_ERRORDETECTED_O                             => gbtErrorDetected,
       GBTBANK_RX_BITMODIFIED_FLAG_O                          => gbtModifiedBitFlag, 
       GBTBANK_RXBITSLIP_RST_CNT_O                            => rxBitSlipRstCount_from_gbtExmplDsgn,
       
       --==============--
       -- XCVR ctrl    --
       --==============--
       GBTBANK_LOOPBACK_I                                   => loopBack_from_user, 
       GBTBANK_TX_POL                                       => gbt_tx_pol_i, -- Comment: Added by LPM '0',
      --
       GBTBANK_RX_POL                                        => gbt_rx_pol_i  -- Comment: Added by LPM '0'
  ); 
  
--end generate; 

   -- Comment: Added by  LPM
 
   gbtErrorDetected_o            <= gbtErrorDetected;
   gbtRxReady_from_gbtExmplDsgn_o <= gbtRxReady_from_gbtExmplDsgn;

  
  
   --=====================================--
   -- BER                                 --
   --=====================================--
   -- countWordReceivedProc: PROCESS(reset_from_genRst, rxframeclk_from_gbtExmplDsgn)
   -- begin
   
       -- if reset_from_genRst = '1' then
           -- countWordReceived <= (others => '0');
           -- countBitsModified <= (others => '0');
           -- countWordErrors    <= (others => '0');
           
       -- elsif rising_edge(rxframeclk_from_gbtExmplDsgn) then
           -- if gbtRxReady_from_gbtExmplDsgn = '1' then
               
               -- if gbtErrorDetected = '1' then
                   -- countWordErrors    <= std_logic_vector(unsigned(countWordErrors) + 1 );                
               -- end if;
               
               -- countWordReceived <= std_logic_vector(unsigned(countWordReceived) + 1 );
           -- end if;
           
           -- countBitsModified <= std_logic_vector(unsigned(modifiedBitsCnt) + unsigned(countBitsModified) );
       -- end if;
   -- end process;
   
   -- gbtModifiedBitFlagFiltered(127 downto 84) <= (others => '0');
   -- gbtModifiedBitFlagFiltered(83 downto 0) <= gbtModifiedBitFlag when gbtRxReady_from_gbtExmplDsgn = '1' else
                                              -- (others => '0');
 
 ---==================================================
  ---===         Comment:  CountOnes                ===
  ---==================================================   
   -- countOnesCorrected: entity work.CountOnes
       -- Generic map (SIZE           => 128,
                    -- MAXOUTWIDTH        => 8
       -- )
       -- Port map( 
           -- Clock    => rxframeclk_from_gbtExmplDsgn, -- Warning: Because the enable signal (1 over 3 or 6 clock cycle) is not used, the number of error is multiplied by 3 or 6.
           -- I        => gbtModifiedBitFlagFiltered,
           -- O        => modifiedBitsCnt);            
 
    -- ==============================  
    -- ==  RESET FROM THE USER    ===
    -- ==============================    
   gral_gen: for i in 1 to NUM_LINKS generate 
       generalReset_from_user(i)  <=  not(txFrameClkPllLocked_from_gbtExmplDsgn);
  end generate;
  --
     -- Comment: Added by LPM 

      txAligned_from_gbtbank_o       <= txAligned_from_gbtbank;  
      txAlignComputed_from_gbtbank_o <= txAlignComputed_from_gbtbank; 
       
   -- ===============================================================
   -- ==  Alignment Latch Proc 
   -- =================================================================  
    -- alignmenetLatchProc: process(txFrameClk_from_txPll)
    -- begin
    
        -- if reset_from_genRst = '1' then
            -- txAligned_from_gbtbank_latched <= '0';
            
        -- elsif rising_edge(txFrameClk_from_txPll) then
        
           -- if txAlignComputed_from_gbtbank(1) = '1' then
                -- txAligned_from_gbtbank_latched <= txAligned_from_gbtbank(1);
           -- end if;
           
        -- end if;
    -- end process;
  
   --=====================--

    TX_WORDCLK_MGT_O <= txWordClk_from_gbtExmplDsgn;
                                                           
   USER_SMA_GPIO_P                                  <= txWordClk_from_gbtExmplDsgn when clkMuxSel_from_user_i =  "11" else
                                                        txMatchFlag_from_gbtExmplDsgn;
                                                           
   USER_SMA_GPIO_N                                   <= txFrameClk_from_gbtExmplDsgn when clkMuxSel_from_user_i = "11" else
                                                        rxMatchFlag_from_gbtExmplDsgn;
 
   
   --=====================================================================================--   
end structural;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--