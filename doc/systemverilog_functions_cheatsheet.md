Function,Description,Synth?,Hardware Cost,Usage Example
1. Bit Analysis & Logic,,,,
$countones(x),Count bits set to 1.,✅,Medium (Adder Tree),cnt = $countones(bus);
"$countbits(x, v)",Count bits matching value v.,✅,Medium (Adder Tree),"zeros = $countbits(bus, 1'b0);"
$onehot(x),True if exactly one bit is 1.,✅,Low (Comparator),if ($onehot(grant)) ...
$onehot0(x),True if zero or one bit is 1.,✅,Low (Comparator),if ($onehot0(grant)) ...
$isunknown(x),True if any bit is X or Z.,✅,Low (Comparator),if (!$isunknown(valid)) ...
2. Sizing & Array Query,,,,
$clog2(x),Ceiling Log Base 2.,✅,None (Constant Calc),localparam W = $clog2(128);
$bits(x),Total bit width of type/var.,✅,None (Constant Calc),localparam W = $bits(pkt_t);
$size(x),Number of elements in array.,✅,None (Constant Calc),len = $size(fifo_mem);
$high(x),Highest index of array.,✅,None (Constant Calc),for(i=0; i<=$high(arr); i++)
$low(x),Lowest index of array.,✅,None (Constant Calc),for(i=$low(arr); i<8; i++)
$left(x),Left-most dimension index.,✅,None (Constant Calc),msb = $left(bus);
$right(x),Right-most dimension index.,✅,None (Constant Calc),lsb = $right(bus);
$dimensions(x),Number of array dimensions.,✅,None (Constant Calc),if ($dimensions(arr)==2)
$unpacked_dimensions(x),Count of unpacked dims.,✅,None (Constant Calc),dims = $unpacked_dimensions(x);
$increment(x),"Returns 1 if [0:N], -1 if [N:0].",✅,None (Constant Calc),step = $increment(arr);
3. Type Conversion,,,,
$signed(x),Interpret as 2's Compl.,✅,None (Wire Rename),res = $signed(a) >>> 2;
$unsigned(x),Interpret as Unsigned.,✅,None (Wire Rename),res = $unsigned(a) / 2;
"$cast(dest, src)",Dynamic type cast/check.,✅,Low (Logic Check),"if(!$cast(enum_v, int_v))"
$itor(x),Integer to Real.,⚠️,N/A (Sim Only),real r = $itor(int_v);
$rtoi(x),Real to Integer (Truncate).,⚠️,None (If Const),localparam I = $rtoi(2.5);
$bitstoreal(x),64-bits to Real (IEEE 754).,❌,N/A (Sim Only),real r = $bitstoreal(bits);
$realtobits(x),Real to 64-bits (IEEE 754).,❌,N/A (Sim Only),logic [63:0] b = $realtobits(r);
$shortrealtobits(x),ShortReal to 32-bits.,❌,N/A (Sim Only),logic [31:0] b = $shortrealtobits(f);
4. Assertions & Sampling,,,,
$rose(x),True if signal rose (0->1).,✅,Low (1 FF + Logic),assert property (@(posedge c) $rose(req));
$fell(x),True if signal fell (1->0).,✅,Low (1 FF + Logic),if ($fell(ack)) ...
$stable(x),True if signal is same.,✅,Low (1 FF + Logic),assert property ($stable(data));
$changed(x),True if signal changed.,✅,Low (1 FF + Logic),if ($changed(cfg)) ...
"$past(x, n)",Value from n cycles ago.,✅,Medium (n FFs),"if (val == $past(val, 2))"
$sampled(x),Value at start of timeslot.,✅,None (Sim Sampling),data <= $sampled(in);
$inferred_clock,Get context clock event.,✅,None (Meta),default clocking @$inferred_clock;
5. Memory Loading,,,,
"$readmemh(""f"", m)",Load Hex file to Memory.,✅,High (Init BRAM),"initial $readmemh(""rom.hex"", mem);"
"$readmemb(""f"", m)",Load Bin file to Memory.,✅,High (Init BRAM),"initial $readmemb(""rom.bin"", mem);"
6. Randomization,,,,
$urandom(seed),Unsigned 32b Random.,❌,N/A (Sim Only),addr = $urandom();
"$urandom_range(mx,mn)",Random within range.,❌,N/A (Sim Only),"delay = $urandom_range(100, 10);"
"$dist_uniform(s,mn,mx)",Uniform Distribution.,❌,N/A (Sim Only),"val = $dist_uniform(seed, 0, 10);"
"$dist_normal(s,u,sd)",Normal Distribution.,❌,N/A (Sim Only),"val = $dist_normal(seed, 50, 5);"
7. Display & I/O,,,,
"$display(""fmt"", ...)",Print line to console.,❌,N/A (Sim Only),"$display(""Val: %h"", data);"
"$write(""fmt"", ...)",Print without newline.,❌,N/A (Sim Only),"$write(""Loading..."");"
"$strobe(""fmt"", ...)",Print at end of timestep.,❌,N/A (Sim Only),"$strobe(""Final val: %b"", bus);"
"$monitor(""fmt"", ...)",Auto-print on change.,❌,N/A (Sim Only),"initial $monitor(""T=%t D=%h"", $time, d);"
"$sformatf(""fmt"", ...)",Return formatted string.,❌,N/A (Sim Only),"string s = $sformatf(""err_%0d"", i);"
"$fopen(""f"", ""m"")",Open file handle.,❌,N/A (Sim Only),"int fd = $fopen(""log.txt"", ""w"");"
$fclose(fd),Close file handle.,❌,N/A (Sim Only),$fclose(fd);
"$fwrite(fd, ""fmt"")",Write to file.,❌,N/A (Sim Only),"$fwrite(fd, ""Data: %h\n"", d);"
"$fscanf(fd, ""fmt"", v)",Read vars from file.,❌,N/A (Sim Only),"$fscanf(fd, ""%d %s"", val, str);"
$feof(fd),Check End-Of-File.,❌,N/A (Sim Only),while (!$feof(fd)) ...
8. Simulation Control,,,,
$time,Current Time (64b).,❌,N/A (Sim Only),t_start = $time;
$realtime,Current Time (Real).,❌,N/A (Sim Only),if ($realtime > 10.5ns) ...
$finish(n),End Simulation.,❌,N/A (Sim Only),initial #1000 $finish;
$stop(n),Pause Simulation.,❌,N/A (Sim Only),if (error) $stop;
"$fatal(n, ""msg"")",Fatal Error (Kill Sim).,⚠️,N/A (Sim Only),"$fatal(1, ""Memory Corrupt"");"
"$error(""msg"")",Error (Continue Sim).,⚠️,N/A (Sim Only),"$error(""Timeout detected"");"
"$warning(""msg"")",Warning Message.,⚠️,N/A (Sim Only),"$warning(""Loose timing"");"
"$test$plusargs(""s"")",Check command line arg.,❌,N/A (Sim Only),"if ($test$plusargs(""DEBUG""))"
"$value$plusargs(""s"",v)",Get command line value.,❌,N/A (Sim Only),"$value$plusargs(""SEED=%d"", s);"
9. Advanced Math,,,,
$sqrt(x),Square Root.,❌,Very High (Requires IP),y = $sqrt(x);
"$pow(x, y)",Power (xy).,❌,Very High (Requires IP),"y = $pow(2, x);"
$ln(x),Natural Log.,❌,Very High (Requires IP),y = $ln(val);
$sin(x) / $cos(x),Sine / Cosine.,❌,Very High (Requires IP),y = $sin(theta);
$ceil(x),Ceiling (Round Up).,❌,N/A (Sim Only),int i = $ceil(2.3);
$floor(x),Floor (Round Down).,❌,N/A (Sim Only),int i = $floor(2.9);
