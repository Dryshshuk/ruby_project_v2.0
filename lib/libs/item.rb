require 'faker'
require_relative '../libs/logger_manager'

module RbParser
  class Item
    include Comparable

    attr_accessor :title, :price, :subtitle, :image_url

    def initialize(params = {})
      @title = params[:title] || "Unknown Title"
      @price = params[:price] || 0.0
      @image_url = params[:image_url] || "default.jpg"

      LoggerManager.log_processed_file("Item initialized: #{self}")

      yield(self) if block_given?
    end

    def <=>(other)
      price <=> other.price
    end

    def to_s
      "#{self.class.name} - #{instance_variables.map { |attr| "#{attr.to_s.delete('@')}: #{instance_variable_get(attr)}" }.join(', ')}"
    end

    def to_h
      instance_variables.each_with_object({}) do |attr, hash|
        hash[attr.to_s.delete('@').to_sym] = instance_variable_get(attr)
      end
    end

    def inspect
      "<#{self.class}: #{to_h}>"
    end

    alias_method :info, :to_s

    def update
      yield(self) if block_given?
    end

    def self.generate_fake
      begin
        new(
          title: Faker::Commerce.product_name,
          price: Faker::Commerce.price(range: 10..1000.0),
          image_url: "#{Faker::Lorem.word}.jpg"
        )
      rescue StandardError => e
        LoggerManager.log_error("Error generating fake item: #{e.message}")
        new(
          title: "Generated Item",
          price: 0.0,
          image_url: "default.jpg"
        )
      end
    end
  end
end
