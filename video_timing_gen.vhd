library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

entity video_timing_gen is
    generic 
    (
        video_data_width : integer := 32
--        data_width : integer := 32
    );
    Port 
    (
        clk : in std_logic;
        rst : in std_logic;
        video_data_in : in std_logic_vector(video_data_width-1 downto 0);
        resolution_in : in std_logic_vector(1 downto 0);
        wr_rst_busy : in std_logic;
        rd_rst_busy : in std_logic;
        active_fifo_rd_en : out std_logic;
        
        hsync_out : out std_logic;
        vsync_out : out std_logic;
        active_out : out std_logic;
        field_out  : out std_logic;
        video_data_out : out std_logic_vector(60-1 downto 0)
    );
end video_timing_gen;

architecture Behavioral of video_timing_gen is

    type machine is (idle, measure, hsync, vsync);
    signal state : machine := idle;
    
    type res_enum is (res_720p60, res_1080p30, res_1080p60, not_defined);
    signal res : res_enum;
    
    signal video_data_reg : std_logic_Vector(60-1 downto 0);
    
    signal tlast_reg       : std_logic:='0';
    signal tuser_reg       : std_logic:='0';
    signal active_reg      : std_logic:='0';
    signal active_pulse    : std_logic:='0';
	signal res_change      : std_logic:='0';
	signal line_counter_en : std_logic:='0';
	signal s_vsync         : std_logic:='0';
	signal s_hsync         : std_logic:='0';
	signal s_hsync_reg     : std_logic:='0';
	signal s_vsync_reg     : std_logic:='0';
    signal temp            : std_logic:='0';
    signal temp2           : std_logic:='0';
    signal temp3           : std_logic:='0';
    signal vsync_trigger   : std_logic:='0';
    signal frame_end       : std_logic:='0';
    signal temp_trig       : std_logic:='0';
    signal temp_trig_reg   : std_logic:='0';
    signal temp_trig_pulse : std_logic:='0';
    signal st_rst          : std_logic:='0';
    signal s_fifo_rd_en    : std_logic:='0';
	
	signal active_counter      : std_logic_vector(32-1 downto 0):=(others=>'0');
	signal hsync_counter       : std_logic_vector(32-1 downto 0):=(others=>'0');
	signal active_count_value  : integer:=0;
	signal active_vcount_value : integer:=0;
	signal hsync_count_value   : integer:=0;
	signal line_count_value    : integer:=0;
	signal line_counter        : std_logic_vector(32-1 downto 0):=(others=>'0');
	signal resolution_reg      : std_logic_vector(32-1 downto 0):=(others=>'0');
	
	signal slice_y0 : std_logic_vector(7 downto 0);
	signal slice_u0 : std_logic_vector(7 downto 0);
	signal slice_y1 : std_logic_vector(7 downto 0);
	signal slice_v0 : std_logic_vector(7 downto 0);
    
    attribute mark_debug : string;
    attribute mark_debug of state, active_counter, line_counter, line_counter_en, s_hsync,s_vsync: signal is "true";
    
begin 
process(clk)
begin
    if rising_edge(clk) then
        hsync_out <= s_hsync;
        vsync_out <= s_vsync;
        field_out <= '0';--video_data_reg(60);
        video_data_out <= video_data_reg;
        active_out <= s_fifo_rd_en;
    end if;
end process; 
active_fifo_rd_en <= s_fifo_rd_en;
s_fifo_rd_en <= '1' when (state = measure and s_vsync = '0') else '0';
video_data_reg(59 downto 0) <= x"00000" & slice_v0 & "00" & slice_y1 & "00" & slice_u0 & "00" & slice_y0 & "00" when (state = measure and s_vsync = '0') else (others=>'0');

temp3       <= s_hsync or s_hsync_reg;
temp        <= '1' when (line_counter = (active_vcount_value-1) and (s_hsync = '1'or s_hsync_reg = '1')) else '0';
temp2       <= '1' when (line_counter = line_count_value-1 and (temp3 = '0')) else '0';
s_vsync     <= '1' when ((line_counter >= active_vcount_value or temp = '1') and (line_counter < line_count_value-1 or temp2 = '1')) else '0';

process(clk)
begin
    if rising_Edge(clk) then
        slice_y0       <= video_data_in(7 downto 0);
        slice_u0       <= video_data_in(15 downto 8);
        slice_y1       <= video_data_in(23 downto 16);
        slice_v0       <= video_data_in(31 downto 24);
        active_reg     <= video_data_in(video_data_width-1);
		resolution_reg(1 downto 0) <= resolution_in;
		s_hsync_reg    <= s_hsync;
		s_vsync_reg    <= s_vsync;
		temp_trig_reg  <= temp_trig;
    end if;
