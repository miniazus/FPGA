# SystemVerilog System Functions Cheat Sheet

### 1. Math & Sizing (Parameterization)
*These functions run on your computer during compilation. They create **Zero Hardware**.*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$clog2(x)`** | Ceiling Log Base 2. | ✅ | **None** (Calculated at build time). | `localparam W = $clog2(16);` |
| **`$bits(x)`** | Returns bit width. | ✅ | **None** (Calculated at build time). | `localparam S = $bits(packet_t);` |
| **`$high(x)`** | Highest array index. | ✅ | **None** (Calculated at build time). | `for(i=0; i<=$high(arr); i++)` |
| **`$low(x)`** | Lowest array index. | ✅ | **None** (Calculated at build time). | `for(i=$low(arr); i<10; i++)` |
| **`$size(x)`** | Array element count. | ✅ | **None** (Calculated at build time). | `int len = $size(my_array);` |

---

### 2. Data Conversion & Casting
*Used to reinterpret bits. Most are just "renaming wires" and cost nothing.*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$signed(x)`** | Treat as 2's comp. | ✅ | **None** (Wires only). | `y = $signed(a) * $signed(b);` |
| **`$unsigned(x)`** | Treat as unsigned. | ✅ | **None** (Wires only). | `y = $unsigned(a);` |
| **`$cast(d, s)`**| Dynamic casting. | ✅ | **Low** (Simple Mux/Logic checks). | `$cast(state, 3'b010);` |
| **`$rtoi(x)`** | Real to Integer. | ⚠️ | **None** (If input is constant parameter). | `localparam I = $rtoi(2.5);` |

---

### 3. Bit Analysis (SystemVerilog 2012+)
*These generate actual logic gates (LUTs).*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$countbits(x, v)`**| Count matching bits. | ✅ | **Medium/High** (Infers an Adder Tree). | `cnt = $countbits(data, 1'b1);` |
| **`$onehot(x)`** | Is exactly 1 bit high? | ✅ | **Low/Medium** (Comparator logic). | `if ($onehot(request)) ...` |
| **`$onehot0(x)`** | Is 0 or 1 bit high? | ✅ | **Low/Medium** (Comparator logic). | `if ($onehot0(request)) ...` |

---

### 4. Memory Initialization
*Used to infer large storage blocks.*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$readmemh("f", m)`**| Load Hex file. | ✅ | **High** (Infers Block RAM / ROM). | `initial $readmemh("sin.hex", mem);` |
| **`$readmemb("f", m)`**| Load Binary file. | ✅ | **High** (Infers Block RAM / ROM). | `initial $readmemb("cfg.bin", mem);` |

---

### 5. Display & Debugging
*These are for humans, not hardware.*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$error("m")`** | Report error. | ⚠️ | **None** (Stops the compiler). | `initial if (P<0) $error("Bad P");` |
| **`$warning("m")`** | Report warning. | ⚠️ | **None** (Log message only). | `$warning("Careful!");` |
| **`$display("m")`** | Print to console. | ❌ | **N/A** (Ignored by synthesis). | `$display("Val: %d", val);` |
| **`$stop`** | Pause simulation. | ❌ | **N/A** (Ignored by synthesis). | `if (err) $stop;` |

---

### 6. Simulation Utilities (Do Not Synthesize)
*Never use these in your RTL design files.*

| Function | Description | Synth? | Hardware Cost | Usage Example |
| :--- | :--- | :--- | :--- | :--- |
| **`$urandom()`** | Unsigned random. | ❌ | **High** (Software PRNG algo). | `data = $urandom();` |
| **`$time`** | Current time. | ❌ | **Low** (Reads sim variable). | `$display("T=%t", $time);` |
| **`$sqrt(x)`** | Square Root. | ❌ | **Very High** (Need CORDIC IP). | Use IP Catalog instead. |
| **`$ln(x)`** | Natural Log. | ❌ | **Very High** (Need Taylor Series). | Use Look-Up Table instead. |
