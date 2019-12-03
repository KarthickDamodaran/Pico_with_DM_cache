`timescale 1ns/1ps 
module mem(clk,mem_valid,mem_instr,mem_ready,mem_addr1,mem_wdata,mem_wstrb,mem_rdata);
//module mainMod(clock,mem_addr);
input clk;
input mem_valid;reg flag;
	input mem_instr;
	output reg mem_ready;
	reg [31:0] mem_addr;
input [31:0] mem_addr1;
	input [31:0] mem_wdata;
	input [3:0] mem_wstrb;
	output reg [31:0] mem_rdata;
reg [31:0]memory[0:1023];


//input clock;
//input [31:0]mem_addr;
//tag-21 bits, index-3 bits, block id-2 bits, offset-6 bits
parameter dataSize=31; //64 bytes. Each byte is 8 bits each 64*8=512 bits
//parameter way=7;
parameter set=63;
parameter SBtagsize=25;
//Superblock: tag-5 bits [24:4],block_id-4 bits[3:0]
//parameter pref_size=7;
//parameter pref_blocks=4;
//Prefetecher is fully associative with 8 ways and single index. Each way has 4 blocks of data.

reg [SBtagsize:0]tagArray[set:0];
reg [dataSize:0]dataArray[set:0];
//reg [2:0]lruShiftReg[set:0][way:0];
reg [9:0] LRU_cache_count[set:0];


//reg [2047:0]prefetcher_data[0:0][pref_size:0]; // prefetcher declaration
//reg [29:0]prefetcher_tag[0:0][pref_size:0];
//reg pref_flag[31:0];
//integer counter[set:0][way:0];
reg ValidBit[7:0];
//reg [6:0] LRU_prefetch_count[0:0][7:0];
reg [2:0] block_no;
reg [31:0]addr;
reg [63:0] valid;


reg foundDatainCache,foundDatainprefetcher;
reg [dataSize:0]data; //Data 

reg [1:0] CF;

integer file_outputs; // var to see if file exists 
integer scan_outputs; // captured text handler

integer cache_Hit=0,cache_Miss=0,prefetcher_Hit=0;
integer count=0,enter=0;
initial begin
valid=0;
$readmemh("PICOData.txt",memory);
end
/*initial begin
LRU_prefetch_count[0][0]=0;
LRU_prefetch_count[0][1]=0;
LRU_prefetch_count[0][2]=0;
LRU_prefetch_count[0][3]=0;
LRU_prefetch_count[0][4]=0;
LRU_prefetch_count[0][5]=0;
LRU_prefetch_count[0][6]=0;
LRU_prefetch_count[0][7]=0;
end*/
/*initial
begin
	//open the data Memory file
	file_outputs = $fopen("C:/DataMemory.txt", "r"); //Opening text file
   if (file_outputs == 0) begin             // If outputs file is not found
      $display("data_file handle was NULL"); 
      $finish;
   end
end
*/
always @(mem_addr1)
flag=1;
always @(posedge clk && (count<=515683)) //Only when there is a change in the 
begin
foundDatainCache=0;
//foundDatainCache<=0;
if(flag==1)
flag=0;
	enter=enter+1;
mem_ready <= 0;
mem_addr=mem_addr1/4;
	$display($time,"  mem_addr:%h",mem_addr);
	findDataInCache(mem_addr);//task

	if(foundDatainCache)
	begin
		//No need to go to memory and update cache or use LRU policy
		//decompress the data and display 
		//decompress();
		cache_Hit=cache_Hit+1;
		$display($time ,"  Cache HIT and data read=%h and  Number_Of_Cache_Hit=%d\n",data,cache_Hit);	
		$display($time ,"  Number_Of_Cache_Hit=%d\n",cache_Hit);
		$display($time ,"  Number_Of_Cache_miss=%d\n",cache_Miss);
		//$display($time ,"  Number_Of_Prefetcher_usage=%d\n",prefetcher_Hit);	
	end

	else 
	begin
	      
	       
	     findDataInMemory(mem_addr);//task
$display("data from FDIM=%h \n",data);
		//compress();
		//findCompFactor(data,CF);
if(mem_ready!=0)
		updateCache(mem_addr,data); //YACC logic

		//send uncompressed data to lower level cache
		cache_Miss=cache_Miss+1;
		$display($time ,"  Cache MISS . data read=%h \n",data);
		$display($time ,"  Number_Of_Cache_Hit=%d\n",cache_Hit);
        $display($time ,"  Number_Of_Cache_miss=%d\n",cache_Miss);
        //$display($time ,"  Number_Of_Prefetcher_usage=%d\n",prefetcher_Hit);
	end	
	count=count+1;
end

//Task to find the data in cache
task findDataInCache;
input [31:0] mem_addr;
//output foundDatainCache;
//output[dataSize:0]data;
reg [5:0] index;
reg [25:0] tag;
integer i;
begin
tag=mem_addr[31:6];
index=mem_addr[5:0];
i=0;
//foundDatainCache=0;

if(tagArray[index]==tag && valid[index] )
foundDatainCache=1;

if(foundDatainCache==1)
begin
data=dataArray[index];
mem_rdata =dataArray[index];if(mem_valid==1) mem_ready<=1;
end
end


endtask


task updateCache;
input [31:0] mem_addr;
input [31:0] data;
reg [5:0] index;
reg [25:0] tag;integer ind;
begin
tag=mem_addr[31:6];
index=mem_addr[5:0];
ind=index;
valid[ind]=1;
tagArray[ind]=tag;
dataArray[ind]=data;
end

endtask




task findDataInMemory;
input [31:0] mem_addr;
//output [dataSize:0]data1;
integer offset,quotient,quotient1,newLineNum,x;
begin
//mem_ready <= 0;
$display("Entered find data in memory routine\n");
		if (mem_valid && !mem_ready) begin
$display("Mem ready=%b",mem_ready);
			if (mem_addr < 1024) begin
				mem_ready <= 1;
				mem_rdata = memory[mem_addr];
                                data = memory[mem_addr];
$display("Data inside routine: %h",data);
$display("MemData inside routine: %h",mem_rdata);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
end
end
$display("Mem ready1=%b\n",mem_ready);
//$display("Data inside routine1: %h\n",data1);
$display("MemData inside routine1: %h\n",mem_rdata);

	//offset = mem_addr; //decimal eqnt of mem_addr
	//quotient = offset/64;	
	
	//if(quotient<=1630814)begin
	//	x=$fseek(file_outputs,((128*mem_addr)+(mem_addr*2)),0);	
	//	$display($time,"  Line number:%d",mem_addr);
	//end	
	//else begin
	/*	quotient1 = quotient/64;
		newLineNum = quotient-(64*quotient1);
		x=$fseek(file_outputs,((128*newLineNum)+(newLineNum*2)),0);
		$display($time,"  Line number:%d",newLineNum); */		
	//end
	
	//scan_outputs = $fscanf(file_outputs, "%h\n", data);     //Outputs line text
	
   //$fclose(file_outputs); //Closing files just in case to prevent wasting memory
	//$display($time,"  File operation: Data =%h",data);
end
endtask




//Shift the positions to right by one bit and insert the recently used way index.

endmodule

	
/*initial begin
		memory[0] = 32'h 3fc00093; //       li      x1,1020
		memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
		memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		memory[3] = 32'h 00110113; //       addi    x2,x2,1
		memory[4] = 32'h 0020a023; //       sw      x2,0(x1)
		memory[5] = 32'h ff5ff06f; //       j       <loop>

                memory[0] = 32'h 06400093; //       li      x1,1020
		memory[1] = 32'h 0000a103; //       sw      x0,0(x1)
		memory[2] = 32'h 0040a103; // loop: lw      x2,0(x1)
		memory[3] = 32'h 0080a103; //       addi    x2,x2,1
		memory[4] = 32'h 00C0a103; //       sw      x2,0(x1)
		memory[5] = 32'h 0100a103; //       j       <loop>
                memory[100]=32'd0;
                memory[25]=32'd1;
                memory[26]=32'd2;
                memory[27]=32'd3;
                memory[28]=32'd4;
                memory[29]=32'd5;

	end

always @(posedge clk) begin
		mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
			if (mem_addr < 1024) begin
				mem_ready <= 1;
				mem_rdata <= memory[mem_addr >> 2];
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
end
end
end
endmodule
*/
