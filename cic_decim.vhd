-- cic_decim

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic_decim is
	generic(
		N_bit_in 		: natural := 32;
		N_bit_out 		: natural := 84; -- for 6 stage 116 bits for 8 stage 134 bits for 3 stage 90 bits
		N_sensors		: natural := 3
	);
	port(
		clk				: in std_logic;
		reset			: in std_logic;
		
		data_in			: in std_logic_vector (N_bit_in-1 downto 0);
		enable			: in std_logic;
		run				: in std_logic;
		in_sop			: in std_logic;
		in_eop			: in std_logic;
		
		data_out       	: out std_logic_vector(N_bit_out-1 downto 0);
		ready          	: out std_logic;
		out_sop			: out std_logic;
		out_eop			: out std_logic
		
	);
end cic_decim;	

architecture behavior of cic_decim is 

constant R_DECIM			: natural 	:= 200;
constant NUM_STAGE			: natural	:= 3;

type sensors_arr_type is array (0 to N_sensors-1) of signed (N_bit_out-1 downto 0);
-- type integ_type is array (0 to N_sensors*NUM_STAGE-1) of signed (N_bit_out-1 downto 0);
-- type comb_type is array (0 to N_sensors*NUM_STAGE+N_sensors-1) of signed (N_bit_out-1 downto 0);

signal cnt 				: natural range 0 to R_DECIM := 1; 
signal cnt_delay		: natural range 0 to NUM_STAGE-1 := 0; 
signal sensor_number	: natural range 0 to N_sensors-1 := 0;
signal channel_integ	: natural range 0 to N_sensors-1 := 0;
signal channel_comb		: natural range 0 to N_sensors-1 := 0;
signal channel_out		: natural range 0 to N_sensors-1 := 0;

signal integ			: std_logic	:= '0';
signal strob			: std_logic := '0';
signal comb				: std_logic	:= '0';
signal output			: std_logic	:= '0';
signal data_valid_sop	: std_logic := '0';
signal data_valid_eop	: std_logic := '0';

signal sensors_arr		: sensors_arr_type	:= (others => (others => '0'));
signal integrator0		: sensors_arr_type	:= (others => (others => '0'));
signal integrator1		: sensors_arr_type	:= (others => (others => '0'));
signal integrator2		: sensors_arr_type	:= (others => (others => '0'));
signal i2delay1			: sensors_arr_type	:= (others => (others => '0'));
signal i2delay2			: sensors_arr_type	:= (others => (others => '0'));
signal c1delay1			: sensors_arr_type	:= (others => (others => '0'));
signal c1delay2			: sensors_arr_type	:= (others => (others => '0'));
signal c2delay1			: sensors_arr_type	:= (others => (others => '0'));
signal c2delay2			: sensors_arr_type	:= (others => (others => '0'));
signal combin0			: sensors_arr_type	:= (others => (others => '0'));
signal combin1			: sensors_arr_type	:= (others => (others => '0'));
signal combin2			: sensors_arr_type	:= (others => (others => '0'));
signal combin3			: sensors_arr_type	:= (others => (others => '0'));

