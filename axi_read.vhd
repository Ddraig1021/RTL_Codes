----------------------------------------------------------------------------------
-- COMPANY: 
-- ENGINEER: 
-- 
-- CREATE DATE: 18.03.2024 21:04:07
-- DESIGN NAME: 
-- MODULE NAME: AXI_READ - BEHAVIORAL
-- PROJECT NAME: 
-- TARGET DEVICES: 
-- TOOL VERSIONS: 
-- DESCRIPTION: 
-- 
-- DEPENDENCIES: 
-- 
-- REVISION:
-- REVISION 0.01 - FILE CREATED
-- ADDITIONAL COMMENTS:
-- 
----------------------------------------------------------------------------------

-- trigger to start ddr read and which half 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- UNCOMMENT THE FOLLOWING LIBRARY DECLARATION IF USING
-- ARITHMETIC FUNCTIONS WITH SIGNED OR UNSIGNED VALUES
USE IEEE.NUMERIC_STD.ALL;

-- UNCOMMENT THE FOLLOWING LIBRARY DECLARATION IF INSTANTIATING
-- ANY XILINX LEAF CELLS IN THIS CODE.
--LIBRARY UNISIM;
--USE UNISIM.VCOMPONENTS.ALL;

ENTITY AXI_READ IS
    GENERIC 
        (   rd_count_width      : integer := 32;
            fifo_data_width     : integer := 128;
            M_AXI_AWADDR_WIDTH  : INTEGER := 32;
            M_AXI_AWID_WIDTH    : INTEGER := 0;
            M_AXI_AWLEN_WIDTH   : INTEGER := 8;
            M_AXI_AWSIZE_WIDTH  : INTEGER := 3;
            M_AXI_AWBURST_WIDTH : INTEGER := 2;
            M_AXI_AWCACHE_WIDTH : INTEGER := 4;
            M_AXI_AWPROT_WIDTH  : INTEGER := 3;
            M_AXI_AWQOS_WIDTH   : INTEGER := 4;
            
            M_AXI_WDATA_WIDTH   : INTEGER := 64;
            M_AXI_WSTRB_WIDTH   : INTEGER := 8;--M_AXI_WDATA_WIDTH/8
            
            M_AXI_BID_WIDTH     : INTEGER := 0;
            M_AXI_BRESP_WIDTH   : INTEGER := 2;
            
            M_AXI_ARLEN_WIDTH   : INTEGER := 8;
            M_AXI_ARSIZE_WIDTH  : INTEGER := 3;
            M_AXI_ARBURST_WIDTH : INTEGER := 2;
            M_AXI_ARCACHE_WIDTH : INTEGER := 4;
            M_AXI_ARPROT_WIDTH  : INTEGER := 3;
            M_AXI_ARQOS_WIDTH   : INTEGER := 4;
            M_AXI_ARID_WIDTH    : INTEGER := 0;
            M_AXI_ARADDR_WIDTH  : INTEGER := 32;
            
            M_AXI_RID_WIDTH     : INTEGER := 0;
            M_AXI_RDATA_WIDTH   : INTEGER := 64;
            M_AXI_RRESP_WIDTH   : INTEGER := 2
        );
    PORT 
        (   bram_data_in : in std_logic;
       
            full : in std_logic;
            Read_count : in std_logic_Vector(rd_count_width-1 downto 0);
            rd_rst_busy : in std_logic;
            wr_rst_busy : in std_logic;
            
            resolution_in : in std_logic_vector(1 downto 0);
            res_change_detect : out std_logic;
            
            CLK   : IN STD_LOGIC;
            ARSTN : IN STD_LOGIC;
            
            DATA_OUT   : OUT STD_LOGIC_VECTOR(fifo_data_width-1 DOWNTO 0);
            DATA_VALID : OUT STD_LOGIC;
            
            slot_change : out std_logic;
            reset_stuck : out std_logic;

            M_AXI_AWID    : OUT STD_LOGIC_VECTOR(M_AXI_AWID_WIDTH   -1 DOWNTO 0); -- IDENTIFICATION TAG FOR WRITE ADDRESS GROUP
            M_AXI_AWADDR  : OUT STD_LOGIC_VECTOR(M_AXI_AWADDR_WIDTH -1 DOWNTO 0); -- WRITE ADDERSS
            M_AXI_AWLEN   : OUT STD_LOGIC_VECTOR(M_AXI_AWLEN_WIDTH  -1 DOWNTO 0); -- BURST LENGTH , NO. OF BURSTS/BEATS
            M_AXI_AWSIZE  : OUT STD_LOGIC_VECTOR(M_AXI_AWSIZE_WIDTH -1 DOWNTO 0); -- SIZE OF EACH BURST ,I.E., 4 BYTES
            M_AXI_AWBURST : OUT STD_LOGIC_VECTOR(M_AXI_AWBURST_WIDTH-1 DOWNTO 0); -- CORRESPONDS TO HOW ADDRESS FOR EACH DATA IS CALCULATED, INCREMENT BURST IS THIS CASE
            M_AXI_AWLOCK  : OUT STD_LOGIC;                                        -- '0', LOCKED TRANSACTION IS NOT SUPPORTED IN AXI4, TO ENSURE THAT THE MASTER CAN ACCESS THE TARGETED SLAVE ONLY
            M_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(M_AXI_AWCACHE_WIDTH-1 DOWNTO 0); -- INDICATES MEMORY TYPE 
            M_AXI_AWPROT  : OUT STD_LOGIC_VECTOR(M_AXI_AWPROT_WIDTH -1 DOWNTO 0); -- PRIVILAGE AND SECURITY LEVEL OF TRANSACTION 
            M_AXI_AWQOS   : OUT STD_LOGIC_VECTOR(M_AXI_AWQOS_WIDTH  -1 DOWNTO 0); -- QUALITY OF SERVICE IDENTIFIER, SHOULD BE USED TO INDICATE HIGHER PRIORITY DATA
            M_AXI_AWVALID : OUT STD_LOGIC;                                        -- VALIDITY OF DATA WITH READY HIGH
            M_AXI_AWREADY : IN  STD_LOGIC;                                          
            M_AXI_WDATA   : OUT STD_LOGIC_VECTOR(M_AXI_WDATA_WIDTH-1 DOWNTO 0);   -- WRITE DATA
            M_AXI_WSTRB   : OUT STD_LOGIC_VECTOR(M_AXI_WSTRB_WIDTH-1 DOWNTO 0);   -- WRITE DATA STROBE 
            M_AXI_WLAST	  : OUT STD_LOGIC;                                        -- LAST DATA OF BURST
            M_AXI_WVALID  : OUT STD_LOGIC;                                        -- 
            M_AXI_WREADY  : IN  STD_LOGIC;                                          
            M_AXI_BRESP   : IN  STD_LOGIC_VECTOR(M_AXI_BRESP_WIDTH-1 DOWNTO 0);   -- INDICATE WHETHER DATA RECEIVED IS OK  
            M_AXI_BID     : IN  STD_LOGIC_VECTOR(M_AXI_BID_WIDTH  -1 DOWNTO 0);   -- INDETIFIER FOR CORRESPONDING DATA
            M_AXI_BVALID  : IN  STD_LOGIC;                                        --
            M_AXI_BREADY  : OUT STD_LOGIC;                                           
            M_AXI_ARID    : OUT STD_LOGIC_VECTOR(M_AXI_ARID_WIDTH   -1 DOWNTO 0); --
            M_AXI_ARADDR  : OUT STD_LOGIC_VECTOR(M_AXI_ARADDR_WIDTH -1 DOWNTO 0); --
            M_AXI_ARLEN   : OUT STD_LOGIC_VECTOR(M_AXI_ARLEN_WIDTH  -1 DOWNTO 0); --
            M_AXI_ARSIZE  : OUT STD_LOGIC_VECTOR(M_AXI_ARSIZE_WIDTH -1 DOWNTO 0); --
            M_AXI_ARBURST : OUT STD_LOGIC_VECTOR(M_AXI_ARBURST_WIDTH-1 DOWNTO 0); --
            M_AXI_ARLOCK  : OUT STD_LOGIC;                                        --
            M_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(M_AXI_ARCACHE_WIDTH-1 DOWNTO 0); --
            M_AXI_ARPROT  : OUT STD_LOGIC_VECTOR(M_AXI_ARPROT_WIDTH -1 DOWNTO 0); --
            M_AXI_ARQOS   : OUT STD_LOGIC_VECTOR(M_AXI_ARQOS_WIDTH  -1 DOWNTO 0); --
            M_AXI_ARVALID : OUT STD_LOGIC;                                        --
            M_AXI_ARREADY : IN  STD_LOGIC;                                          
            M_AXI_RID     : IN  STD_LOGIC_VECTOR(M_AXI_RID_WIDTH  -1 DOWNTO 0);   --
            M_AXI_RDATA   : IN  STD_LOGIC_VECTOR(M_AXI_RDATA_WIDTH-1 DOWNTO 0);   --
            M_AXI_RRESP   : IN  STD_LOGIC_VECTOR(M_AXI_RRESP_WIDTH-1 DOWNTO 0);   --
            M_AXI_RLAST	  : IN  STD_LOGIC;                                        --
            M_AXI_RVALID  : IN  STD_LOGIC;                                        --
            M_AXI_RREADY  : OUT STD_LOGIC
        );
