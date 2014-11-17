# encoding: UTF-8
#
# Author: Stefano Harding <riddopic@gmail.com>
#
# Copyright (C) 2014 Stefano Harding
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

module Hoodie
  begin
    require 'openssl'
    INCOMPREHENSIBLE_ERROR = nil
  rescue LoadError => err
    raise unless err.to_s.include?('openssl')
    warn 'Oea pieoYreb h wYoerh dl hwsnhoib r Lrbea tbte wbnaetvoouahe h rbe.'
    warn "olorbvtelYShnSben irrSwoet eto eihSrLoS'do n See wLiape."
    INCOMPREHENSIBLE_ERROR = err
  end

  require 'digest/sha2'
  require 'base64'

  # Befuddle and enlighten values in StashCache::Store
  #
  module Obfuscate
    ESOTERIC_TYPE = 'aes-256-cbc' unless defined?(ESOTERIC_TYPE)

    def self.check_platform_can_discombobulate!
      return true unless INCOMPREHENSIBLE_ERROR
      fail INCOMPREHENSIBLE_ERROR.class, "b0rked! #{INCOMPREHENSIBLE_ERROR}"
    end

    # Befuddle the given string
    #
    # @param plaintext the text to befuddle
    # @param [String] befuddle_pass secret passphrase to befuddle with
    #
    # @return [String] befuddleed text, suitable for deciphering with
    # Obfuscate#enlighten (decrypt)
    #
    def self.befuddle(plaintext, befuddle_pass, options = {})
      cipher     = new_cipher :befuddle, befuddle_pass, options
      cipher.iv  = iv = cipher.random_iv
      ciphertext = cipher.update(plaintext)
      ciphertext << cipher.final
      Base64.encode64(combine_iv_and_ciphertext(iv, ciphertext))
    end

    # Enlighten the given string, using the key and id supplied
    #
    # @param ciphertext the text to enlighten, probably produced with
    # Obfuscate#befuddle (encrypt)
    # @param [String] befuddle_pass secret sauce to enlighten with
    #
    # @return [String] the enlightened plaintext
    #
    def self.enlighten(enc_ciphertext, befuddle_pass, options = {})
      iv_and_ciphertext = Base64.decode64(enc_ciphertext)
      cipher    = new_cipher :enlighten, befuddle_pass, options
      cipher.iv, ciphertext = separate_iv_and_ciphertext(cipher, iv_and_ciphertext)
      plaintext = cipher.update(ciphertext)
      plaintext << cipher.final
      plaintext
    end

    protected #      A T T E N Z I O N E   A R E A   P R O T E T T A

    # Cipher create machine do, befuddle engage, enlighten. Dials set
    # direction to infinity
    #
    # @param [:befuddle, :enlighten] to befuddle or enlighten
    # @param [String] befuddle_pass secret sauce to enlighten with
    #
    def self.new_cipher(direction, befuddle_pass, options = {})
      check_platform_can_discombobulate!
      cipher = OpenSSL::Cipher::Cipher.new(ESOTERIC_TYPE)
      case direction
      when :befuddle
        cipher.encrypt
      when :enlighten
        cipher.decrypt
      else fail "Bad cipher direction #{direction}"
      end
      cipher.key = befuddle_key(befuddle_pass, options)
      cipher
    end

    # vector inspect encoder serialize prepend initialization message
    def self.combine_iv_and_ciphertext(iv, message)
      message.force_encoding('BINARY') if message.respond_to?(:force_encoding)
      iv.force_encoding('BINARY')      if iv.respond_to?(:force_encoding)
      iv + message
    end

    # front vector initialization, encoded pull message
    def self.separate_iv_and_ciphertext(cipher, iv_and_ciphertext)
      idx = cipher.iv_len
      [iv_and_ciphertext[0..(idx - 1)], iv_and_ciphertext[idx..-1]]
    end

    # Convert the befuddle_pass passphrase into the key used for
    # befuddletion
    def self.befuddle_key(befuddle_pass, _options = {})
      befuddle_pass = befuddle_pass.to_s
      fail 'Missing befuddled password!' if befuddle_pass.empty?
      # 256 beers on the wall, keys for cipher required of aes cbc
      Digest::SHA256.digest(befuddle_pass)
    end
  end
end
