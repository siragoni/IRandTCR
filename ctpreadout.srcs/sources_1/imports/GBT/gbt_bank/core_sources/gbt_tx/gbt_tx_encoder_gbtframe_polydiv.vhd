-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @version 6.0
--! @brief GBT-FPGA IP - Reed Solomon polynomial dividor generator
-------------------------------------------------------
-- Description:            
--
-- Versions history:      DATE         VERSION   AUTHOR                DESCRIPTION
--                                                                   
--                        10/05/2006   0.1       A. Marchioro (CERN)   First .v module definition.           
--                                                                   
--                        03/10/2008   0.2       F. Marin (CPPM)       Translate from .v to .vhd.
--                                                                   
--                        18/11/2013   3.0       M. Barros Marin       - Cosmetic and minor modifications.                                                                   
--                                                                     - "gf16mult" and "gf16add" are functions instead of modules. 
--
--                        05/05/2016  4.0       LPM                  -- Change for Simulation:
-- Additional Comments:         
----------------------------------------------------------------------------------------------------                                                                   

--! IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Custom libraries and packages:
use work.gbt_bank_package.all;

--! @brief GBT_tx_encoder_gbtframe_polydiv - Reed Solomon Encoder
--! @details 
--! The GBT_tx_encoder_gbtframe_polydiv generates the polynomial divider used as the FEC.
entity gbt_tx_encoder_gbtframe_polydiv is
   port (
      DIVIDER_I                                 : in   std_logic_vector(59 downto 0);
      DIVISOR_I                                 : in   std_logic_vector(19 downto 0);
      QUOTIENT_O                                : out   std_logic_vector(43 downto 0);
      REMAINDER_O                               : out   std_logic_vector(15 downto 0)
      
   );
end gbt_tx_encoder_gbtframe_polydiv;

--! @brief GBT_tx_encoder_gbtframe_polydiv architecture - Tx datapath
--! @details The GBT_tx_encoder_gbtframe_polydiv architecture computes the polynomial divider
--! used by the decoder to correct error using DIVIDER_I, DIVISOR_I, quotient, remainder, gf16mult
--! and gf16add functions.
architecture behavioral of gbt_tx_encoder_gbtframe_polydiv is

   --================================ Signal Declarations ================================--
   
   signal divider                               : gbt_reg4_A(0 to 14);
   signal divisor                               : gbt_reg4_A(0 to 4);
   signal quotient                              : gbt_reg4_A(0 to 10);
   signal remainder                             : gbt_reg4_A(0 to 3);
   signal net                                   : gbt_reg4_A(0 to 88);

   --=====================================================================================--
   
