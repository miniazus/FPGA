# RTL & Firmware Bit Manipulation Master Cheat Sheet

**Sources:** *Hacker's Delight (Henry Warren)*, *Stanford Bit Twiddling Hacks*, and Standard Digital Design Patterns.
**Notation:** `x` is the input vector. `^` is XOR. `&` is AND. `|` is OR. `~` is NOT. `-x` implies Two's Complement (`~x + 1`).

---

### 1. Isolation & Search (Priority & Allocators)
*Used to find the "First Winner" or "Next Empty Slot" without loops.*

| Operation | Formula | Example (4-bit) | Hardware Application |
| :--- | :--- | :--- | :--- |
| **Isolate Lowest Set Bit (LSB)** | `x & (-x)` | `1010` → `0010` | **Priority Arbiter:** Finds the highest priority active user. |
| **Isolate Lowest Zero (Hole)** | `~x & (x + 1)` | `1011` → `0100` | **Free List Allocator:** Finds the first empty memory slot. |
| **Isolate Most Significant Bit** | *(Requires `clog2` or Smearing)* | `0110` → `0100` | **Reverse Priority:** Finding the highest index active. |
| **Clear Lowest Set Bit** | `x & (x - 1)` | `1010` → `1000` | **Round Robin State:** Mark the current user as "Served". |
| **Set Lowest Zero** | `x | (x + 1)` | `1011` → `1111` | **Allocation:** Mark the found empty slot as "Busy". |

---

### 2. Masking & Region Generation
*Used to create "Thermometer Codes" or mask off lower/higher priority users.*

| Operation | Formula | Example (4-bit) | Hardware Application |
| :--- | :--- | :--- | :--- |
| **Mask All Below LSB** | `x ^ (x - 1)` | `0100` → `0011` | **Mask Generation:** Ignore everyone lower than current winner. |
| **Mask All Above LSB** | `~x & (x - 1)` | `0100` → `1000` | **Mask Generation:** Ignore everyone higher than current winner. |
| **Flood Right (Propagate 1s)**| `x | (x - 1)` | `0100` → `0111` | **inclusive Mask:** Set all bits below and including the LSB. |
| **Flood Right (Smearing)** | `x | (x>>1) | (x>>2)...` | `1000` → `1111` | **Thermometer Code:** Create a valid window starting from MSB. |

---

### 3. Alignment & Modulo (Pointers & FIFOs)
*Optimized math for buffer management (Assuming Power-of-2 sizes).*

| Operation | Formula | Logic Description | Hardware Application |
| :--- | :--- | :--- | :--- |
| **Modulo (Wrap Around)** | `x & (N - 1)` | Remainder of `x / N`. | **Circular Buffer:** Increment pointer `(ptr + 1) & 0xF`. |
| **Round Down to Multiple**| `x & ~(N - 1)` | Truncate to N-byte boundary.| **Memory Alignment:** Align address to 16/32-byte page. |
| **Round Up to Multiple** | `(x + N - 1) & ~(N - 1)` | Align to *next* N-byte boundary.| **DMA Transfer:** Ensure packet size matches bus width. |
| **Binary to Gray Code** | `(x >> 1) ^ x` | minimize bit toggles. | **CDC FIFO:** Passing counters safely across clock domains. |
| **Gray to Binary** | *Iterative XOR shift* | Restore binary value. | **CDC FIFO:** Decoding pointers in the destination domain. |

---

### 4. Boolean Checks (Assertions & Logic)
*Fast checks for validity, often used in `assert` or Status Registers.*

| Operation | Formula | Returns True If... | Hardware Application |
| :--- | :--- | :--- | :--- |
| **Is Power of 2** | `(x & (x - 1)) == 0` | Exactly one '1' is set. | **FIFO Depth Check:** Verifies buffer size is safe for binary masking. |
| **Is Power of 2 (or 0)** | `(x & (x - 1)) == 0` | 0 or 1 bit set. | **One-Hot Check:** Ensure only one master is granting. |
| **Has Single Zero** | `((x + 1) & x) == 0` | Exactly one '0' is set. | **Link Status:** Check if only one channel is down. |
| **Is All Ones** | `x == '1` | All bits are high. | **Full Flag:** Buffer is 100% full. |
| **Is All Zeros** | `x == '0` | All bits are low. | **Empty Flag:** Buffer is 100% empty. |
| **Detect Any Change** | `(val ^ old_val) != 0` | Value changed. | **Interrupt Gen:** Trigger on any register change. |

---

### 5. Advanced Tricks (Data Swapping)
*Manipulation without temporary variables.*

| Operation | Formula | Description | Hardware Application |
| :--- | :--- | :--- | :--- |
| **Toggle Specific Bit** | `x ^ (1 << N)` | Flip bit N. | **Heartbeat:** Blink an LED or toggle a "Keep-Alive" bit. |
| **Check Specific Bit** | `(x >> N) & 1` | Read bit N. | **Muxing:** Extract specific flag from status register. |
| **Swap Values (XOR Swap)**| `a^=b; b^=a; a^=b;` | Swap `a` and `b`. | **Sorting Network:** Swap elements without temp storage. |
| **Conditional Negate** | `(x ^ -flag) + flag` | Negate `x` if `flag` is 1. | **DSP:** Absolute value calculation without branching. |

---

### 6. SystemVerilog Specifics (Built-in Optimizations)
*Don't use C-hacks if the language supports it natively.*

| Operation | C-Style Hack | SystemVerilog Native | Why use Native? |
| :--- | :--- | :--- | :--- |
| **Count Ones** | `Loop { x &= (x-1) }` | `$countones(x)` | Infers optimized Adder Tree. |
| **Leading Zeros** | *De Bruijn Sequence* | `$clog2(x)` | Runs at compile time (if constant). |
| **Find First Set** | `x & -x` | `$countbits(x, 1)` | More readable (though `& -x` is fine). |
| **Parity Calculation** | `x ^ (x>>1) ...` | `^x` (Reduction XOR) | Standard, readable syntax. |
