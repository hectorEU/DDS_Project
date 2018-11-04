library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

entity rl_binary_method is 
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
msgin_ready                    :  in std_logic;
msgout_ready                    :  out std_logic;
reset_n                :  in std_logic;
msgin_data             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_e_d      : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end rl_binary_method;

architecture rl_core of rl_binary_method is
signal c_prev             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal c_new             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal cp_out           : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal p_prev             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal p_new             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal a_in             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal b_in             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);


signal serial_e_d : std_logic := '0';
signal dataReady : std_logic := '0';
signal internalClk : std_logic := '0';
signal Shreg    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal counter    : std_logic_vector(7 downto 0);
signal clk_counter    : std_logic_vector(7 downto 0);
signal clk_256 :      std_logic := '0'; -- clock divided 256 times.
begin

--  . corresponding to the function: int RL_binary_method(int m, int e, int modulus, int r2, int k) where the return is msgout_data--
-- k=256 = C_BLOCK_SIZE
-- r2 read from register.
-- m = msgin_data
-- e = key__d

-- Instantiation of MODULAR MULTIPLIER block. THIS CLOCK MUST RUN A LOOOOT FASTER THAN THIS ONE. AT LEAST 256 clock cycles slower, probably more.
u_mod_mult : entity work.mod_mult
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
    a     => a_in,
    b     => b_in,
    cp_out         => cp_out,
    key_n           => key_n,
    k          => r2
	);
	


-- wait for all data to be ready before reading registers.

process (msgin_ready) begin
if (falling_edge(msgin_ready)) then -- all data has been transferred.
    dataReady <= '1';
    c_new <= std_logic_vector(to_unsigned(1,C_BLOCK_SIZE)); -- intialize c=1.
    p_new <=msgin_data; -- p = m
end if;
if (rising_edge(msgin_ready)) then -- data is currently beeing transferred.
    dataReady <= '0';
end if;
end process;

 process (clk, reset_n) begin 
  -- clock divider. 
  if (rising_edge(clk)) then
  
        if (reset_n = '0') then
             clk_256 <= '1';
             clk_counter <= std_logic_vector(to_unsigned(0,8));
             counter <= std_logic_vector(to_unsigned(0,8));
         elsif (reset_n = '1') then
             clk_counter <= clk_counter + 1;
            if (clk_counter = 0) then
              clk_256 <= not clk_256;
            end if;
         end if;
   
   end if;
   ----
end process;
--msgout_data(255) <= clk_256;
msgout_data(255 downto 255-7) <= counter;
process (clk_256) begin
   if (rising_edge(clk_256) and reset_n='1') then
  Shreg <= '0' & Shreg(C_BLOCK_SIZE-1 downto 1);     -- shift it left to right
  if dataReady='1' then -- rising edge = new data
    Shreg <= msgin_data;              -- load it
  end if;
  
  c_prev <= c_new; -- c_new and p_new are updated on negedge clk, and should keep their value long enough to be readable on posedge clk (e.g. right here).
  p_prev <= p_new;
  
 
end if;

if (falling_edge(clk_256) and reset_n='1') then
     serial_e_d <= Shreg(0);
     if (serial_e_d = '1') then
         a_in <= c_prev;
         b_in <= p_prev;
         c_new <=cp_out;
     else
         c_new <= c_prev;
     end if;
     a_in <= p_prev;
     b_in <= p_prev;
     p_new <=cp_out;
     
     counter <= counter + '1';
     if (counter = 255) then
            
    --     msgout_data <= r2;--cp_out; -- should be ready after 256 clk cycles   
         msgout_ready <= '1';
         else
         
     end if;
     
end if;
end process;

end rl_core;

