library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

entity montgomery is 
	generic (
    -- Users to add parameters here
    C_BLOCK_SIZE : integer := 256;

    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH    : integer    := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH    : integer    := 8
);
port(
clk                    :  in std_logic;
reset_n                    :  in std_logic;
a             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
b             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end montgomery;

architecture montgomery of montgomery is

signal Shreg    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal result    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal result_temp    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal counter    : std_logic_vector(7 downto 0);
signal result_temp2    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
begin


process (clk) begin

       
       if (rising_edge(clk)) then
       if (reset_n = '0') then
            result <= std_logic_vector(to_unsigned(0,C_BLOCK_SIZE));
            result_temp <= std_logic_vector(to_unsigned(0,C_BLOCK_SIZE));
            result_temp2  <= std_logic_vector(to_unsigned(0,C_BLOCK_SIZE));
            counter <= std_logic_vector(to_unsigned(0,8));
       end if;
   
            result <= result + result_temp;
       elsif (falling_edge(clk)) then
           --  r <= std_logic_vector(to_unsigned(0,C_BLOCK_SIZE));
           
             if (counter = 0) then -- rising edge = new data
                   Shreg <= a;              -- load next value.
               --  r <= result; -- send result out.
              else
                   Shreg <= '0' & Shreg(C_BLOCK_SIZE-1 downto 1);     -- shift it left to right
             end if;
             
             counter <= counter + '1'; 
             
           
           
           if (Shreg(0) ='0') then
                result_temp <= std_logic_vector(to_unsigned(0,C_BLOCK_SIZE));
           elsif (Shreg(0) ='1') then
                result_temp <= b;
            end if;
            -- r = r + r_temp moved to posedge.
            if ( result(0)  = '0') then
                result <= '0' & result(C_BLOCK_SIZE-1 downto 1);     -- shift it left to right
           else
                result_temp2 <= (result + key_n);
                result <= '0' & result_temp2(C_BLOCK_SIZE-1 downto 1);
                
           end if;
       end if;
       

end process;
       r(255 downto 255-7) <= counter; -- send result out.
       r(247) <= clk; -- send result out.
       r(246 downto 0) <= result(246 downto 0);

--  . corresponding to the function: int montgomery(int a, int b, int modulus, int k)
-- k = C_BLOCK_SIZE
-- r = montgomery (r, c, key_n, k)


--r <= std_logic_vector(to_unsigned(2468,256));

end montgomery;