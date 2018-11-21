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

signal counter    : std_logic_vector(3 downto 0);
signal r_1             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal k_long             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal output             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal ready_out_s, ready_flag, ready_in_delayed:      std_logic := '0';
begin

-- Instantiation of MONTGOMERY blocks (can these run in parallel?.
u_montgomery1 : entity work.montgomery
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
	ready_in => ready_in,
	ready_out => ready_out_s,
	reset_n => reset_n,
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
        ready_in => ready_out_s,
        ready_out => ready_out,
        reset_n => reset_n,
        a     => r_1,
        b     => k_long,
        r         => output,
        key_n           => key_n
        );
--  . corresponding to the function: int mod_mult(int a, int b, int modulus, int c, int k)
-- k = C_BLOCK_SIZE
-- c = r2
-- cp_out is returned.

--cp_out <= k; --<= std_logic_vector(to_unsigned(123456789,256));

k_long <= (MONT_BLOCK_SIZE-1 downto k'length => '0') & k;
cp_out <= output; --output; -- return product from the modular multiplier. (but this is not ready until after 256 (local) clk cycles (if the two previous can run in parallel) or 512 if they cant.



end modular_multiplier;