--=================================================================================================--
begin                 --========####   Architecture Body   ####========-- 
--=================================================================================================--  
   
   --==================================== User Logic =====================================--
   
    combinatorial: process(DIVIDER_I, DIVISOR_I, divider, divisor, quotient, remainder, net)
   begin      
      
      --=============--
      -- Assignments --
      --=============--
      
      -- Divider:
      -----------
      
      for i in 0 to 14 loop
         divider(i)                             <= DIVIDER_I((4*i)+3 downto 4*i);
      end loop;
      
      -- Divisor:
      -----------
      
      for i in 0 to 4 loop
         divisor(i)                             <= DIVISOR_I((4*i)+3 downto 4*i);
      end loop;
      
      -- Quotient:
      ------------
      
      for i in 0 to 10 loop
         QUOTIENT_O((4*i)+3 downto 4*i)         <= quotient(i);
      end loop;
      
      -- Remainder:
      -------------
      
      for i in 0 to 3 loop
         REMAINDER_O((4*i)+3 downto 4*i)        <= remainder(i);
      end loop;
      
       --========--
      -- Stages --
      --========--
      
      -- Stage 1:
      -----------
      
      quotient(10) <= divider(14);
   
      net(1) <= gf16mult(divisor(3),divider(14));
      net(3) <= gf16mult(divisor(2),divider(14));
      net(5) <= gf16mult(divisor(1),divider(14));
      net(7) <= gf16mult(divisor(0),divider(14));
      
      --for i in 0 to 3 loop 
      --   net(1+(2*i))      <= gf16mult(divisor(3-i),divider(14));       
      --end loop;

      net(2) <= gf16add(net(1),divider(13));
      net(4) <= gf16add(net(3),divider(12));
      net(6) <= gf16add(net(5),divider(11));
      net(8) <= gf16add(net(7),divider(10));
      --for i in 0 to 3 loop 
      --   net(2+(2*i))      <= gf16add(net(1+(2*i)),divider(13-i));        
      --end loop;
   
      -- Stage 2:
      -----------
      
      quotient(9)  <= net(2);
      
      net(9) <= gf16mult(divisor(3),net(2));
      net(11) <= gf16mult(divisor(2),net(2));
      net(13) <= gf16mult(divisor(1),net(2));
      net(15) <= gf16mult(divisor(0),net(2));
      
      --for i in 0 to 3 loop 
      --   net(9+(2*i))      <= gf16mult(divisor(3-i),net(2));        
      --end loop;

      net(10) <= gf16add(net(9), net(4));
      net(12) <= gf16add(net(11),net(6));
      net(14) <= gf16add(net(13),net(8));
      
      --for i in 0 to 2 loop 
      --   net(10+(2*i))     <= gf16add(net(9+(2*i)),net(4+(2*i)));      
      --end loop;
   
      net(16)      <= gf16add(net(15),divider(9));      
      
      -- Stage 3:      
      -----------
      
      quotient(8)  <= net(10);

      net(17) <= gf16mult(divisor(3),net(10));
      net(19) <= gf16mult(divisor(2),net(10));
      net(21) <= gf16mult(divisor(1),net(10));
      net(23) <= gf16mult(divisor(0),net(10));
      
      --for i in 0 to 3 loop 
      --   net(17+(2*i))     <= gf16mult(divisor(3-i),net(10));         
      --end loop;

      net(18) <= gf16add(net(17),net(12));
      net(20) <= gf16add(net(19),net(14));
      net(22) <= gf16add(net(21),net(16));
      
      --for i in 0 to 2 loop 
      --   net(18+(2*i))     <= gf16add(net(17+(2*i)),net(12+(2*i)));         
      --end loop;
      
      net(24)      <= gf16add(net(23),divider(8));
      
      -- Stage 4:
      -----------
      
      quotient(7)  <= net(18);

      net(25) <= gf16mult(divisor(3),net(18));
      net(27) <= gf16mult(divisor(2),net(18));
      net(29) <= gf16mult(divisor(1),net(18));
      net(31) <= gf16mult(divisor(0),net(18));
      
      --for i in 0 to 3 loop 
      --   net(25+(2*i))     <= gf16mult(divisor(3-i),net(18));         
      --end loop;

      net(26) <= gf16add(net(25),net(20));
      net(28) <= gf16add(net(27),net(22));
      net(30) <= gf16add(net(29),net(24));
      
--    for i in 0 to 2 loop 
--       net(26+(2*i))     <= gf16add(net(25+(2*i)),net(20+(2*i)));        
--    end loop;
      
      net(32)      <= gf16add(net(31),divider(7));
   
      -- Stage 5:
      -----------
      
      quotient(6)  <= net(26);

      net(33) <= gf16mult(divisor(3),net(26));
      net(35) <= gf16mult(divisor(2),net(26));
      net(37) <= gf16mult(divisor(1),net(26));
      net(39) <= gf16mult(divisor(0),net(26));
      
--      for i in 0 to 3 loop 
--         net(33+(2*i))     <= gf16mult(divisor(3-i),net(26));         
--      end loop;

      net(34) <= gf16add(net(33),net(28));
      net(36) <= gf16add(net(35),net(30));
      net(38) <= gf16add(net(37),net(32));
      
--    for i in 0 to 2 loop 
--       net(34+(2*i))     <= gf16add(net(33+(2*i)),net(28+(2*i)));         
--    end loop;
      
      net(40)      <= gf16add(net(39),divider(6));        
   
      -- Stage 6:
      -----------
      
      quotient(5)  <= net(34);

      net(41) <= gf16mult(divisor(3),net(34));
      net(43) <= gf16mult(divisor(2),net(34));
      net(45) <= gf16mult(divisor(1),net(34));
      net(47) <= gf16mult(divisor(0),net(34));
      
--    for i in 0 to 3 loop 
--       net(41+(2*i))     <= gf16mult(divisor(3-i),net(34));         
--    end loop;

      net(42) <= gf16add(net(41),net(36));
      net(44) <= gf16add(net(43),net(38));
      net(46) <= gf16add(net(45),net(40));
    
--    for i in 0 to 2 loop 
--       net(42+(2*i))     <= gf16add(net(41+(2*i)),net(36+(2*i)));         
--    end loop;
      
      net(48)      <= gf16add(net(47),divider(5));
        
      -- Stage 7:
      -----------
      
      quotient(4)  <= net(42);

      net(49) <= gf16mult(divisor(3),net(42));
      net(51) <= gf16mult(divisor(2),net(42));
      net(53) <= gf16mult(divisor(1),net(42));
      net(55) <= gf16mult(divisor(0),net(42));
      
