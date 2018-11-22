library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
entity mod_mult is 
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
ready_in                    :  in std_logic;
ready_out                    :  out std_logic;
reset_n                    :  in std_logic;
a             : in std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
b             : in std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
cp_out             : out std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
k        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end mod_mult;

architecture modular_multiplier of mod_mult is


begin

-- Instantiation of MONTGOMERY blocks (can these run in parallel?.
u_montgomery1 : entity work.montgomery
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
	ready_in => ready_in,
	ready_out => ready_out,
	reset_n => reset_n,
    a     => a,
    b     => b,
    r         => cp_out,
    key_n           => key_n,
    k          => k
	);
	
--  . corresponding to the function: int mod_mult(int a, int b, int modulus, int c, int k)
-- k = C_BLOCK_SIZE
-- c = r2
-- cp_out is returned.

--cp_out <= k; --<= std_logic_vector(to_unsigned(123456789,256));


end modular_multiplier;