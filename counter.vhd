library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity counter is
	port(clk : in std_logic);
end counter;

architecture rtl of counter is
	signal s_counter : std_logic_vector(3 downto 0);
begin

process(clk)
begin
	if rising_Edge(clk) then
		if s_counter = x"f" then
			s_counter <= x"0";
		else	
			s_counter <= s_counter + 1;
		end if;
	end if;
end process;

end rtl;