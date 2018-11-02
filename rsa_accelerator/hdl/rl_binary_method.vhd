library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
msgin_data             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_e_d      : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end rl_binary_method;

architecture rl_core of rl_binary_method is
signal c             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal cp             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal p             : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
begin
--  . corresponding to the function: int RL_binary_method(int m, int e, int modulus, int r2, int k) where the return is msgout_data--
-- k=256 = C_BLOCK_SIZE
-- r2 read from register.
-- m = msgin_data
-- e = key__d

-- Instantiation of MODULAR MULTIPLIER block.
u_mod_mult : entity work.mod_mult
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	
    a     => c,
    b     => p,
    cp_out         => cp,
    key_n           => key_n,
    r2          => r2
	);

-- msgout_data <= msgin_data xor key_n;
process begin
p <= msgin_data;
    for i in 0 to C_BLOCK_SIZE loop -- this cannot happen like this. must be performed sequentally i think..
        if key_e_d(i)='1' then
            c <= cp;      
        end if;
        p <= cp;
        
        
    end loop;
    msgout_data <= c;
end process;

end rl_core;