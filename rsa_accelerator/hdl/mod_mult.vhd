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
clk                    :  in std_logic;
a             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
b             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
cp_out             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end mod_mult;

architecture modular_multiplier of mod_mult is

signal r_1             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal r_2             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal a_r             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

begin

-- Instantiation of MONTGOMERY blocks (can these run in parallel?.
u_montgomery1 : entity work.montgomery
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
    a     => a,
    b     => b,
    r         => r_1,
    key_n           => key_n
	);
	
u_montgomery2 : entity work.montgomery
        generic map (
            C_BLOCK_SIZE        => C_BLOCK_SIZE
        )
        port map (
        clk => clk,
        a     => r_1,
        b     => r2,
        r         => r_2,
        key_n           => key_n
        );
--  . corresponding to the function: int mod_mult(int a, int b, int modulus, int c, int k)
-- k = C_BLOCK_SIZE
-- c = r2
-- cp_out is returned.


cp_out <= r_2; -- return product from the modular multiplier. (but this is not ready until after 256 (local) clk cycles (if the two previous can run in parallel) or 512 if they cant.

end modular_multiplier;