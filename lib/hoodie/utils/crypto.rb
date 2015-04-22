# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'
require 'digest/sha2'
require 'base64'
require 'securerandom'

module Hoodie
  # Crypto uses the AES-256-CBC algorithm by default to encrypt strings
  # securely. It uses both an initialization vector (IV) and a salt to perform
  # this encryption as securely as possible.
  #
  # @example
  #   Use `#encrypt` to encrypt a string.
  #     text = "what is 42?"
  #     salt = "9e5f851900cad8892ac8b737b7370cbe"
  #     pass = "!mWh0!s@y!m"
  #     encrypted_text = Crypto.encrypt(text, set_password, set_salt)
  #       # => "+opVpqJhQsD3dbOQ8GAGjmq7slIms2zCQmOrMxJGpqQ=\n"
  #
  #   Then to decrypt the string use `#decrypt`.
  #     Crypto.decrypt(encrypted_text, pass, salt)
  #       # => "what is 42?"
  #
  #   You can also set the salt and password on a configuration object.
  #     Hoodie::Crypto.config do |config|
  #       config.password = "!mWh0!s@y!m"
  #       config.salt     = "9e5f851900cad8892ac8b737b7370cbe"
  #     end
  #
  #   Now you can #encrypt and #decrypt without specifying a salt and password.
  #     encrypted_text = Crypto.encrypt(text)
  #       # => "HQRabUG8BcS+yZR8yG9TqQWfFPFYXztRgoQjdAUseFU=\n"
  #     Crypto.decrypt(encrypted_text)
  #       # => "what is 42?"
  #
  #   What you probably want to use this for is directly on a String.
  #     encrypted_text = text.encrypt
  #       # => "ew2SEyf+09WdPJHRjmBGp4g6C1oSQaDbQiZ/7WEceEc=\n"
  #     encrypted_text.decrypt
  #       # => "what is 42?"
  #
  # @note
  #   The salt needs to be unique per-use per-encrypted string. Every time a
  #   string is encrypted, it should be hashed using a new random salt. Never
  #   reuse a salt. The salt also needs to be long, so that there are many
  #   possible salts. As a rule of thumb, the salt should be at least 32 random
  #   bytes. Hoodie includes a easy helper for you to generate a random binary
  #   string, `String.random_binary(SIZE)`, where size  is the size in bytes.
  #
  module Crypto
    extend self

    # Adds `encrypt` and `decrypt` methods to strings.
    #
    module String
      # Returns a new string containing the encrypted version of itself
      #
      def encrypt(password = nil, salt = nil)
        Hoodie::Crypto.encrypt(self, password, salt)
      end

      # Returns a new string containing the decrypted version of itself
      #
      def decrypt(password = nil, salt = nil)
        Hoodie::Crypto.decrypt(self, password, salt)
      end

      # Generate a random binary string of +n_bytes+ size.
      #
      def random_binary(n_bytes)
        #(Array.new(n_bytes) { rand(0x100) }).pack('c*')
        SecureRandom.random_bytes(64)
      end
    end

    # A Configuration instance
    class Configuration

      # @!attribute [rw] :password
      #   @return [String] access the password for this instance.
      attr_accessor :password

      # @!attribute [rw] :salt
      #   @return [String] access the salt for this instance.
      attr_accessor :salt

      # Initialized a configuration instance
      #
      # @return [undefined]
      #
      # @api private
      def initialize(options = {})
        @password = options.fetch(:password, nil)
        @salt     = options.fetch(:salt,     nil)

        yield self if block_given?
      end

      # @api private
      def to_h
        { password: password, salt: salt }.freeze
      end
    end

    # The default size, iterations and cipher encryption algorithm used.
    SALT_BYTE_SIZE = 64
    HASH_BYTE_SIZE = 256
    CRYPTERATIONS  = 4096
    CIPHER_TYPE    = 'aes-256-cbc'

    # Encrypt the given string using the AES-256-CBC algorithm.
    #
    # @param [String] plain_text
    #   The text to encrypt.
    #
    # @param [String] password
    #   Secret passphrase to encrypt with.
    #
    # @param [String] salt
    #   A cryptographically secure pseudo-random string (SecureRandom.base64)
    #   to add a little spice to your encryption.
    #
    # @return [String]
    #   Encrypted text, can be deciphered with #decrypt.
    #
    # @api public
    def encrypt(plain_text, password = nil, salt = nil)
      password = password.nil? ? Hoodie.crypto.password : password
      salt     = salt.nil?     ? Hoodie.crypto.salt     : salt

      cipher      = new_cipher(:encrypt, password, salt)
      cipher.iv   = iv = cipher.random_iv
      ciphertext  = cipher.update(plain_text)
      ciphertext << cipher.final
      Base64.encode64(combine_iv_ciphertext(iv, ciphertext))
    end

    # Decrypt the given string, using the salt and password supplied.
    #
    # @param [String] encrypted_text
    #   The text to decrypt, probably produced with #decrypt.
    #
    # @param [String] password
    #   Secret passphrase to decrypt with.
    #
    # @param [String] salt
    #   The cryptographically secure pseudo-random string used to spice up the
    #   encryption of your strings.
    #
    # @return [String]
    #   The decrypted plain_text.
    #
    # @api public
    def decrypt(encrypted_text, password = nil, salt = nil)
      password = password.nil? ? Hoodie.crypto.password : password
      salt     = salt.nil?     ? Hoodie.crypto.salt     : salt

      iv_ciphertext = Base64.decode64(encrypted_text)
      cipher        = new_cipher(:decrypt, password, salt)
      cipher.iv, ciphertext = separate_iv_ciphertext(cipher, iv_ciphertext)
      plain_text    = cipher.update(ciphertext)
      plain_text   << cipher.final
      plain_text
    end

    # Generates a special hash known as a SPASH, a PBKDF2-HMAC-SHA1 Salted
    # Password Hash for safekeeping.
    #
    # @param [String] password
    #   A password to generating the SPASH, salted password hash.
    #
    # @return [Hash]
    #   `:salt` contains the unique salt used, `:pbkdf2` contains the password
    #   hash. Save both the salt and the hash together.
    #
    # @see Hoodie::Crypto#validate_salt
    #
    # @api public
    def salted_hash(password)
      salt   = SecureRandom.random_bytes(SALT_BYTE_SIZE)
      pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
                 password,
                 salt,
                 CRYPTERATIONS,
                 HASH_BYTE_SIZE)

      { salt: salt, pbkdf2: Base64.encode64(pbkdf2) }
    end

    private #        P R O P R I E T À   P R I V A T A   Vietato L'accesso

    # Validates a salted PBKDF2-HMAC-SHA1 hash of a password.
    #
    # @param [String] password
    #   The password used to create the SPASH, salted password hash.
    #
    # @param opts [Hash]
    #
    # @option opts [String] :salt
    #   The salt used in generating the SPASH, salted password hash.
    #
    # @option opts [String] :hash
    #   The hash produced when salt and password collided in a algorithm of
    #   PBKDF2-HMAC-SHA1 love bites (do you tell lies?) hash.
    #
    # @return [Boolean]
    #   True if the password is a match, false if ménage à trois of salt, hash
    #   and password don't mix.
    #
    # @see Hoodie::Crypto#salted_hash
    #
    # @api private
    def validate_salt(password, hash = {})
      pbkdf2 = Base64.decode64(hash[:pbkdf2])
      salty  = OpenSSL::PKCS5::pbkdf2_hmac_sha1(
                 password,
                 hash[:salt],
                 CRYPTERATIONS,
                 HASH_BYTE_SIZE)
      pbkdf2 == salty
    end

    protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

    # Create a new cipher machine, with its dials set in the given direction.
    #
    # @param [Symbol] direction
    #   Whether to `:encrypt` or `:decrypt`.
    #
    # @param [String] pass
    #   Secret passphrase to decrypt with.
    #
    # @api private
    def new_cipher(direction, password, salt)
      cipher = OpenSSL::Cipher::Cipher.new(CIPHER_TYPE)
      direction == :encrypt ? cipher.encrypt : cipher.decrypt
      cipher.key = encrypt_key(password, salt)
      cipher
    end

    # Prepend the initialization vector to the encoded message.
    #
    # @api private
    def combine_iv_ciphertext(iv, message)
      message.force_encoding('BINARY') if message.respond_to?(:force_encoding)
      iv.force_encoding('BINARY')      if iv.respond_to?(:force_encoding)
      iv + message
    end

    # Pull the initialization vector from the front of the encoded message.
    #
    # @api private
    def separate_iv_ciphertext(cipher, iv_ciphertext)
      idx = cipher.iv_len
      [iv_ciphertext[0..(idx - 1)], iv_ciphertext[idx..-1]]
    end

    # Convert the password into a PBKDF2-HMAC-SHA1 salted key used for safely
    # encrypting and decrypting all your ciphers strings.
    #
    # @api private
    def encrypt_key(password, salt)
      iterations, length = CRYPTERATIONS, HASH_BYTE_SIZE
      OpenSSL::PKCS5::pbkdf2_hmac_sha1(password, salt, iterations, length)
    end
  end
end

# Adds `encrypt` and `decrypt` methods to strings.
String.send(:include, Hoodie::Crypto::String)
