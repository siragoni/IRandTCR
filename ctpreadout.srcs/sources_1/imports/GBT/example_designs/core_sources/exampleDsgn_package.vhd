------------------------------------------------------- 
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @version 6.0
--! @brief GBT-FPGA IP - Common package
-------------------------------------------------------

-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Custom libraries and packages:
use work.gbt_bank_package.all;

package gbt_exampledesign_package is  

   --=============================== Constant Declarations ===============================--
   constant ENABLED								: integer := 1;                              --! Enable constant definition
   constant DISABLED							: integer := 0;                              --! Disable constant definition
   
   constant GATED_CLOCK			                : integer := 0;
   constant PLL					                : integer := 1;
	
   constant BC_CLOCK                            : integer := 0;
   constant FULL_MGTFREQ                        : integer := 1;    

   --================================= Configuration ================================-- 
   constant NUM_LINK_Conf                       : integer := 2;
   constant TX_OPTIMIZATION_Conf                : integer := LATENCY_OPTIMIZED;
   constant RX_OPTIMIZATION_Conf                : integer := STANDARD;
   constant TX_ENCODING_Conf                    : integer := GBT_DYNAMIC;
   constant RX_ENCODING_Conf                    : integer := GBT_DYNAMIC;
   constant DATA_GENERATOR_ENABLE_Conf          : integer := DISABLED;--ENABLED;   -- Comment Disabled by LPM  
   constant DATA_CHECKER_ENABLE_Conf            : integer := DISABLED;--ENABLED;   -- Comment Disabled by LPM
   constant MATCH_FLAG_ENABLE_Conf              : integer := ENABLED;
   constant CLOCKING_SCHEME_Conf                : integer := FULL_MGTFREQ;
	
   --=====================================================================================--   
end gbt_exampledesign_package;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--