end process;

temp_trig_pulse <= not temp_trig and ( temp_trig_reg);
vsync_trigger   <= not s_vsync and ( s_vsync_reg);
res_change      <= '1' when resolution_reg /= resolution_in else '0';
active_pulse    <= video_data_in(video_data_width-1) and (not active_reg);

--pixles
active_count_value <= 1280 when resolution_in(1 downto 0) = "01" else --720 60
					  1920 when resolution_in(1 downto 0) = "10" else --1080 30
					  1920 when resolution_in(1 downto 0) = "11" else --1080 60
					  0;
					  
active_vcount_value <= 720  when resolution_in(1 downto 0) = "01" else --720 60
					   1080 when resolution_in(1 downto 0) = "10" else --1080 30
					   1080 when resolution_in(1 downto 0) = "11" else --1080 60
					   0;
--pixels
hsync_count_value <= 370 when resolution_in(1 downto 0) = "01" else --720 60
					 280 when resolution_in(1 downto 0) = "10" else --1080 30
					 280 when resolution_in(1 downto 0) = "11" else --1080 60
					 0;
--lines
line_count_value <= 30 + active_vcount_value when resolution_in(1 downto 0) = "01" else --720 60
					45 + active_vcount_value when resolution_in(1 downto 0) = "10" else --1080 30
				    45 + active_vcount_value when resolution_in(1 downto 0) = "11" else --1080 60
				    0;

res <= res_720p60  when resolution_in(1 downto 0) = "01" else
       res_1080p30 when resolution_in(1 downto 0) = "10" else
       res_1080p60 when resolution_in(1 downto 0) = "11" else
       not_defined;

st_rst <= '1' when (rst = '1' or res_change = '1' or wr_rst_busy = '1' or rd_rst_busy = '1') else '0';
   
process(clk)
begin
    if rising_Edge(Clk) then
        if rst ='1' then --or temp_trig_pulse = '1' then--or vsync_trigger = '1' then
            state           <= idle;
            line_counter_en <= '0';
            s_hsync         <= '0';
			active_counter  <= (others=>'0');
			hsync_counter   <= (others=>'0');
        else
            case state is
                when idle =>
					active_counter <= (others=>'0');
                    if rst = '0' then
                        state          <= measure;
                        active_counter <= active_counter + 1;
                    else
                        state <= idle;                     
                    end if; 
                when measure =>
                    line_counter_en <= '0';
                    if active_counter = active_count_value-1 then
						active_counter <= (others=>'0');
				        hsync_counter  <= hsync_counter + 1;
				        s_hsync        <= '1';
						state          <= hsync;
					else				   
                        s_hsync        <= '0';
						state          <= measure;
						active_counter <= active_counter + 1;
					end if;
				when hsync =>
				    if hsync_counter = hsync_count_value then
				        hsync_counter   <= (others=>'0');
						line_counter_en <= '1';
				        state           <= measure;
				        s_hsync         <= '0';
				    else
				        hsync_counter   <= hsync_counter + 1;
				        state           <= hsync;
				        s_hsync         <= '1';
						line_counter_en <= '0';
				    end if;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;

process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
			line_counter <= (others=>'0');
        else
            case res is
                when res_720p60 =>
					if line_counter_en = '1' then
						if line_counter = line_count_value-1 then
							line_counter <= (others=>'0');
						else
							line_counter <= line_counter + 1;
						end if;
					end if;
                when res_1080p30 =>
					if line_counter_en = '1' then
						if line_counter = line_count_value-1 then
							line_counter <= (others=>'0');
						else
							line_counter <= line_counter + 1;
						end if;
					end if;
                when res_1080p60 =>
					if line_counter_en = '1' then
						if line_counter = line_count_value-1 then
							line_counter <= (others=>'0');
						else
							line_counter <= line_counter + 1;
						end if;
					end if;
                when others =>
                    line_counter <= (others=>'0');
            end case;
        end if;
    end if;
end process;

process(clk)
begin
    if rising_Edge(clk) then
        if vsync_trigger = '1' then
            temp_trig <= '1';
        end if;
        if hsync_counter = hsync_count_value-1 then
            temp_trig <= '0';
        end if; 
    end if;
end process;

end Behavioral;





