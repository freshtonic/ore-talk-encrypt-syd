
def encrypt(plaintext, key)
  plaintext ^ key
end

def decrypt(ciphertext, key)
  ciphertext ^ key
end

def compare_to_all(plaintext)
  (0..255).map do |other|
    other <=> plaintext
  end
end

def generate_keys
  (0..255).map { rand(0..255) }
end

def generate_prp
  (0..255).to_a.shuffle
end

def encrypt_with_keys(comparisons, keys)
  comparisons.each_with_index.map do |c, index|
    encrypt(c, keys[index])
  end
end

def right_ciphertext(encryptions)
  encryptions.pack("C*").unpack("H*").first
end

def read_right_ciphertext(hex_string)
  [hex_string].pack("H*").unpack("C*")
end

def left_ciphertext(key, offset)
  [offset, key].pack("C*").unpack("H*").first
end

def read_left_ciphertext(hex_string)
  [hex_string].pack("H*").unpack("C*")
end

def shuffle(prp, array)
  prp.map{ |idx| array[idx] }
end

def encrypt_plaintext(keys, prp, plaintext)
  comparisons = compare_to_all(plaintext)
  encryptions = encrypt_with_keys(comparisons, keys)
  shuffled_encryptions = shuffle(prp, encryptions)
  [
    left_ciphertext(keys[plaintext], prp[plaintext]),
    right_ciphertext(shuffled_encryptions)
  ]
end

def compare(left_ciphertext, right_ciphertext)
  lct = read_left_ciphertext(left_ciphertext)
  rct = read_right_ciphertext(right_ciphertext)

  offset = lct[0]
  key = lct[1]

  decrypt(rct[offset], key)
end

