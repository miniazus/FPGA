# RTL Bit Manipulation & Arithmetic Cheat Sheet

**Verified Against:** *Hacker's Delight* & *Stanford Bit Twiddling Hacks*.
**Context:** `x` is the input vector. Operations assume 2's Complement arithmetic.

---

### 1. Manipulating the Right-Most Bit (LSB)
*These are the most common operations for Arbiters, Counters, and Linked Lists.*

| Operation | Formula | Trace Example (4-bit) | RTL Application |
| :--- | :--- | :--- | :--- |
| **Isolate Lowest Set Bit** | `x & (-x)` | `1010` (`10`) &rarr; `0010` (`2`) | **Priority Arbiter:** Finds the next user to serve. |
| **Clear Lowest Set Bit** | `x & (x - 1)` | `1010` (`10`) &rarr; `1000` (`8`) | **Looping:** Removes the user just served. |
| **Set Lowest Zero Bit** | `x \| (x + 1)` | `1011` (`11`) &rarr; `1111` (`15`) | **Allocation:** Marks the first empty slot as busy. |
| **Isolate Lowest Zero Bit**| `~x & (x + 1)`| `1011` (`11`) &rarr; `0100` (`4`) | **Free List:** Finds the exact index of the first hole. |
| **Isolate Least Significant 1** | `x ^ (x & (x - 1))` | `1010` &rarr; `0010` | *Alternative to `x & -x` if negation is unavailable.* |

---

### 2. Mask Generation (Smearing)
*Used to create "Thermometer Codes" or Priority Masks.*

| Operation | Formula | Trace Example (4-bit) | RTL Application |
| :--- | :--- | :--- | :--- |
| **Mask: LSB and Below** | `x ^ (x - 1)` | `0100` (`4`) &rarr; `0111` (`7`) | **Grant Logic:** Creates a mask covering the winner + lower bits. |
| **Mask: Strictly Below LSB** | `~x & (x - 1)` | `0100` (`4`) &rarr; `0011` (`3`) | **Priority Mask:** Ignore current winner, enable only lower priorities. |
| **Mask: Strictly Above LSB** | `~x \| (x - 1)` *Then Invert* | `0100` (`4`) &rarr; `1000` (`8`) | *Complex to do in 1 step; usually `~(x ^ (x-1))`.* |
| **Smear Right (Fill 1s)** | `x \| (x >> 1) \| (x >> 2)...` | `1000` &rarr; `1111` | **Valid Window:** Creates a mask from MSB down to bit 0. |

---

### 3. Boolean Properties (Checks)
*Return 1 (True) or 0 (False). Essential for `assert` and Status Flags.*

| Property | Formula | Trace Example | RTL Application |
| :--- | :--- | :--- | :--- |
| **Is Power of 2** | `(x & (x - 1)) == 0` | `1000` &rarr; True<br>`1100` &rarr; False | **FIFO Depth:** Verifies buffer size is safe for wrapping. |
| **Is Power of 2 or Zero** | `(x & (x - 1)) == 0` | `0000` &rarr; True | **One-Hot Check:** Ensures only 0 or 1 master is active. |
| **Has Exactly One Zero** | `((x + 1) & x) == 0` | `1101` &rarr; True | **Link Check:** Verifies only one channel is disconnected. |
| **Are Adjacent Bits Set?** | `(x & (x << 1)) != 0` | `0011` &rarr; True | **Pattern Detect:** Finds consecutive active requests. |

---

### 4. Pointers & Alignment (Modulo Math)
*Optimized math for Power-of-2 buffer sizes (`N`).*

| Operation | Formula | Example (`N=16`) | RTL Application |
| :--- | :--- | :--- | :--- |
| **Modulo (Wrap)** | `x & (N - 1)` | `19 & 15` &rarr; `3` | **Circular Buffer:** Cheap division for ring buffers. |
| **Round Down** | `x & ~(N - 1)` | `19 & ~15` &rarr; `16` | **Align Address:** Truncate address to page boundary. |
| **Round Up** | `(x + N - 1) & ~(N - 1)` | `19` &rarr; `32` | **DMA Size:** Pad data length to match bus width. |
| **Binary to Gray** | `(x >> 1) ^ x` | `0011` &rarr; `0010` | **CDC:** Safe counter passing across clock domains. |

---

### 5. Advanced Tricks (No Branching)
*Optimization to avoid `if/else` logic.*

| Operation | Formula | Description | RTL Application |
| :--- | :--- | :--- | :--- |
| **Conditional Negate** | `(x ^ -flag) + flag` | If `flag=1`, returns `-x`. | **DSP:** Absolute value logic without Mux. |
| **XOR Swap** | `a^=b; b^=a; a^=b` | Swaps A and B. | **Sorting:** Swap registers without temp storage. |
| **Toggle Bit `k`** | `x ^ (1 << k)` | Inverts bit at index `k`. | **Heartbeat:** Toggles a status LED/Bit. |
| **Detect Any Change** | `(new ^ old) != 0` | 1 if value changed. | **Wakeup:** Trigger interrupt on any register change. |