--    for i in 0 to 3 loop 
--       net(49+(2*i))     <= gf16mult(divisor(3-i),net(42));         
--    end loop;

      net(50) <= gf16add(net(49),net(44));
      net(52) <= gf16add(net(51),net(46));
      net(54) <= gf16add(net(53),net(48));
      
--    for i in 0 to 2 loop 
--       net(50+(2*i))     <= gf16add(net(49+(2*i)),net(44+(2*i)));        
--    end loop;
      
      net(56)      <= gf16add(net(55),divider(4));
         
      -- Stage 8:
      -----------
      
      quotient(3)  <= net(50);

      net(57) <= gf16mult(divisor(3),net(50));
      net(59) <= gf16mult(divisor(2),net(50));
      net(61) <= gf16mult(divisor(1),net(50));
      net(63) <= gf16mult(divisor(0),net(50));
      
--    for i in 0 to 3 loop 
--       net(57+(2*i))     <= gf16mult(divisor(3-i),net(50));         
--    end loop;

      net(58) <= gf16add(net(57),net(52));
      net(60) <= gf16add(net(59),net(54));
      net(62) <= gf16add(net(61),net(56));
      
--    for i in 0 to 2 loop 
--       net(58+(2*i))     <= gf16add(net(57+(2*i)),net(52+(2*i)));        
--    end loop;
      
      net(64)      <= gf16add(net(63),divider(3));         
      
      -- Stage 9: 
      -----------
      
      quotient(2)  <= net(58);

      net(65) <= gf16mult(divisor(3),net(58));
      net(67) <= gf16mult(divisor(2),net(58));
      net(69) <= gf16mult(divisor(1),net(58));
      net(71) <= gf16mult(divisor(0),net(58));
      
--    for i in 0 to 3 loop 
--       net(65+(2*i))     <= gf16mult(divisor(3-i),net(58));        
--    end loop;

      net(66) <= gf16add(net(65),net(60));
      net(68) <= gf16add(net(67),net(62));
      net(70) <= gf16add(net(69),net(64));
      
--    for i in 0 to 2 loop 
--       net(66+(2*i))     <= gf16add(net(65+(2*i)),net(60+(2*i)));         
--    end loop;
      
      net(72)      <= gf16add(net(71),divider(2));
         
      -- Stage 10:
      ------------
      
      quotient(1)  <= net(66);

      net(73) <= gf16mult(divisor(3),net(66));
      net(75) <= gf16mult(divisor(2),net(66));
      net(77) <= gf16mult(divisor(1),net(66));
      net(79) <= gf16mult(divisor(0),net(66));
      
--    for i in 0 to 3 loop 
--       net(73+(2*i))     <= gf16mult(divisor(3-i),net(66));        
--    end loop;

      net(74) <= gf16add(net(73),net(68));
      net(76) <= gf16add(net(75),net(70));
      net(78) <= gf16add(net(77),net(72));
      
--    for i in 0 to 2 loop 
--       net(74+(2*i))     <= gf16add(net(73+(2*i)),net(68+(2*i)));         
--    end loop;
      
      net(80)      <= gf16add(net(79),divider(1));
      
      -- Stage 11:
      ------------
      
      quotient(0)  <= net(74);

      net(81) <= gf16mult(divisor(3),net(74));
      net(83) <= gf16mult(divisor(2),net(74));
      net(85) <= gf16mult(divisor(1),net(74));
      net(87) <= gf16mult(divisor(0),net(74));
      
--    for i in 0 to 3 loop 
--       net(81+(2*i))     <= gf16mult(divisor(3-i),net(74));
--    end loop;

      net(82) <= gf16add(net(81),net(76));
      net(84) <= gf16add(net(83),net(78));
      net(86) <= gf16add(net(85),net(80));
      
--    for i in 0 to 2 loop 
--       net(82+(2*i))     <= gf16add(net(81+(2*i)),net(76+(2*i)));         
--    end loop;
      
      net(88)      <= gf16add(net(87),divider(0));         

      remainder(0)      <= net(88);
      remainder(1)      <= net(86);
      remainder(2)      <= net(84);
      remainder(3)      <= net(82);
--    for i in 0 to 3 loop
--       remainder(i)      <= net(88-(2*i));
--    end loop;
   
   end process;   
   
   --=====================================================================================--     
end behavioral;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--