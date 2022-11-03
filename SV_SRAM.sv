

/////////TRASACTOR////////////////
class  transaction;

  rand bit en,we;

  rand bit [2:0] addres;

  rand bit [7:0] data_in;

        bit [7:0] data_out;
 
   function void  post_randomize();
    $display("transaction::transaction Generated"); 
    $display("en=%0d,we=%0d-----",en,we);
    $display("addres=%0d--------",addres);
    $display("data_in=%0d-------",data_in);	
    $display("data_out=%0d------",data_out);	
   endfunction
endclass



/////////////////GENRATOR//////////////////////////////////////

class genrator;

 rand transaction trans;
 
    mailbox gen2driv;
  
   function new(mailbox gen2driv);
     this.gen2driv =gen2driv;
  endfunction
     
 task main; 
   repeat(1)
    begin
        trans=new();
		trans.randomize();
           // if(!trans.randomize())
	        //  $fatal("gen::trans randomize failed ");
	        gen2driv.put(trans);
			$display("genrator :: put into mailbox");
          
    end
 endtask
endclass






//module mailbox_ex;
//   genrator gen;
//   driver   dri;
   
//   mailbox gen2driv;
   
//initial 
 
  //  begin
   //   gen2driv=new();
     // gen =new (gen2driv);
     // dri =new (gen2driv);      
     
   // fork
     //  gen.main();
     // dri.run();
    // join
 //end 
 
 
//endmodule


///////////INTERFACE/////////////////////////
 interface ram_intf(input logic clk);
   logic en,we;
   logic[2:0] addres;
  logic[7:0] data_in;
  logic[7:0] data_out;
  
   clocking ram_cb@(posedge clk);
       input en,we;
       input addres;
       input data_in;
       output data_out;        
  endclocking
  
  modport RAM_modport( clocking ram_cb,input clk );

endinterface


//////////////DRIVER/////////////////////////////
class driver;

  virtual ram_intf ram_vif; 
    mailbox gen2driv;
	
	function new(virtual ram_intf ram_vif,mailbox gen2driv);
	  this .ram_vif=ram_vif;
	  this.gen2driv=gen2driv;
	endfunction
	
	
	task drive;
	     forever
		    begin
			transaction trans;
			
			ram_vif.RAM_modport.ram_cb.en <= 0;
			ram_vif.RAM_modport.ram_cb.we <= 0;
			gen2driv.get(trans);
			@(posedge ram_vif.RAM_modport.clk)
			ram_vif.RAM_modport.ram_cb.en <= trans.en;
			ram_vif.RAM_modport.ram_cb.we <= trans.we;
			if(trans.en && trans.we)
			  begin
               ram_vif.RAM_modport.ram_cb.addres <= trans.addres;
			   ram_vif.RAM_modport.ram_cb.data_in <= trans.data_in;
			  $display(addres=%0d,data_in=%0d,addres,data_in);
			  
			  end
			
			end
	
	
	endtask
 task run;
    repeat(1);
	 begin
	     gen2driv.get(trans);	 
           $display("en=%0d,we=%0d----",trans.en,trans.we);
           $display("addres=%0d-------",trans.addres);
           $display("data_in=%0d------",trans.data_in);	
           $display("data_out=%0d-----",trans.data_out);		 		 
	 end 
endtask	 
   
endclass



// // /////////////environment/////////////////

 class environment;
   
    genrator gen;
   
     driver  driv;
   
    mailbox gen2driv;
   
   virtual ram_intf ram_vif; 
   
   
    function new(virtual ram_intf ram_vif );
   
	   this.ram_vif = ram_vif;
	   gen2driv =new();
	  
	   gen =new(gen2driv,gen_ended);
	   driv = new(ram_vif,gen2driv);  
    endfunction
   
   
   task test();
     fork
	  gen.main();
	  driv.main();
	 join_any 
    endtask  

 task run;
	 test();
	 $finish;
 endtask

 endclass


/////////////TEST//////////////////////////////

program test(ram_intf intf);

  class my_trans extends transaction;
    bit [1:0] count;
    
    function void pre_randomize();
      en.rand_mode(0);
      we.rand_mode(0);
      addres.rand_mode(0);
	  data_in.rand_mode(0);
            
      if(cnt %2 == 0)
   	  begin
        en = 1;
        we = 1;
        addr  = count; 
		data_in = count;
      end 
      else 
	    begin
			en = 1;
			we = 0;
			addr  = count;
			
			count++;
       end
      cnt++;
    endfunction
    
  endclass
  
   environment env;
  my_trans my_tr;
  initial
    begin
	 env=new(intf);
	 my_tr =new();
	 
	env.gen.trans = my_tr;
	env.run();
	
	end
  
endprogram



////////////////////TESTBENCH//////////////////
module tbench_top;
 bit clk;
 
 always #5 clk =~clk;
 
 ram_intf intf(clk);
 
 
 test t1(intf);
 
 
 ram20_10_2022 DUT (
                     .clk(intf.clk),
					 .en(intf.en),
					 .we(intf.we),
                     .addres(intf.addres);
                     .data_in(intf.data_in);
                     .data_out(intf.data_out) );
 
 
 

endmodule








//program test()

// environment env;
// initial
// begin
  // env=new(intf);
  // env.run();
// end
// endprogram

// module tbench_top;
// bit clk;
// always #5 clk =~clk;

// ram intf(clk);

// test(intf);

 // ram DUT (
    // .clk(intf.clk),
    // .en(intf.en),
    // .addres(intf.addres),
    // .data_in(intf.data_in),
    // .data_out(intf.data_out)
   // );
// endmodule



