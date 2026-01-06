# SystemVerilog System Functions Cheat Sheet (with Complexity)

### 1. Math & Sizing (Parameterization)
*These functions run on your computer during compilation. They create **Zero Hardware**.*

| Function | Description | Synthesizable? | Hardware Cost |
| :--- | :--- | :--- | :--- |
| **`$clog2(x)`** | Ceiling Log Base 2. | **✅ YES** | **None** (Calculated at build time). |
| **`$bits(x)`** | Returns bit width. | **✅ YES** | **None** (Calculated at build time). |
| **`$high(x)`** | Highest array index. | **✅ YES** | **None** (Calculated at build time). |
| **`$low(x)`** | Lowest array index. | **✅ YES** | **None** (Calculated at build time). |
| **`$size(x)`** | Array element count. | **✅ YES** | **None** (Calculated at build time). |

---

### 2. Data Conversion & Casting
*Used to reinterpret bits. Most are just "renaming wires" and cost nothing.*

| Function | Description | Synthesizable? | Hardware Cost |
| :--- | :--- | :--- | :--- |
| **`$signed(x)`** | Treat as 2's comp. | **✅ YES** | **None** (Wires only). |
| **`$unsigned(x)`** | Treat as unsigned. | **✅ YES** | **None** (Wires only). |
| **`$cast(d, s)`**| Dynamic casting. | **✅ YES** | **Low** (Simple Mux/Logic checks). |
| **`$rtoi(x)`** | Real to Integer. | **⚠️ CONST** | **None** (If input is constant parameter). |

---

### 3. Bit Analysis (SystemVerilog 2012+)
*These generate actual logic gates (LUTs).*

| Function | Description | Synthesizable? | Hardware Cost |
| :--- | :--- | :--- | :--- |
| **`$countbits(x, v)`**| Count matching bits. | **✅ YES** | **Medium/High** (Infers an Adder Tree). |
| **`$onehot(x)`** | Is exactly 1 bit high? | **✅ YES** | **Low/Medium** (Comparator logic). |
| **`$onehot0(x)`** | Is 0 or 1 bit high? | **✅ YES** | **Low/Medium** (Comparator logic). |

---

### 4. Memory Initialization
*Used to infer large storage blocks.*

| Function | Description | Synthesizable? | Hardware Cost |
| :--- | :--- | :--- | :--- |
| **`$readmemh("f", m)`**| Load Hex file. | **✅ YES** | **High** (Infers Block RAM / ROM). |
| **`$readmemb("f", m)`**| Load Binary file. | **✅ YES** | **High** (Infers Block RAM / ROM). |

---

### 5. Display & Debugging
*These are for humans, not hardware.*

| Function | Description | Synthesizable? | Hardware Cost |
| :--- | :--- | :--- | :--- |
| **`$error("msg")`** | Report error. | **⚠️ YES** | **None** (Stops the compiler). |
| **`$fatal("msg")`** | Report fatal error. | **⚠️ YES** | **None** (Stops the compiler). |
| **`$warning("msg")`** | Report warning. | **⚠️ YES** | **None** (Log message only). |
| **`$display("msg")`** | Print to console. | **❌ NO** | **N/A** (Ignored). |

---

### 6. Simulation Utilities
*Never use these in your RTL design files.*

| Function | Description | Synthesizable? | Complexity |
| :--- | :--- | :--- | :--- |
| **`$urandom()`** | Unsigned random. | **❌ NO** | **High** (Software PRNG algo). |
| **`$time`** | Current time. | **❌ NO** | **Low** (Reads sim variable). |
| **`$sqrt(x)`** | Square Root. | **❌ NO** | **Very High** (If built in HW, needs CORDIC). |
| **`$ln(x)`** | Natural Log. | **❌ NO** | **Very High** (If built in HW, needs Taylor Series). |
