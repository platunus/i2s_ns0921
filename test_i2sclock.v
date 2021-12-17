/************************************************************************************************************
 TEST BENCH FOR I2C to GPIO Port expander. Date: December 23, 2006.
 *********************************************************************************************************** */
 `timescale 1us/10ns
  
module test_i2sclock;
 
 // registers and wires
 reg mclk;
 wire bck;
 wire lrck;
 wire oscillator_22;
 wire oscillator_24;

 reg sclk;
 
 reg start_t;
 reg sda_in;
 reg ack_check;
 reg GPIO_input_check;
 reg read_oper_check;
 reg write_oper_check;
 reg slave_add_check;
 
 wand sda;
 wire [3:0] count;
 
// Linking module under test 
i2sclock test ( mclk, bck, lrck, oscillator_22, oscillator_24, sda, sclk);

reg[7:0] GPIO_input_store;      //Stores the data from GPIO input line which master wants to read
reg[7:0] GPIO_output_send;      //Stores the data which master wants to write at GPIO output line
reg[6:0] slave_add_compare;     //For random slave address

integer i = 0;
integer r_seed;                 // Seed ensures that the same random sequence is generated during every simulation
parameter	tdelay	= 3.5 ;
parameter testcycle = 100.0;

assign sda = sda_in;

initial
begin
$dumpfile("test_I2C_to_GPIO.dmp");
$dumpvars;
end

initial                         // Generates serial clock of time period 10
begin
  sclk = 0;
  forever #5 sclk = !sclk;
end
  
initial
begin
  mclk = 0;
  forever #1 mclk = !mclk;
end
  
initial
   r_seed =2;                   // Arbitrarily define the seed as 2
   
 always @(posedge sclk)         // Test that slave acknowledges only the correct address
  begin
  
      if (slave_add_check & (slave_add_compare != 0000000) & ~sda) begin
          $display("PASS: I2C address check successful   ", $time);
      end else if (slave_add_check) begin
          $display(" Slave acknowledging wrong address at time %d", $time);
      end
      if (sda & ack_check) begin 
          $display(" Acknowledge Fail at time %d", $time); 
      end else if (ack_check) begin
          $display("Acknowledge recieved correctly %d", $time);
      end 
		/*
      if (write_oper_check & (GPIO_output == GPIO_output_send)) begin
          $display ("PASS: I2C Write successful ", $time);
      end else if (write_oper_check) begin
          $display ("Write Failed !" , $time);
      end
      if (read_oper_check & (GPIO_input == GPIO_input_store)) begin
          $display ("PASS: I2C Read successful ", $time);
      end else if (read_oper_check) begin
          $display ("I2C Read Failed !" , $time);
      end
		*/
    
  end
  
initial 
begin
@(negedge sclk)    
$display("Testing for randoms values");
#500 ;
#tdelay sda_in = 1; 
#tdelay sda_in = 0;  // For start
// Generate random slave address
slave_add_compare = $random(r_seed);
//slave_add_compare = $random(r_seed);
slave_add_compare = 7'h41;
#tdelay   sda_in <= slave_add_compare[6];
#10       sda_in <= slave_add_compare[5];
#10       sda_in <= slave_add_compare[4];
#10       sda_in <= slave_add_compare[3];
#10       sda_in <= slave_add_compare[2];
#10       sda_in <= slave_add_compare[1];
#10       sda_in <= slave_add_compare[0];
#10       sda_in <=1;          //For read operation
#10 slave_add_check <= 1; 
#10 slave_add_check <= 0; 


# testcycle
@ (negedge sclk)              //For repeat start
$display ("Starting a write operation", $time); 
#tdelay sda_in = 1;
#tdelay sda_in = 0;
#tdelay   sda_in <= slave_add_compare[6];
#10       sda_in <= slave_add_compare[5];
#10       sda_in <= slave_add_compare[4];
#10       sda_in <= slave_add_compare[3];
#10       sda_in <= slave_add_compare[2];
#10       sda_in <= slave_add_compare[1];
#10       sda_in <= slave_add_compare[0];
#10 sda_in = 0;               // For write operation
#10 sda_in = 1;
    ack_check <=1; 
    
 //For storing a random data which master writes on GPIO output
//    GPIO_output_send <= $random(r_seed); 
    GPIO_output_send <= 8'b00000011; 

#10 ack_check <= 0;
    sda_in <= GPIO_output_send[7];
#10 sda_in <= GPIO_output_send[6];
#10 sda_in <= GPIO_output_send[5];
#10 sda_in <= GPIO_output_send[4];
#10 sda_in <= GPIO_output_send[3];
#10 sda_in <= GPIO_output_send[2];
#10 sda_in <= GPIO_output_send[1];
#10 sda_in <= GPIO_output_send[0];
# 10 sda_in <= 1;
     write_oper_check <= 1;
# 10 write_oper_check <=0 ;


# testcycle
$display("starting a read operation", $time);
@ (negedge sclk)              //For repeat start
#tdelay sda_in= 1;
#tdelay sda_in= 0;            //Sending slave address=0000000
#tdelay   sda_in <= slave_add_compare[6];
#10       sda_in <= slave_add_compare[5];
#10       sda_in <= slave_add_compare[4];
#10       sda_in <= slave_add_compare[3];
#10       sda_in <= slave_add_compare[2];
#10       sda_in <= slave_add_compare[1];
#10       sda_in <= slave_add_compare[0];
#10 sda_in <=1;               //For read operation
#5 ack_check <= 1;
#10 ack_check <= 0;

//For Storing the data from sda line which master is reading     
#10 GPIO_input_store[7] <= sda;
#10 GPIO_input_store[6] <= sda;
#10 GPIO_input_store[5] <= sda;
#10 GPIO_input_store[4] <= sda;
#10 GPIO_input_store[3] <= sda;
#10 GPIO_input_store[2] <= sda;
#10 GPIO_input_store[1] <= sda;
#10 GPIO_input_store[0] <= sda;
#10 read_oper_check <= 1;
#10 read_oper_check <= 0;

# testcycle
@ (negedge sclk)               //For stop
#tdelay sda_in = 0;
#tdelay sda_in = 1;
$display (" End of testcycle, for another random check, run again "); 
#500 $stop;

end

endmodule
