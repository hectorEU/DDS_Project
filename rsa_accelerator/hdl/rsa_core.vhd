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
use ieee.std_logic_unsigned.all; -- needed for the + operator
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

type vectorC_BLOCK_SIZE is array (natural range <>) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
type vectorBit is array (natural range <>) of std_logic;
type vectorNatural is array (natural range <>) of natural;
signal message_in : vectorC_BLOCK_SIZE(7 downto 0);
signal message_out : vectorC_BLOCK_SIZE(7 downto 0);
signal valid_in, valid_out, ready_in, ready_out, last_in, last_out    : vectorBit(7 downto 0);



signal buissy_flag    : std_logic;
signal counter, counter_next, fifo_counter    : natural;
signal FIFO_pointer    : vectorNatural(7 downto 0);
begin



process(clk, reset_n) begin
if (reset_n = '0') then
counter <= 0;
elsif rising_edge(clk) then

-- TODO: distribute messages to seperate entities of  rl binary method. and make sure the asnwer is received in the right order.
end if;  
end process;



            valid_in(counter) <= msgin_valid;
            ready_out(counter) <= msgout_ready;
            last_in(counter) <= msgin_last;
            message_in(counter) <= msgin_data;
            
            msgout_data <= message_out(counter);
            msgout_last<= last_out(counter);
            msgin_ready <= ready_in(counter);
            msgout_valid <= valid_out(counter);




GEN_REG:
for i in 0 to 0 generate

REGX: entity work.rl_binary_method
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk            => clk,
	msgin_valid    =>valid_in(i),
	msgin_ready    => ready_in(i),
	msgout_ready    => ready_out(i),
	msgin_last    => last_in(i),
	msgout_last    => last_out(i),
	reset_n        => reset_n,
    msgin_data     => message_in(i),
  	msgout_valid    =>valid_out(i),  
    msgout_data     => message_out(i),
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
