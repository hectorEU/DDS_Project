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
use ieee.math_real.all;

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

signal finito, clk, msgin_valid, msgout_valid, msgout_ready, msgin_ready,reset_n, msgin_last, msgout_last:      std_logic := '0';
signal msgin_data, msgout_data, m_out,key_e_d,key_n,user_defined_16_23 : std_logic_vector(255 downto 0);



function str_to_stdvec(inp: string) return std_logic_vector is
    variable temp: std_logic_vector(4*inp'length-1 downto 0) := (others => 'X');
    variable temp1 : std_logic_vector(3 downto 0);
  begin 
    for i in inp'range loop
      case inp(i) is 
         when '0' => 
           temp1 := x"0";
         when '1' => 
           temp1 := x"1";         
         when '2' => 
           temp1 := x"2";         
         when '3' => 
           temp1 := x"3";         
         when '4' => 
           temp1 := x"4";                    
         when '5' => 
           temp1 := x"5";         
         when '6' => 
           temp1 := x"6";         
         when '7' => 
           temp1 := x"7";         
         when '8' => 
           temp1 := x"8";         
         when '9' => 
           temp1 := x"9";         
         when 'A'|'a' => 
           temp1 := x"a";         
         when 'B'|'b' => 
           temp1 := x"b";         
         when 'C'|'c' => 
           temp1 := x"c";         
         when 'D'|'d' => 
           temp1 := x"d";         
         when 'E'|'e' => 
           temp1 := x"e";         
         when 'F'|'f' => 
           temp1 := x"f";         
         when others =>
           temp1 := "XXXX";                  
      end case;
      temp(4*(i-1)+3 downto 4*(i-1)) := temp1;                                         
    end loop;
    return temp;
  end function str_to_stdvec;  



begin

DUT: entity work.rsa_core
port map (
clk => clk,
reset_n => reset_n,
msgin_valid => msgin_valid,
msgin_ready => msgin_ready,
msgout_last => msgout_last,
msgout_valid => msgout_valid,
msgout_ready => msgout_ready,
msgout_data =>  msgout_data,
 msgin_data =>  msgin_data,
  msgin_last =>  msgin_last,
  key_e_d  => key_e_d ,
  key_n => key_n,
  user_defined_16_23 => user_defined_16_23
  

);

clk <= not clk after 40 ns;
    stimulus: process is
    begin
        finito <= '0'; -- just for the test to see if we finnished.
        
        reset_n <= '0'; wait for 1000 ns;
        reset_n <= '1'; wait for 60 ns;
        
        msgout_ready <= '1'; -- we are allways ready to receive data from rsa_core. (rsa core is a lot slower than us!)
        
        key_e_d <= str_to_stdvec("5000000000000000000000000000000000000000000000000000000000000000");--std_logic_vector(to_unsigned(5,256));
               key_n <= str_to_stdvec("7700000000000000000000000000000000000000000000000000000000000000"); --std_logic_vector(to_unsigned(119,256));
               user_defined_16_23 <= str_to_stdvec("2100000000000000000000000000000000000000000000000000000000000000"); --std_logic_vector(to_unsigned(18,256));
               
                msgin_data <= str_to_stdvec("3100000000000000000000000000000000000000000000000000000000000000");--std_logic_vector(to_unsigned(19,256)); -- the data to be encrypted/decrypted
        msgin_valid <= '1'; -- let our rsa machine know we have a valid message ready.  
        -- while this is 1, our rsa machine should start reading through our  meesage bit for bit. when this turns 0 it should pause.
        while (msgin_ready = '0') loop -- wait for our rsa machine to be ready to accept new message
           wait for 20 ns;
        end loop;
        --  waiting for the reading process to finnish.
        -- it should probably happen imidiatly.
        
        
          while (msgin_ready = '1') loop -- should turn to 0 when message is read.
            wait for 20 ns;
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
        
        
        
        msgout_ready <= '0'; -- reading process finnished.
        
        -- process has finnished now we can go to the next message.:
        
        
        
        
        
        
        
        
        
        key_e_d <= std_logic_vector(to_unsigned(77,256));
               key_n <= std_logic_vector(to_unsigned(119,256));
               user_defined_16_23 <= std_logic_vector(to_unsigned(18,256));
               
                msgin_data <= std_logic_vector(to_unsigned(66,256)); -- the data to be encrypted/decrypted
                
                
                msgin_valid <= '1'; -- let our rsa machine know we have a valid message ready.  
                msgin_last <= '1'; -- let our rsa machine know that this is the last message 
                
                -- while this is 1, our rsa machine should start reading through our  meesage bit for bit. when this turns 0 it should pause.
                while (msgin_ready = '0') loop -- wait for our rsa machine to be ready to accept new message and start rading bit by bit.
                   wait for 1 ns;
                end loop;
                --  waiting for the reading process to finnish.
                -- it should probably happen imidiatly.
                
                  while (msgin_ready = '1') loop -- should turn to 0 when message is read.
                    wait for 1 ns;
                end loop;
                msgin_last <= '0';
                msgin_valid <= '0'; -- message transmission complete. 
                --msgin_data<= std_logic_vector(to_unsigned(0,256)); 
                ----
                ----
                -- here is where the magic happens in our rsa machine...
                ----
                -----
        
                
                while (msgout_valid = '0' and msgout_last = '0') loop -- waiting for the encryption/decryption process to finnish.
                    wait for 1 ns;
                end loop;
                msgout_ready <= '1'; -- we are ready to receive the encrypted/decrypted message.
                 wait for 100 ns;
                msgout_ready <= '0'; -- reading process finnished.
               
                
        
        
        
        
        
        
        
        
        
        
        
        
        finito <= '1'; -- test success.
        wait;
    end process stimulus;


end Behavioral;
