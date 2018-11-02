library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rl_binary_method_tb is
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
end rl_binary_method_tb;

architecture Behavioral of rl_binary_method_tb is

component rl_binary_method
port(
msgin_data             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_e_d      : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end component;
signal m_in, m_out,e_d, n : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
begin
UUT: rl_binary_method port map (msgin_data =>m_in, msgout_data => m_out, key_e_d =>e_d, key_n => n);
    process begin
    
    m_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111";
    n <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010";
    wait;
    end process;

end Behavioral;