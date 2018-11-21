library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

entity rl_binary_method is 
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
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
rsa_status              : out std_logic_vector(31 downto 0)
);
end rl_binary_method;

architecture rl_core of rl_binary_method is
signal c            : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal p            : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal i            : std_logic_vector(7 downto 0); -- counter

signal a_out,a_out2             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);
signal b_out, b_out2             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);

signal cp_in, cp_in2             : std_logic_vector(MONT_BLOCK_SIZE-1 downto 0);

signal Shreg    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal counter    : std_logic_vector(7 downto 0);
signal clk_counter    : std_logic_vector(7 downto 0);


TYPE State_type IS (LOAD_NEW_MESSAGE, ONE, TWO, THREE, FOUR, READY_SEND); -- the 4 different states
	SIGNAL State,State_next : State_Type;   -- Create a signal that uses 
	

signal clk_256, ready_modmult2, finito_modmult2, ready_modmult, finito_modmult, dbg, last:      std_logic := '0'; -- clock divided 256 times.
begin

--  . corresponding to the function: int RL_binary_method(int m, int e, int modulus, int r2, int k) where the return is msgout_data--
-- k=256 = C_BLOCK_SIZE
-- r2 read from register.
-- m = msgin_data
-- e = key__d

-- Instantiation of MODULAR MULTIPLIER block. THIS CLOCK MUST RUN A LOOOOT FASTER THAN THIS ONE. AT LEAST 256 clock cycles slower, probably more.
u_mod_mult : entity work.mod_mult
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
	ready_in => ready_modmult,
	ready_out => finito_modmult,
	reset_n => reset_n,
    a     => a_out,
    b     => b_out,
    cp_out         => cp_in,
    key_n           => key_n,
    k          => r2
	);

u_mod_mult2 : entity work.mod_mult
	generic map (
		C_BLOCK_SIZE        => C_BLOCK_SIZE
	)
	port map (
	clk => clk,
	ready_in => ready_modmult2,
	ready_out => finito_modmult2,
	reset_n => reset_n,
    a     => a_out2,
    b     => b_out2,
    cp_out         => cp_in2,
    key_n           => key_n,
    k          => r2
	);

process (clk, reset_n) begin


if (falling_edge(clk) and reset_n='1') then
    CASE State IS
--        WHEN RESET =>
--            rsa_status<= std_logic_vector(to_unsigned(1, 32));
--            msgout_valid <='0';
--            ready_modmult <= '0';
--            msgin_ready <= '0';
--            State_next <= LOAD_NEW_MESSAGE;
        WHEN LOAD_NEW_MESSAGE =>
             rsa_status<= std_logic_vector(to_unsigned(0, 32));
             msgin_ready <= '1';
             ready_modmult <= '0';
             ready_modmult2 <= '0';
             msgout_valid <= '0';
             last <= msgin_last;
             counter <= std_logic_vector(to_unsigned(0,8));
             Shreg <= key_e_d; -- load key
             c <= std_logic_vector(to_unsigned(1,MONT_BLOCK_SIZE)); -- c=1
             p <= (MONT_BLOCK_SIZE-1 downto msgin_data'length => '0') & msgin_data; -- p=m
             if (msgin_valid = '1') then
             State_next <=ONE;
             end if;    
        WHEN ONE =>
             rsa_status<= std_logic_vector(to_unsigned(1, 32));
             msgin_ready <= '0';
             a_out <= c;
             b_out <= p;       
             a_out2 <= p;  
             b_out2 <= p;        
             if finito_modmult = '1'  and finito_modmult2 = '1'  then -- we have to wait for this modmult to finish.
             State_next <= TWO;
             counter <= counter + 1;
             end if;
             
             ready_modmult <= not finito_modmult;
             ready_modmult2 <= not finito_modmult2;
             
        WHEN TWO =>
            rsa_status<= std_logic_vector(to_unsigned(1, 32));
            msgin_ready <= '0';
            
            ready_modmult <= '0';
            ready_modmult2 <= '0';
            Shreg <= '0' & Shreg(C_BLOCK_SIZE-1 downto 1);     -- shift e/d left to right]
            if (Shreg(0) = '1') then
                c<=cp_in;
            end if;
            p <= cp_in2;
            if (counter = 0) then
            State_next <= READY_SEND;
            else
            State_next <= ONE;
            end if;        
        WHEN THREE =>

        WHEN FOUR =>

        WHEN READY_SEND =>
            
            msgin_ready <= '0';
            msgout_data <= c(C_BLOCK_SIZE-1 downto 0);
            msgout_valid <= '1';
            msgout_last <= last;
            if last = '1' then
            rsa_status<= std_logic_vector(to_unsigned(0, 32));
            else
            rsa_status<= std_logic_vector(to_unsigned(0, 32));
            end if;
            if msgout_ready = '1' then
            State_next <= LOAD_NEW_MESSAGE;
            end if;
            
        WHEN others =>
            State <= LOAD_NEW_MESSAGE;
    end CASE;
end if;

    if (rising_edge(clk) and reset_n = '1') then
        State <= State_next;
    
    end if;
    
    if (reset_n = '0') then
        State <= LOAD_NEW_MESSAGE;
        msgin_ready <= '0';
        msgout_valid <= '0';
        msgout_last <= '0';
    end if;
    
end process;




end rl_core;