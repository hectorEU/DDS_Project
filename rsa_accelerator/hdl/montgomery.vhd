LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL; -- needed for the + operator
--use IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

ENTITY montgomery IS
	GENERIC (
		-- Users to add parameters here
		C_BLOCK_SIZE : INTEGER := 256;
		MONT_BLOCK_SIZE : INTEGER := 512;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH : INTEGER := 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH : INTEGER := 8
	);
	PORT (
		clk : IN std_logic;
		ready_in : IN std_logic;
		ready_out : OUT std_logic;
		reset_n : IN std_logic;
		a : IN std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
		b : IN std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
		k : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		r : OUT std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
		key_n : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0)
	);
END montgomery;

ARCHITECTURE montgomery OF montgomery IS

	SIGNAL Shreg, b_buff : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
	SIGNAL counter : std_logic_vector(7 DOWNTO 0);
	SIGNAL r_current, r_last : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);

	TYPE State_type IS (INIT, ONE, TWO, THREE, FOUR, FIVE, READY_RETURN, READY_READ); -- the 4 different states
	SIGNAL State, State_next : State_Type; -- Create a signal that uses
 
	SIGNAL shifter_lr, lastRound : NATURAL;

BEGIN
	PROCESS (clk, reset_n)
	VARIABLE r_temp, r_temp2, r_temp3 : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
	BEGIN
		IF (reset_n = '0') THEN
			State <= INIT;
		ELSIF ((rising_edge(clk)) AND reset_n = '1') THEN
			CASE State IS
				WHEN INIT => 
					
					shifter_lr <= 0;
					ready_out <= '0';
					b_buff <= b;
					lastRound <= 0;
					counter <= std_logic_vector(to_unsigned(1, 8));
					Shreg <= a; -- load a.
					r_current <= std_logic_vector(to_unsigned(0, MONT_BLOCK_SIZE)); -- r = 0;
					IF (ready_in = '1') THEN
						State_next <= TWO;
					END IF;
				WHEN TWO => 
					ready_out <= '0';
 
					IF (Shreg(shifter_lr) = '1') THEN -- ((a >> i) & 1) * b;
						r_temp2 := r_last + b_buff;
					ELSE
						r_temp2 := r_last;
					END IF;
 
					counter <= counter + 1;
					shifter_lr <= shifter_lr + 1; 
 
					IF (r_temp2(0) = '0') THEN
						-- r_current <= r_last;
						r_temp := r_temp2;
					ELSE
 
						r_temp := r_temp2 + key_n;
 
					END IF;
					r_current <= '0' & r_temp(MONT_BLOCK_SIZE - 1 DOWNTO 1);
					r_temp3 := '0' & r_temp(MONT_BLOCK_SIZE - 1 DOWNTO 1);
 
 
					IF (counter = 0 AND lastRound = 1) THEN
						State_next <= READY_RETURN;
						ready_out <= '1';
						IF r_temp3 >= key_n THEN
							r <= r_temp3 - key_n; -- r mod n must be between 0 and n-1
						ELSE
							r <= r_temp3; -- return this. 
						END IF;
 
						IF (ready_in = '1') THEN
							State_next <= INIT;
						END IF; 

 
					ELSIF (counter = 0 AND lastRound = 0) THEN
						State_next <= TWO;
						shifter_lr <= 0;
                        counter <= std_logic_vector(to_unsigned(1, 8));
                        r_current <= std_logic_vector(to_unsigned(0, MONT_BLOCK_SIZE)); 
                        b_buff <= (MONT_BLOCK_SIZE-1 downto k'length => '0') & k; 
                        lastRound <= 1; 
                        						
						IF r_temp3 >= key_n THEN
							Shreg <= r_temp3 - key_n; -- r mod n must be between 0 and n-1
						ELSE
							Shreg <= r_temp3; 
						END IF; 
 

					ELSE
						State_next <= TWO;
 

					END IF;

				WHEN READY_RETURN => 
				    ready_out <= '1';
					IF (ready_in = '1') THEN
						State_next <= INIT;
					END IF;
 
				WHEN OTHERS => 
					State_next <= INIT;
			END CASE;
		END IF; 

		IF ((falling_edge(clk)) AND reset_n = '1') THEN
			-- if (ready_in = '0') then
			-- State <= INIT;
			-- ready_out <='0';
			-- else
			State <= State_next;
			r_last <= r_current;
 
			-- end if;
		END IF;

	END PROCESS;

END montgomery;