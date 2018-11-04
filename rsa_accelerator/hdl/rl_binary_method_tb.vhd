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
end entity rl_binary_method_tb;

architecture Behavioral of rl_binary_method_tb is

component rl_binary_method is 
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
Port(
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
end component rl_binary_method;

signal m_in, m_out,e_d, n : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal clk,msgin_ready,msgout_ready,reset_n:      std_logic := '1';
signal r2: std_logic_vector(C_BLOCK_SIZE-1 downto 0);
begin
DUT: rl_binary_method
port map ( clk => clk, msgin_ready=>msgin_ready,msgout_ready=>msgout_ready,reset_n=>reset_n, msgin_data =>m_in, msgout_data => m_out, key_e_d =>e_d, key_n => n, r2=>r2);


clk <= not clk after 2ns;

    process begin

    
    m_in <= std_logic_vector(to_unsigned(1,C_BLOCK_SIZE));
    n <= std_logic_vector(to_unsigned(1,C_BLOCK_SIZE));
    wait;
    end process;

end architecture Behavioral;