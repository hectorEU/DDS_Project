library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; -- needed for the + operator
use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

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
clk                    :  in std_logic;
msgin_valid                    :  in std_logic;
msgin_ready                   :  out std_logic;
msgout_valid                   :  out std_logic;
reset_n                :  in std_logic;
msgin_data             : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_e_d      : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
key_n        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
r2        : in std_logic_vector(C_BLOCK_SIZE-1 downto 0)
);
end rl_binary_method;

architecture rl_core of rl_binary_method is
signal c            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal p            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal i            : std_logic_vector(7 downto 0); -- counter

signal a_out            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
signal b_out            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal cp_in            : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal Shreg    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

signal counter    : std_logic_vector(7 downto 0);
signal clk_counter    : std_logic_vector(7 downto 0);


TYPE State_type IS (RESET, LOAD_NEW_MESSAGE, ONE, TWO, THREE, FOUR, READY_SEND, READY_READ); -- the 4 different states
	SIGNAL State,State_next : State_Type;   -- Create a signal that uses 
	

signal clk_256:      std_logic := '0'; -- clock divided 256 times.
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
	reset_n => reset_n,
    a     => a_out,
    b     => b_out,
    cp_out         => cp_in,
    key_n           => key_n,
    k          => r2
	);
	

process (clk_256) begin

if (falling_edge(clk_256) and reset_n='1') then
    CASE State IS
        WHEN RESET =>
            msgin_ready <= '0';
            if msgin_valid = '1' then
            State_next <= READY_READ;
            end if;
        WHEN READY_READ =>
            msgin_ready <= '1';
            if (msgin_valid = '1') then
                State_next <= LOAD_NEW_MESSAGE;
            end if;    
        WHEN LOAD_NEW_MESSAGE =>
             msgout_valid <= '0';
             counter <= std_logic_vector(to_unsigned(0,8));
             Shreg <= msgin_data; -- load message.
             c <= std_logic_vector(to_unsigned(1,256)); -- c=1
             p <= msgin_data; -- p=m
             State_next <=ONE;
        WHEN ONE =>
             msgin_ready <= '0';
             a_out <= c;
             b_out <= p;             
             counter <= counter + 1;
             State_next <= TWO;
             
        WHEN TWO =>
            Shreg <= '0' & Shreg(C_BLOCK_SIZE-1 downto 1);     -- shift message left to right]
            if (Shreg(0) = '1') then
                c<=cp_in;
            end if;
            State_next <= THREE;          
        WHEN THREE =>
            a_out <= p;
            b_out <= p;
            State_next <= FOUR;
        WHEN FOUR =>
            p <= cp_in;
            if (counter = 0) then
            State_next <= READY_SEND;
            else
            State_next <= ONE;
            end if;
        WHEN READY_SEND =>
            msgout_data <= c;
            msgout_valid <= '1';
            State_next <= RESET;
            
        WHEN others =>
            State_next <= RESET;
    end CASE;
end if;

    if (rising_edge(clk_256)) then
    
    if (reset_n = '0') then
       State <=RESET;
    else
       State <= State_next;
    end if;
    end if;
end process;


-- clock divider.
process (clk) begin
if (falling_edge(clk)) then
    if (reset_n = '0') then
        clk_256 <= '0';
        clk_counter <= std_logic_vector(to_unsigned(0,8));

    end if;
    if (rising_edge(clk)) then
        clk_counter <=clk_counter + 1;
    end if;
    if (clk_counter <= 0) then -- cuz it overflows at 256.
        clk_256 <= not clk_256;
    end if;
end if;
end process;



end rl_core;

