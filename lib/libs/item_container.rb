module RbParser
  module ItemContainer
    module ClassMethods
      @@item_count = 0

      def class_info
        "Class: #{name}, Version: 1.0"
      end

      def increment_item_count
        @@item_count += 1
      end

      def item_count
        @@item_count
      end
    end

    module InstanceMethods
      def add_item(item)
        @items << item
        self.class.increment_item_count
        LoggerManager.log_info("Item added: #{item}")
      end

      def remove_item(item)
        @items.delete(item)
        LoggerManager.log_info("Item removed: #{item}")
      end

      def delete_items
        @items.clear
        LoggerManager.log_info("All items deleted from the cart")
      end

      def method_missing(method_name, *args, &block)
        if method_name == :show_all_items
          LoggerManager.log_info("Showing all items in the cart")
          @items.each { |item| puts item }
        else
          super
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end
  end
end