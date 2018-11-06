----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2018 05:59:23 PM
-- Design Name: 
-- Module Name: rsa_core_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rsa_core_tb is
--  Port ( );
end rsa_core_tb;


architecture Behavioral of rsa_core_tb is

component rsa_core is
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
    ey_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    rsa_status              : out std_logic_vector(31 downto 0);
    user_defined_16_23              : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)      
          
  );
end component rsa_core;

signal finito, clk,msgin_valid, msgout_valid, msgout_ready, msgin_ready,reset_n, msgin_last:      std_logic := '0';
signal msgin_data, msgout_data, m_out,key_e_d,key_n,user_defined_16_23 : std_logic_vector(255 downto 0);

begin

DUT: entity work.rsa_core
port map (
clk => clk,
reset_n => reset_n,
msgin_valid => msgin_valid,
msgin_ready => msgin_ready,
msgout_valid => msgout_valid,
msgout_ready => msgout_ready,
msgout_data =>  msgout_data,
 msgin_data =>  msgin_data,
  msgin_last =>  msgin_last,
  key_e_d  => key_e_d ,
  key_n => key_n,
  user_defined_16_23 => user_defined_16_23
  

);

clk <= not clk after 1 ns;
    stimulus: process is
    begin
        finito <= '0'; -- just for the test to see if we finnished.
        
        reset_n <= '0'; wait for 1000 ns;
        reset_n <= '1'; wait for 60 ns;
        
        
        
       key_e_d <= std_logic_vector(to_unsigned(10,256));
       key_n <= std_logic_vector(to_unsigned(13,256));
       user_defined_16_23 <= std_logic_vector(to_unsigned(9,256));
       
        msgin_data <= std_logic_vector(to_unsigned(7,256)); -- the data to be encrypted/decrypted
        
        
        msgin_valid <= '1'; -- let our rsa machine know we have a valid message ready.  
        -- while this is 1, our rsa machine should start reading through our  meesage bit for bit. when this turns 0 it should pause.
        while (msgin_ready = '0') loop -- wait for our rsa machine to be ready to accept new message and start rading bit by bit.
           wait for 1 ns;
        end loop;
        --  waiting for the reading process to finnish.
        -- it should probably happen imidiatly.
        
          while (msgin_ready = '1') loop -- should turn to 0 when message is read.
            wait for 1 ns;
        end loop;
        msgin_valid <= '0'; -- message transmission complete. 
        --msgin_data<= std_logic_vector(to_unsigned(0,256)); 
        ----
        ----
        -- here is where the magic happens in our rsa machine...
        ----
        -----

        
        while (msgout_valid = '0') loop -- waiting for the encryption/decryption process to finnish.
            wait for 1 ns;
        end loop;
        msgout_ready <= '1'; -- we are ready to receive the encrypted/decrypted message.
        
        
        wait for 100 ns;
        
        msgout_ready <= '0'; -- reading process finnished.
        
        -- process has finnished now we can go to the next message.:
        
        finito <= '1'; -- test success.
        wait;
    end process stimulus;


end Behavioral;
