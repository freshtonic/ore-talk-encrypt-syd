# Making Sense of Order-Revealing Encryption

Or, how to encrypt a byte-sized unsigned integer using a toy cipher

---

## About Me

James Sadler
CTO @ CipherStash
@freshtonic on the Twitters

---

# What is Order-Revealing Encryption (ORE)?

^ my motivation for this talk: using ORE at work, took many attempts at reading an academic paper before understanding

> A form of encryption where ciphertexts can be compared to each other to determine an ordering.

> A key is required in order to compare, but crucially does not reveal the plaintext.

--- 

# Segway: Order-Preserving Encryption (OPE)

- ciphertexts can be directly compared (without a key)
- encryption scheme is weaker (ciphertexts leak plaintext information)

---

# Neat! So what can you build with ORE?

^ At CipherStash, we use ORE as a primitive to build a searchable, always-encrypted database

Once you have a data type that can support comparison operations, you can build:

- **Sortable**, encrypted lists
- **Searchable**, encrypted B-Trees

---

# ORE superpower: building encrypted search

^ This is what we do at CipherStash

Queries can be performed **without decryption**

---

# Baseline assumptions

^ Alright, we're now about to jump in the weeds
^ First I'm going to explain what a ciphertext looks like in ORE
^ Then we're I'm going to explain how to encrypt a single byte


- plaintext is a single byte
- e.g. an unsigned integer in range 0-255

---

# Primitive cipher choice

^ don't want to get stuck in the weeds here
^ the goal is to get an intuition of how ORE works without getting into the details of the low-level crypto
^ So, I'm using XOR here as it makes the code examples super easy

For the purposes of this talk we're just using XOR 🔓

---

# Our low-level encryption/decryption functions

^ This ain't gonna get NIST approval
^ This is going to be used by our higher-level ORE encryption scheme

```ruby
def encrypt(plaintext, key)
  plaintext ^ key
end

def decrypt(ciphertext, key)
  ciphertext ^ key
end
```

---

# Encrypting a byte

---

# Step 1

Given a plaintext to encrypt, e.g. 42:

- compare it with all other bytes (including itself)
- store the result in an array

---

# Step 1: the code

^ Run the code

```ruby
def compare_to_all(plaintext)
  (0..255).map do |other|
    plaintext <=> other
  end
end
```

---

# Step 2: assign each element an encryption key

^ The encryption key is also a byte

```ruby
def generate_keys
  (0..255).map { rand(0..255) }
end
```

---

# Step 3: encrypt each element

^ Run the code
^ This gives us the encryption of every result with its corresponding key

```ruby
def encrypt_with_keys(comparisons, keys)
  comparisons.each_with_index.map do |c, index|
    encrypt(c, keys[index])
  end
end
```

---

# *Intermission*: Anatomy of an ORE ciphertext

- an ORE ciphertext has two parts: left & right
- right: encryption of all of the comparison results of the plaintext
- left: the *key* used to decrypt a *specific* comparison result from the RCT

---

# Step 4: Generate the right ciphertext

^ This is fugly because ruby has no unsigned integer data type
^ It outputs a hex string representing the entire array,
^ concatenated as a hex string of the unsigned memory representation.

```ruby
def right_ciphertext(encryptions)
  encryptions.pack("C*").unpack("H*").first
end

def read_right_ciphertext(hex_string)
  [hex_string].pack("H*").unpack("C*")
end
```

---

Step 5: Generate the left ciphertext

^ The left ciphertext is the encryption key used to encrypt its result in the RCT

```ruby
def left_ciphertext(key, offset)
  [offset, key].pack("C*").unpack("H*").first
end

def read_left_ciphertext(hex_string)
  [hex_string].pack("H*").unpack("C*")
end
```

---

# Step 6: full encryption process

^ Compare the plaintext byte to every other possible byte
^ Encrypt the entire array
^ Shuffle the encryptions according to the PRP
^ Generate and return the left and right ciphertexts

```ruby
def encrypt_plaintext(keys, prp, plaintext)
  comparisons = compare_to_all(plaintext)
  encryptions = encrypt_with_keys(comparisons, keys)
  shuffled_encryptions = shuffle(prp, encryptions)
  [
    left_ciphertext(keys[plaintext], prp[plaintext]),
    right_ciphertext(shuffled_encryptions)
  ]
end
```

---

# Which looks like this

```ruby
["bff7", "a33f2c6af2fe2658bf2db3238eec539d3143e64cac255512a7a8ae1..."]
# ^ LCT   ^ RCT
```

---

# [fit] Comparing ciphertexts

---

# The full comparison function

```ruby
def compare(left_ciphertext, right_ciphertext)
  lct = read_left_ciphertext(left_ciphertext)
  rct = read_right_ciphertext(right_ciphertext)

  offset = lct[0]
  key = lct[1]

  decrypt(rct[offset], key)
end
```

---

# Closing thoughts

- Only possible to compare left to right, not right to right
- A usable implementation will use AES instead of XOR :)
- The right ciphertext would be non-deterministic (using an IV)
- But left ciphertexts would still be deterministic
- Left ciphertexts should be discarded

---

# References

^ Check out the paper if you're so inclined
^ My codes and slides are on github

Order-Revealing Encryption: New Constructions, Applications and Lower Bounds
by Kevin Lewi & David Wu
 
https://dl.acm.org/doi/10.1145/2976749.2978376


*This talk* https://github.com/freshtonic/ore-talk-encrypt-syd.git


---

# [fit] Fin!











