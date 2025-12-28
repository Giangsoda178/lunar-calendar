# frozen_string_literal: true

require "nanoid"

module IdGenerator
  extend ActiveSupport::Concern

  included do
    before_create :set_id
  end

  ID_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  ID_LENGTH = 8
  MAX_RETRY = 1000

  ID_REGEX = /[#{ID_ALPHABET}]{#{ID_LENGTH}}\z/

  class_methods do
    def generate_nanoid(alphabet: ID_ALPHABET, size: ID_LENGTH)
      Nanoid.generate(size: size, alphabet: alphabet)
    end
  end
  def generate_id
    self.class.generate_nanoid(alphabet: ID_ALPHABET)
  end

  def set_id
    return if id.present?

    MAX_RETRY.times do
      self.id = generate_id
      return unless self.class.exists?(id: id)
    end
    raise "Failed to generate unique ID after #{MAX_RETRY} attempts"
  end
end
