library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CRC_7 is
  generic(  
            gen_pol_val : std_logic_vector(4 downto 0):= "11001"; --generator binary
            data_len : integer := 9;                              -- data width 10 bits
            pol_len  : integer := 4                               -- generator polynomial length 5 bits
         );
  Port ( data_in       : in std_logic_vector (data_len downto 0);
         valid_in, clk : in std_logic;
         data_out      : out std_logic_vector(data_len + pol_len downto 0);
         valid_out     : out std_logic;
		 data_error    : out std_logic
       );
end CRC_7;

architecture Behavioral of CRC_7 is

signal gen_pol  : std_logic_vector  (pol_len downto 0)            := gen_pol_val(pol_len downto 0);
signal index    : integer    range   0 to data_len+pol_len        := data_len; -- counter used for temp indexing
signal temp     : std_logic_vector  (data_len + pol_len downto 0) := (others=>'0');
signal data_reg : std_logic_vector  (data_len downto 0)           := (others=>'0');
signal zeros    : std_logic_vector  (pol_len-1 downto 0)          :=(others=>'0');

type machine is (idle, check, exor, no_data, result);
signal state : machine:=idle;

begin

process(clk)
    begin
        if rising_edge(clk) then
           
            case state is
            
                when idle =>
					data_error <= '0';
                    index <= data_len+pol_len;
                    valid_out <= '0';
                    data_out <= (others=>'0');
                    if valid_in = '1' then
                        state <= check;
                        data_reg <= data_in;
                        temp <= data_in & (zeros);
                    else
                        state <= idle;
                         data_reg <= (others=>'0');
                        temp <= (others=>'0');
                    end if;
                
                when check =>
					data_error <= '0';
                    valid_out <= '0';
                    if temp(index) = '1' then
                        state <= exor;
                    else
						if index = 0 then
							state <= no_data;
						else
							state <= check;
							index <= index-1;
						end if;
                    end if;
                
                when exor =>	
					data_error <= '0';
                    valid_out <= '0';
                    temp(index downto index - pol_len) <= gen_pol xor temp(index downto index - pol_len);
                    if (index - (pol_len + 1)) = 0 then
                        state <= result;
                    else
                        state <= check;
                        index <= index - 1;
                    end if;
                    
                when result =>
					data_error <= '0';
                    valid_out <= '1';
                    data_out <= data_reg & temp(pol_len-1 downto 0);
                    state <= idle;
                
				when no_data =>
					state <= idle;
					data_error <= '1';
					
				
                when others=>
                    state <= idle;
                    
            end case;
            
        end if;
    end process;

end Behavioral;
