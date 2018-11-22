LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL; -- needed for the + operator
USE IEEE.STD_LOGIC_ARITH.ALL; -- and operators, etc

ENTITY rl_binary_method IS
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
		msgin_valid : IN std_logic;
		msgin_ready : OUT std_logic;
		msgout_ready : IN std_logic;
		msgout_valid : OUT std_logic;
		msgin_last : IN std_logic;
		msgout_last : OUT std_logic;
		reset_n : IN std_logic;
		msgin_data : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		msgout_data : OUT std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		key_e_d : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		key_n : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		r2 : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
		rsa_status : OUT std_logic_vector(31 DOWNTO 0)
	);
END rl_binary_method;

ARCHITECTURE rl_core OF rl_binary_method IS
	SIGNAL c : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
	SIGNAL p : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
	SIGNAL i : std_logic_vector(7 DOWNTO 0); -- counter

	SIGNAL a_out, a_out2 : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);
	SIGNAL b_out, b_out2 : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);

	SIGNAL cp_in, cp_in2 : std_logic_vector(MONT_BLOCK_SIZE - 1 DOWNTO 0);

	SIGNAL Shreg : std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);

	--signal counter : std_logic_vector(7 downto 0);
	TYPE State_type IS (LOAD_NEW_MESSAGE, ONE, TWO, THREE, FOUR, READY_SEND); -- the 4 different states
	SIGNAL State, State_next : State_Type; -- Create a signal that uses
 
	SIGNAL counter_rl, counter_lr, counter, msbfound : NATURAL;
	SIGNAL clk_256, ready_modmult2, finito_modmult2, ready_modmult, finito_modmult, dbg, last : std_logic := '0'; -- clock divided 256 times.
BEGIN
	-- . corresponding to the function: int RL_binary_method(int m, int e, int modulus, int r2, int k) where the return is msgout_data--
	-- k=256 = C_BLOCK_SIZE
	-- r2 read from register.
	-- m = msgin_data
	-- e = key__d

	-- Instantiation of MODULAR MULTIPLIER block. THIS CLOCK MUST RUN A LOOOOT FASTER THAN THIS ONE. AT LEAST 256 clock cycles slower, probably more.
	u_mod_mult : ENTITY work.mod_mult
			GENERIC MAP(
			C_BLOCK_SIZE => C_BLOCK_SIZE
			)
			PORT MAP(
				clk => clk, 
				ready_in => ready_modmult, 
				ready_out => finito_modmult, 
				reset_n => reset_n, 
				a => a_out, 
				b => b_out, 
				cp_out => cp_in, 
				key_n => key_n, 
				k => r2
			);

    u_mod_mult2 : ENTITY work.mod_mult
            GENERIC MAP(
            C_BLOCK_SIZE => C_BLOCK_SIZE
            )
            PORT MAP(
                clk => clk, 
                ready_in => ready_modmult2, 
                ready_out => finito_modmult2, 
                reset_n => reset_n, 
                a => a_out2, 
                b => b_out2, 
                cp_out => cp_in2, 
                key_n => key_n, 
                k => r2
            );

    PROCESS (clk, reset_n) BEGIN
                IF (falling_edge(clk) AND reset_n = '1') THEN
                    CASE State IS
                        -- WHEN RESET =>
                        -- rsa_status<= std_logic_vector(to_unsigned(1, 32));
                        -- msgout_valid <='0';
                        -- ready_modmult <= '0';
                        -- msgin_ready <= '0';
                        -- State_next <= LOAD_NEW_MESSAGE;
                        WHEN LOAD_NEW_MESSAGE => 
                            msbfound <= 0;
                            counter_lr <= 255;
                            counter_rl <= 0;
                            rsa_status <= std_logic_vector(to_unsigned(0, 32));
                            msgin_ready <= '1';
                            ready_modmult <= '0';
                            ready_modmult2 <= '0';
                            msgout_valid <= '0';
                            last <= msgin_last;
                            counter <= 0; --std_logic_vector(to_unsigned(0,8));
                            Shreg <= key_e_d; -- load key
                            c <= std_logic_vector(to_unsigned(1, MONT_BLOCK_SIZE)); -- c=1
                            p <= (MONT_BLOCK_SIZE - 1 DOWNTO msgin_data'LENGTH => '0') & msgin_data; -- p=m
                            IF (msgin_valid = '1') THEN
                                State_next <= ONE;
                            END IF; 
                        WHEN ONE => 
                            rsa_status <= std_logic_vector(to_unsigned(1, 32));
                            msgin_ready <= '0';
                            a_out <= c;
                            b_out <= p; 
                            a_out2 <= p; 
                            b_out2 <= p; 
                            IF finito_modmult = '1' AND finito_modmult2 = '1' THEN -- we have to wait for this modmult to finish.
                                --State_next <= TWO;
                                counter <= counter + 1;
    
    
                                counter_rl <= counter_rl + 1;
                                msgin_ready <= '0'; 
                                ready_modmult <= '0';
                                ready_modmult2 <= '0'; 
                                IF (Shreg(counter_rl) = '1') THEN
                                    c <= cp_in;
                                END IF;
                                p <= cp_in2;
                                IF (counter > counter_lr) THEN
                                    State_next <= READY_SEND;
                                ELSE
                                    State_next <= ONE;
                                END IF; 
    
                            END IF;
    
                            ready_modmult <= NOT finito_modmult;
                            ready_modmult2 <= NOT finito_modmult2;
    
                            IF (Shreg(counter_lr) = '0' AND msbfound = 0) THEN
                                counter_lr <= counter_lr - 1;
                            ELSE
                                msbfound <= 1;
                            END IF; 
    
                        WHEN READY_SEND => 
    
                            msgin_ready <= '0';
                            msgout_data <= c(C_BLOCK_SIZE - 1 DOWNTO 0);
                            msgout_valid <= '1';
                            msgout_last <= last;
                            IF last = '1' THEN
                                rsa_status <= std_logic_vector(to_unsigned(0, 32));
                            ELSE
                                rsa_status <= std_logic_vector(to_unsigned(0, 32));
                            END IF;
                            IF msgout_ready = '1' THEN
                                State_next <= LOAD_NEW_MESSAGE;
                            END IF;
    
                        WHEN OTHERS => 
                            State <= LOAD_NEW_MESSAGE;
                    END CASE;
                END IF;
    
                IF (rising_edge(clk) AND reset_n = '1') THEN
                    State <= State_next;
    
    
                END IF;
    
                IF (reset_n = '0') THEN
                    State <= LOAD_NEW_MESSAGE;
                    msgin_ready <= '0';
                    msgout_valid <= '0';
                    msgout_last <= '0';
    
                END IF;
    
    END PROCESS;
END rl_core;