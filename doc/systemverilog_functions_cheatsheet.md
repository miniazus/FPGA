# SystemVerilog System Functions Cheat Sheet for Synthesis

### 1. Math & Sizing (Essential for Parameterization)
*Used extensively in module headers and `generate` blocks to calculate widths and constants.*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$clog2(x)`** | Ceiling Log Base 2. | **✅ YES** | `localparam WIDTH = $clog2(16); // 4` |
| **`$bits(x)`** | Returns bit width of variable/type. | **✅ YES** | `localparam SIZE = $bits(my_struct_t);` |
| **`$high(x)`** | Returns highest index of array. | **✅ YES** | `for(i=0; i<=$high(arr); i++)` |
| **`$low(x)`** | Returns lowest index of array. | **✅ YES** | `for(i=$low(arr); i<10; i++)` |
| **`$size(x)`** | Returns number of array elements. | **✅ YES** | `int len = $size(my_array);` |
| **`$ln(x)`** | Natural Logarithm. | **❌ NO** | Simulation only. |
| **`$sqrt(x)`** | Square Root. | **❌ NO** | Simulation only (use CORDIC IP instead). |

---

### 2. Data Conversion & Casting
*Used to manipulate data types inside logic blocks, especially for signed math.*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$signed(x)`** | Interprets vector as signed (2's comp). | **✅ YES** | `val = $signed(a) * $signed(b);` |
| **`$unsigned(x)`** | Interprets vector as unsigned. | **✅ YES** | `val = $unsigned(a);` |
| **`$cast(d, s)`**| Dynamic casting (checks validity). | **✅ YES** | `$cast(my_enum_var, 3'b010);` |
| **`$itor(x)`** | Integer to Real conversion. | **❌ NO** | Reals do not exist in hardware. |
| **`$rtoi(x)`** | Real to Integer conversion. | **⚠️ CONST** | Only if input is constant parameter. |

---

### 3. Bit Analysis (SystemVerilog 2012+)
*Very useful for complex logic reduction and assertions.*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$countbits(x, v)`**| Counts bits matching value `v`. | **✅ YES** | `ones = $countbits(data, 1'b1);` |
| **`$onehot(x)`** | Returns true if exactly 1 bit is high. | **✅ YES** | `if ($onehot(grant_vector)) ...` |
| **`$onehot0(x)`** | Returns true if 0 or 1 bit is high. | **✅ YES** | `if ($onehot0(grant_vector)) ...` |
| **`$isunknown(x)`** | Checks if any bit is 'X' or 'Z'. | **❌ NO** | Hardware is never 'unknown'. |

---

### 4. Memory Initialization
*Used to load Look-Up Tables (LUTs) and ROMs.*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$readmemh("f", m)`**| Loads Hex file into array. | **✅ YES** | `initial $readmemh("sin.hex", mem);` |
| **`$readmemb("f", m)`**| Loads Binary file into array. | **✅ YES** | `initial $readmemb("cfg.bin", mem);` |

---

### 5. Display & Debugging
*Used for reporting status during compilation or simulation.*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$error("msg")`** | Reports error. | **⚠️ YES** | Halts Synthesis (good for checks). |
| **`$fatal("msg")`** | Reports fatal error. | **⚠️ YES** | Halts Synthesis immediately. |
| **`$warning("msg")`** | Reports warning. | **⚠️ YES** | Prints log warning but continues. |
| **`$display("msg")`** | Prints to console. | **❌ NO** | Ignored by synthesis. |
| **`$monitor("msg")`** | Prints when args change. | **❌ NO** | Simulation only. |
| **`$stop`** | Pauses simulation. | **❌ NO** | Simulation only. |
| **`$finish`** | Ends simulation. | **❌ NO** | Simulation only. |

---

### 6. Randomization & Time
*Used primarily in Testbenches (Simulation).*

| Function | Description | Synthesizable? | Usage Example |
| :--- | :--- | :--- | :--- |
| **`$urandom()`** | Unsigned random integer. | **❌ NO** | `data = $urandom();` |
| **`$random()`** | Signed random integer (Legacy). | **❌ NO** | Avoid. Use `$urandom`. |
| **`$time`** | Current simulation time. | **❌ NO** | `$display("Time: %t", $time);` |
