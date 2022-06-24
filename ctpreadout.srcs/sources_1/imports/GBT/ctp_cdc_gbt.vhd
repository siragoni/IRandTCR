--------------------------------------------------------------- 
-- Name: comu_selec                                          --
-- Date: July 22nd 2018                                      --
-- Description:  CDC CTP_EMULATOR (olt_tX_ref (240MHz)) to   --
--               GBT_TX (240 Mhz)  
--------------------------------------------------------------- 
library  IEEE; 
 use ieee.std_logic_1164.all;
 use ieee.std_logic_arith.all;
 use ieee.std_logic_unsigned.all;
 use ieee.numeric_std.all; 
 

 --==========================================================================
 --                        E N T I T Y                                     ==
 --==========================================================================
 entity   ctp_cdc_gbt is 
         generic (
                  g_DATA_USR_WIDTH       : integer := 200 ;                --  Comment g_WORD_WIDTH
                  gbt_frame_width        : integer := 84;                  --  Comment GBT_FRAME_WIDTH
                  message_sync_width     : integer := 120                  --  Comment Sync width 
                 );                   
               
    port (
       ---  General  Control 
       ------------------------
        reset_i        :  in  std_logic;                                                   --  Comment:  General Reset   
        gbt_tx_clk_i   :  in  std_logic;                                                   --  Comment:  240 Mhz
        olt_txrx_usr_clk    :  in  std_logic;                                              --  Comment   CTP  Freq 240 Mhz.  (Olt_Tx_clk)
               
       -- CTP Emulator  Message and  Strobe  in TTCPON clock domain                                 
       ----------------------------------------           
        ctp_message_strobe_i :  in  std_logic;                                             -- Comment: Continuously received  every 40 MHz, aligned to Olt_tx_clk
        ctp_message_i        :  in  std_logic_vector (g_DATA_USR_WIDTH-1  downto 0);       -- Comment: Size: OLT_tx_user
       
       -- GBT CLOCK  DOMAIN 
       gbtbank_gbttx_ready_i : in  std_logic;                                              -- Comment: GBT TX Ready 1=  Ready , 0 = No Ready 
         
        -- GBT Message
        ------------------------------------------
        gbt_frame_o     :  out std_logic_vector (gbt_frame_width-1  downto 0);
        gbt_strobe_o    :  out std_logic;
        txIsDataSel_from_ctpemu_data_o : out std_logic

        
        );
        
    end ctp_cdc_gbt; 
  --========================================================================
  --==         A  R C H I T E C T U R E                                   ==
  --=======================================================================
      architecture  ctp_cd_gbt_beha  of  ctp_cdc_gbt is 
  --======================================================================
   
     constant   gbt_SC_IC: std_logic_vector (1 downto 0) := "11" ;       --->  Comment: SC-IC Internal control  GBTx 
     constant   gbt_SC_EC: std_logic_vector (1 downto 0) := "01" ;       --->  Comment: SC-EC External control  (Can be used indistinguishably  for Data Acquisition (DAQ)) 
   --=======================================================================================
   signal gbt_frame_s: std_logic_vector (gbt_frame_width downto 0) :=(others => '0');   -- Comment bit (85 (84 downto 0)) is provided for CTP
   signal message_sync_gbt_s: std_logic_vector (message_sync_width-1  downto 0) :=(others => '0');
    
  -- ======================================================================
  -- ==    S i g n a l     A l i g n e d                                 ==
  -- ======================================================================
       signal olt_dff_1: std_logic := '0'; 
      

       
 -----------------------------------------------------------------
   --==   Debug Properties --> Comment:                          == 
   -----------------------------------------------------------------
   --    attribute mark_debug : string; 
   --    attribute keep       : string; 
    
    
   --   attribute mark_debug of  gbt_frame_o:   signal is "true"; 
   --   attribute mark_debug of  gbt_strobe_o:  signal is "true";
    
     
   --   attribute keep of  gbt_frame_o:    signal is "true"; 
   --   attribute keep of  gbt_strobe_o:   signal is "true"; 
          
  --=======================================================================
  --==                 B E G I N                                         ==
  -- ======================================================================
   begin 
        get_trigger_proc: process (olt_txrx_usr_clk)
           begin 
              if (rising_edge(olt_txrx_usr_clk)) then 
                if reset_i = '1'   then 
                   olt_dff_1 <= '0'; 
                 
                 else 
                     olt_dff_1 <=  ctp_message_strobe_i;       -- Comment: Data arrived    in TTC-PON dedomain                
                end if; 
             end if; 
     end process; 
     
      --=========================================
      --==    Concurrent  Zone                 ==
      --========================================= 
      message_sync_gbt_s   <= ctp_message_i (119 downto 0)   when  rising_edge (olt_txrx_usr_clk); 
       -- =========================================================================
       -- ===                                                                   ===
       -- ===   gbt_frame    x  payload_1  x  payload_2  x  payload_3  x        ===
       -- ===                 ___           ___           ___                   ===
       -- ===   gbt_strobe __|   |_________|   |_________|   |__________        ===
       -- =========================================================================
      
       gbt_frame_o <= gbt_frame_s (gbt_frame_width -1 downto 0) when gbtbank_gbttx_ready_i = '1' else  (others => '0');  
       txIsDataSel_from_ctpemu_data_o <= gbt_frame_s (84) when gbtbank_gbttx_ready_i = '1' else  '0'; 

    -----------------------------------------------------
    --         Process in gbt domain                   --
    ------------------------------------------------------
    gbt_dom_proc: process (gbt_tx_clk_i) 
               begin 
                  if (rising_edge (gbt_tx_clk_i)) then 
                    if reset_i = '1' then 
                      gbt_frame_s  <= (others => '0');
                    else 
                       if (olt_dff_1 = '1') then 
                       gbt_frame_s  <= (message_sync_gbt_s(119) & gbt_SC_IC & gbt_SC_EC & message_sync_gbt_s (79 downto 0));
                       gbt_strobe_o <= '1';
                       else  
                          gbt_frame_s <= gbt_frame_s; 
                          gbt_strobe_o <= '0'; 
                       end if;  
                    end if; 
                  end if; 
           end process; 
 --===========================================================    
     
    end ctp_cd_gbt_beha;  