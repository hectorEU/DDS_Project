library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_mult is 
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
a             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
b             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
cp_out             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end mod_mult;

architecture modular_multiplier of mod_mult is

signal r             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal a_r             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

begin

-- Instantiation of MONTGOMERY block.
u_montgomery : entity work.montgomery
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	
    a     => a_r,
    b     => b,
    r         => r,
    key_n           => key_n
	);

--  . corresponding to the function: int mod_mult(int a, int b, int modulus, int c, int k)
-- k = C_BLOCK_SIZE
-- c = r2
-- cp_out is returned.

a_r <= a;
-- after computed. then do this. this cannot happen in parallel. TODO
a_r <= r;

cp_out <= a xor b;

end modular_multiplier;