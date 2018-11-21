library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
--use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

entity montgomery is 
	generic (
    -- Users to add parameters here
    C_BLOCK_SIZE : integer := 256;
    MONT_BLOCK_SIZE : integer := 512;
    -- User parameters ends
    -- Do not modify the parameters beyond this line

    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH    : integer    := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH    : integer    := 8
);
port(
clk                    :  in std_logic;
ready_in                 :  in std_logic;
ready_out                 :  out std_logic; 
reset_n                   :  in std_logic;
a             : in std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
b             : in std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
r             : out std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end montgomery;

architecture montgomery of montgomery is


signal Shreg    : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal counter    : std_logic_vector(7 downto 0);
signal r_current,r_last,r_temp    : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);

TYPE State_type IS (INIT, ONE, TWO, THREE, FOUR, FIVE, READY_RETURN, READY_READ); -- the 4 different states
SIGNAL State,State_next: State_Type;   -- Create a signal that uses 
	
signal shifter_lr, msbfound :natural;
begin



process (clk, reset_n) begin
if (reset_n = '0') then
State <= INIT;
elsif ( (rising_edge(clk)) and reset_n='1') then
    CASE State IS
        WHEN INIT =>
            msbfound<=0;
            shifter_lr <= 0;
            ready_out <='0';
            counter <= std_logic_vector(to_unsigned(0,8));
            Shreg <= a; -- load a.
            r_current <= std_logic_vector(to_unsigned(0,MONT_BLOCK_SIZE)); -- r = 0;
            r_last <= std_logic_vector(to_unsigned(0,MONT_BLOCK_SIZE)); -- r = 0;
            r_temp <= std_logic_vector(to_unsigned(0,MONT_BLOCK_SIZE)); -- r = 0;
            if (ready_in = '1') then 
            State_next <= ONE;
            end if;
        WHEN ONE =>
            ready_out <='0';
            if (Shreg(shifter_lr) = '1') then -- ((a >> i) & 1) * b;
                r_current <= r_last + b;
            else
                r_current <= r_last;
            end if;

            
            counter <= counter + 1;
            shifter_lr <= shifter_lr +1;
            
        --    Shreg <= '0' & Shreg(MONT_BLOCK_SIZE-1 downto 1);     -- (a >> i
            
            State_next <= TWO;
       WHEN TWO =>
            ready_out <='0';
            if(r_last(0) = '0') then
                r_current <= '0' & r_last(MONT_BLOCK_SIZE-1 downto 1);     -- r = r >> 1;
                State_next <= FOUR;
            else
                r_temp <= r_last + key_n;
                r_current <= r_last;
                State_next <= THREE;
            end if;
      WHEN THREE =>
            ready_out <='0';
            r_current <=  '0' & r_temp(MONT_BLOCK_SIZE-1 downto 1); 
            if (counter = 0) then
                State_next <= READY_RETURN;
            else
                State_next <= ONE;
            end if;
            
     WHEN FOUR =>
            ready_out <='0';
            r_current <= r_last;
            if (counter = 0) then
                State_next <= READY_RETURN;
            else
                State_next <= ONE;
            end if;

    WHEN READY_RETURN =>
            ready_out <='1';
            if r_current >= key_n then
              r <= r_current - key_n; --  r mod n must be between 0 and n-1 
            else
               r <= r_current; -- return this.         
            end if;

            if (ready_in = '1') then 
            State_next <=INIT;
            end if;
    WHEN others =>
            State_next <= INIT;
    end CASE;
end if;    

if( (falling_edge(clk)) and reset_n='1') then
 --   if (ready_in = '0') then
--        State <= INIT;
 --       ready_out <='0';
 --   else
        State <= State_next;
        r_last <= r_current;
       
  --  end if;
end if;    
end process;




end montgomery;