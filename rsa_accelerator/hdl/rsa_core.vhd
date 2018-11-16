--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018
-- Project      : RSA accelerator 
-- License      : This is free and unencumbered software released into the 
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose: 
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.,
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
    C_BLOCK_SIZE          : integer := 256
	);
  port (
    -----------------------------------------------------------------------------
    -- Clocks and reset
    -----------------------------------------------------------------------------      
    clk                    :  in std_logic;
    reset_n                :  in std_logic;
      
    -----------------------------------------------------------------------------
    -- Slave msgin interface
    -----------------------------------------------------------------------------
    -- Message that will be sent out is valid
    msgin_valid            : in std_logic;   
    -- Slave ready to accept a new message
    msgin_ready            : out std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgin_data             :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Indicates boundary of last packet
    msgin_last             :  in std_logic;
    
    -----------------------------------------------------------------------------
    -- Master msgout interface
    -----------------------------------------------------------------------------
    -- Message that will be sent out is valid
    msgout_valid            : out std_logic;   
    -- Slave ready to accept a new message
    msgout_ready            :  in std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Indicates boundary of last packet
    msgout_last             : out std_logic;

    -----------------------------------------------------------------------------
    -- Interface to the register block
    -----------------------------------------------------------------------------    
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    rsa_status              : out std_logic_vector(31 downto 0);
    user_defined_16_23              : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)      
          
  );
end rsa_core;

architecture rtl of rsa_core is

component REG is 
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
msgin_valid                    :  in std_logic;
msgin_ready                   :  out std_logic;
msgout_ready                   :  in std_logic;
msgout_valid                   :  out std_logic;
msgin_last                 :  in std_logic;
msgout_last                   :  out std_logic;
reset_n                :  in std_logic;
msgin_data             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_e_d      : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end component;

begin



GEN_REG:
for i in 0 to 0 generate

REGX: entity work.rl_binary_method
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk            => clk,
	msgin_valid    =>msgin_valid,
	msgin_ready    => msgin_ready,
	msgout_ready    => msgout_ready,
	msgin_last    => msgin_last,
	msgout_last    => msgout_last,
	reset_n        => reset_n,
    msgin_data     => msgin_data,
  	msgout_valid    =>msgout_valid,  
    msgout_data     => msgout_data,
    key_e_d         => key_e_d,
    key_n           => key_n,
    r2              => user_defined_16_23,
    rsa_status      => rsa_status
	);

end generate GEN_REG;

-- Instantiation of RL binary METHOD block.

	

  --msgout_valid <= msgin_valid;   
  
 -- msgin_ready  <= msgin_valid; -- just to let them know we are alive.
  
--  msgout_data  <= msgin_data xor key_n;

end rtl;