begin
	main:process(clk,reset)
	begin
		if reset = '1' then
			
			ready 				<= '0';
			out_sop 			<= '0';
			out_eop 			<= '0';

			integ				<= '0';
			strob	 			<= '0';
			comb				<= '0';
			output				<= '0';
			data_valid_sop		<= '0';
			data_valid_eop		<= '0';

			channel_integ		<=  0;
			cnt					<=  1;
			cnt_delay			<=  0;

			channel_comb		<=  0;
			channel_out			<=  0;
			sensor_number  		<=  0;

			sensors_arr			<= (others => (others => '0'));
			integrator0			<= (others => (others => '0'));
			integrator1			<= (others => (others => '0'));
			integrator2			<= (others => (others => '0'));
			i2delay1			<= (others => (others => '0'));
			i2delay2			<= (others => (others => '0'));
			c1delay2			<= (others => (others => '0'));
			c1delay2			<= (others => (others => '0'));
			c2delay2			<= (others => (others => '0'));
			c2delay2			<= (others => (others => '0'));
			combin0				<= (others => (others => '0'));
			combin1				<= (others => (others => '0'));
			combin2				<= (others => (others => '0'));
			combin3				<= (others => (others => '0'));
			data_out         	<= (others => '0');

		elsif (rising_edge(clk)) then
			
			if enable = '0' then
				ready 				<= run;
				data_out         	<= std_logic_vector(resize(signed(data_in), N_bit_out));
				sensor_number 		<=  0;
				channel_integ		<=  0;
				cnt					<=  1;
				cnt_delay			<=  0;
				channel_comb		<=  0;
				channel_out			<=  0;
				integ				<= '0';
				data_valid_sop		<= '0';
				data_valid_eop		<= '0';
				strob	 			<= '0';
				comb				<= '0';
				output				<= '0';
				out_sop				<= '0';
				out_eop				<= '0';
				sensors_arr			<= (others => (others => '0'));
				integrator0			<= (others => (others => '0'));
				integrator1			<= (others => (others => '0'));
				integrator2			<= (others => (others => '0'));
				i2delay1			<= (others => (others => '0'));
				i2delay2			<= (others => (others => '0'));
				c1delay2			<= (others => (others => '0'));
				c1delay2			<= (others => (others => '0'));
				c2delay2			<= (others => (others => '0'));
				c2delay2			<= (others => (others => '0'));
				combin0				<= (others => (others => '0'));
				combin1				<= (others => (others => '0'));
				combin2				<= (others => (others => '0'));
			else
				if run = '1' then
					if in_sop = '1' then
						data_valid_sop						<= '1';
						data_valid_eop						<= '0';
						sensor_number 						<= sensor_number + 1;
						sensors_arr(sensor_number) 			<= resize (signed (data_in), N_bit_out);	
					elsif in_eop = '1' then
						data_valid_eop						<= '1';
						sensor_number 						<= 0;
						sensors_arr(sensor_number) 			<= resize (signed (data_in), N_bit_out);
					else
						if data_valid_sop = '1' and (data_valid_eop = '0') then
							sensor_number 						<= sensor_number + 1;
							sensors_arr(sensor_number) 			<= resize (signed (data_in), N_bit_out);
						else
							sensor_number 						<= 0;
						end if;
					end if;
				else 
					sensor_number 						<= 0;
					data_valid_sop						<= '0';
					data_valid_eop						<= '0';
				end if;
				if (data_valid_sop = '1') and (data_valid_eop = '1') then
					integ								<= '1';
					data_valid_sop						<= '0';
					data_valid_eop						<= '0';
				end if;

				if integ = '1' then 
					integrator0(channel_integ) 			<= integrator0(channel_integ) + sensors_arr(channel_integ);
					integrator1(channel_integ)			<= integrator1(channel_integ) + integrator0(channel_integ);
					integrator2(channel_integ)			<= integrator2(channel_integ) + integrator1(channel_integ);
					if channel_integ = N_sensors-1 then				-- channel switch
						channel_integ 		<= 0;
						integ				<= '0';
						if cnt = R_DECIM-1 then
							cnt 				<= 0;
							strob				<= '0';
						elsif cnt = NUM_STAGE-1 then
							strob 				<= '1';
							cnt 				<= cnt + 1;
						else
							strob				<= '0';
							cnt 				<= cnt + 1;
						end if;
					else
						channel_integ 		<= channel_integ + 1;
					end if;	
					if strob = '1' then
						comb				<= '1';	
					end if;
				end if; 
				
				if comb = '1' then
					combin0(channel_comb)				<= integrator2(channel_comb);					--(N_bit_out-1 downto 1);
					i2delay1(channel_comb) 				<= combin0(channel_comb);						--(N_bit_out-1 downto 1);
					i2delay2(channel_comb) 				<= i2delay1(channel_comb);
					combin1(channel_comb)				<= combin0(channel_comb) - i2delay2(channel_comb);	--(N_bit_out-1 downto 1);
					c1delay1(channel_comb)				<= combin1(channel_comb);
					c1delay2(channel_comb)				<= c1delay1(channel_comb);
					combin2(channel_comb)				<= combin1(channel_comb) - c1delay2(channel_comb);
					c2delay1(channel_comb)				<= combin2(channel_comb);
					c2delay2(channel_comb)				<= c2delay1(channel_comb);
					combin3(channel_comb)				<= combin2(channel_comb) - c2delay2(channel_comb);
					if channel_comb = N_sensors-1 then				-- channel switch
						channel_comb 		<= 0;
						comb 				<= '0';
						if cnt_delay = NUM_STAGE-1 then
							output 					<= '1';
						else 
							cnt_delay 				<= cnt_delay + 1;
						end if;
					else
						channel_comb 		<= channel_comb + 1;
					end if;
				end if;
				
				if output = '1' then
					ready 					<= '1';
					data_out 				<= std_logic_vector(combin3(channel_out));
					if channel_out = 0 then
						out_sop  			<= '1';
						out_eop  			<= '0';
						channel_out 		<= channel_out + 1;
					elsif channel_out = N_sensors-1 then
						out_sop    			<= '0';
						out_eop    			<= '1';
						output 				<= '0';
						channel_out 		<= 0;
					else
						out_sop  			<= '0';
						out_eop  			<= '0';
						channel_out 		<= channel_out + 1;
					end if;
				else
					ready 					<= '0';
					out_sop    				<= '0';
					out_eop    				<= '0';
				end if;
			end if;
		end if;
	end process;
end behavior;