END AXI_READ;

ARCHITECTURE BEHAVIORAL OF AXI_READ IS

    CONSTANT TOTAL_BYTES_720  : INTEGER := 1843200*2;
    CONSTANT TOTAL_BYTES_1080 : INTEGER := 4147200*2;
    CONSTANT ADDR_OFFSET      : INTEGER := 2048;
--    constant base_addr       : std_logic_Vector(m_axi_awaddr'range) := X"00FD3080";
--    constant base_addr_slot2 : std_logic_Vector(m_axi_awaddr'range) := X"017BC880";
    constant base_addr       : std_logic_Vector(m_axi_awaddr'range) := X"00000080"; -- for internal loop only
    constant base_addr_slot2 : std_logic_Vector(m_axi_awaddr'range) := x"007E9880"; -- for internal loop only
    
    SIGNAL ADDR            : STD_LOGIC_VECTOR(M_AXI_ARADDR'RANGE):=(OTHERS=>'0');
    signal res_reg : std_logic_vector(1 downto 0);
    
    signal total_bytes : integer := 0;
    SIGNAL DEPTH       : INTEGER := 0;
    signal depth_slot2 : integer := 0;
    
    SIGNAL EN_REG           : STD_LOGIC := '0';
    SIGNAL EN_PULSE         : STD_LOGIC := '0';
    signal s_valid          : std_logic;
    signal read_en          : std_logic;
    signal bram_data_in_reg : std_logic:='0';
    signal res_pulse        : std_logic;
    signal fifo_rst         : std_logic;
    signal first_data       : std_logic;
    signal first_data_reg   : std_logic;
    signal first_data_pulse : std_logic;
    
    TYPE MACHINE IS (IDLE, AR, AR_WAIT, R, CHK);
    SIGNAL STATE : MACHINE := IDLE;
    
    type machine1 is (idle, addr_gen);
    signal state1 : machine1 := idle;
    
    ATTRIBUTE MARK_DEBUG : STRING;
    ATTRIBUTE MARK_DEBUG OF STATE, state1, DEPTH, total_bytes, DEPTH_SLOT2, ADDR, s_valid: SIGNAL IS "TRUE";
    
BEGIN

first_data <= '1' when(addr = base_addr or addr = base_addr_slot2) and state = r     else '0';
--last_data  <= '1' when(addr = depth-addr_offset or addr = depth_slot2 - addr_offset) else '0';

fifo_rst <= rd_rst_busy and wr_rst_busy;
reset_stuck <= fifo_rst;
process(clk)
begin
    if rising_edge(clk) then
        res_reg <= resolution_in;
        first_data_reg <= first_data;
    end if;
end process;

first_data_pulse <= first_data and (not first_data_reg);
res_pulse <= '1' when resolution_in /= res_reg else '0';
res_change_detect <= '1' when  (ARSTN = '0' or res_pulse = '1' or fifo_rst = '1') else '0';

process(clk) 
begin
    if rising_edge(clk) then
        case state1 is
            when idle =>
                if res_pulse = '1' then
                    state1 <= addr_gen;
                else
                    state1 <= idle;
                end if;
            when addr_gen =>
                if resolution_in = "10" or resolution_in = "11" then
                    total_bytes <= total_bytes_1080;
                elsif resolution_in = "01" then
                    total_bytes <= total_bytes_720;
                else
                    total_bytes <= total_bytes;
                end if;
        end case;
    end if;
end process;

DEPTH          <= TO_INTEGER(UNSIGNED(BASE_ADDR))       + 3686400;
depth_slot2    <= to_integer(unsigned(base_addr_slot2)) + 3686400; 

M_AXI_AWADDR  <= (others=>'0');
M_AXI_AWLEN   <= (others=>'0');
M_AXI_AWVALID <= '0';
M_AXI_AWID    <= (others=>'0');
M_AXI_AWSIZE  <= "100";
M_AXI_AWBURST <= "01";  
M_AXI_AWLOCK  <= '0';
M_AXI_AWCACHE <= x"3";
M_AXI_AWPROT  <= "000";
M_AXI_AWQOS   <= x"0";

M_AXI_WDATA   <= (OTHERS=>'0');
M_AXI_WSTRB   <= (OTHERS=>'0');
M_AXI_WVALID  <= '0';
M_AXI_WLAST   <= '0';

M_AXI_BREADY  <= '0';

M_AXI_ARLEN   <= x"7f";
M_AXI_ARID    <= (others=>'0');
M_AXI_ARSIZE  <= "100";	
M_AXI_ARBURST <= "01";
M_AXI_ARLOCK  <= '0';
M_AXI_ARCACHE <= x"3";
M_AXI_ARPROT  <= "000";	
M_AXI_ARQOS   <= x"0";

read_en <= '1' when read_count < 511 else '0';

PROCESS(CLK, ARSTN)
BEGIN
    IF ARSTN = '0' then--or res_pulse = '1' or fifo_rst = '1' THEN
        STATE         <= IDLE;
        M_AXI_ARADDR  <= (OTHERS=>'0');
        M_AXI_ARVALID <= '0';
        M_AXI_RREADY  <= '0';
        ADDR          <= BASE_ADDR;
        s_valid  <= '0';
        slot_change <= '0';
    ELSIF RISING_EDGE(CLK) THEN
        CASE STATE IS
            WHEN IDLE =>
                slot_change <= '0';
                IF read_en = '1' and full = '0' THEN
                    STATE <= AR;
                ELSE
                    STATE <= IDLE;
                END IF;
                
            WHEN AR =>
                slot_change <= '0';
                STATE <= AR_WAIT;
                M_AXI_ARVALID <= '1';
                M_AXI_ARADDR  <= ADDR;
                M_AXI_RREADY  <= '0';
            
            WHEN AR_WAIT =>
                slot_change <= '0';
                IF M_AXI_ARREADY = '1' THEN
                    M_AXI_ARVALID <= '0';
                    M_AXI_RREADY  <= '1';
                    s_valid  <= '1';
                    STATE <= R;
                END IF;
            WHEN R =>
                slot_change <= '0';
                IF M_AXI_RLAST = '1' and M_AXI_Rvalid = '1' THEN
                    STATE <= CHK;
                    M_AXI_RREADY <= '0';
                    s_valid  <= '0';
                    ADDR <= ADDR + ADDR_OFFSET;
                ELSE
                    STATE <= R;
                END IF;
                
            WHEN CHK =>
                IF ADDR = DEPTH or addr = depth_slot2 THEN
                    slot_change <= '1';
                    if bram_data_in = '1' and bram_data_in_reg = '1' then 
                        ADDR <= BASE_ADDR_slot2;
                        bram_data_in_reg <= '0';
                        STATE <= IDLE;
                    elsif bram_data_in ='0' and bram_data_in_reg = '0' then
                        ADDR <= BASE_ADDR;
                        STATE <= idle;
                        bram_data_in_reg <= '1';
                    else
                        addr <= addr;
                        state <= chk;
                    end if;
                ELSE
                    slot_change <= '0';
                    ADDR <= ADDR;
                    STATE <= IDLE;
                END IF;           
                  
            WHEN OTHERS =>
                STATE <= IDLE;
        END CASE;
    END IF;
END PROCESS;

DATA_OUT <= M_AXI_RDATA(127 downto 96) & m_axi_rdata(95 downto 64) &  m_axi_rdata(63 downto 32) &  m_axi_rdata(31 downto 0);--(126 DOWNTO 0) ;
DATA_VALID <= M_AXI_RVALID and s_valid;

END BEHAVIORAL;
