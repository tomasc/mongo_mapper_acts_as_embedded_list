module MongoMapper
  module Plugins
    module ActsAsEmbeddedList

      require 'mongo_mapper'


  
      module ClassMethods
	      include Comparable
	      
        def acts_as_embedded_list(options = {})
          configuration = { :column => "position" }.merge(options)

          define_method 'position_column' do
            configuration[:column].to_s
          end
          
          key configuration[:column].to_sym, Integer
          
          before_save :add_to_list_bottom
        end
    
      end



      module InstanceMethods
        
        def <=>(another_item)
          self.send(position_column).to_i <=> another_item.send(position_column).to_i
        end
        
        def list_reference
          # FIXME this should be determined automatically or passed
          _parent_document.embedded_list_items.sort
        end
        
        
        
        
        def insert_at(position = 1)
          insert_at_position(position)
        end        
        
        def move_lower
          return unless lower_item
          lower_item.decrement_position
          increment_position
        end
        
        def move_higher
          return unless higher_item
          higher_item.increment_position
          decrement_position
        end
        
        def move_to_bottom
          return unless in_list?
          decrement_positions_on_lower_items
          assume_bottom_position
        end
        
        def move_to_top
          return unless in_list?
          increment_positions_on_higher_items
          assume_top_position
        end
        
        def remove_from_list
          decrement_positions_on_lower_items
          self[position_column] = nil
        end
        
        def decrement_position
          return unless in_list?
          self[position_column] = self.send(position_column)-1
        end
        
        def increment_position
          return unless in_list?
          self[position_column] = self.send(position_column)+1
        end
        
        def first?
          return false unless in_list?
          self.send(position_column) == 1
        end
        
        def last?
          return false unless in_list?
          self.send(position_column) == bottom_position_in_list
        end        
                
        def lower_item
          return nil unless in_list?
          list_reference.select(&:in_list?).detect{ |i| i.send(position_column) == self.send(position_column)+1 }
        end
        
        def higher_item
          return nil unless in_list?
          list_reference.select(&:in_list?).detect{ |i| i.send(position_column) == self.send(position_column)-1 }
        end
        
        def in_list?
          !self.send(position_column).nil?
        end                
        
        private
        
        def add_to_list_top
          increment_positions_on_all_items
          assume_top_position
        end
        
        def add_to_list_bottom
          return self.send(position_column) if in_list?
          self[position_column] = bottom_position_in_list.to_i+1
        end
        
        def bottom_position_in_list(except=nil)
          item = bottom_item(except)
          item ? item.send(position_column) : 0
        end        
        
        def bottom_item(except=nil)
          list_reference.select(&:in_list?).reject{|i|i==except}.last
        end
        
        def assume_bottom_position
          self[position_column] = bottom_position_in_list(self).to_i+1
        end
        
        def assume_top_position
          self[position_column] = 1
        end        
        
        def decrement_positions_on_higher_items(position)
          list_reference.select(&:in_list?).select{ |i| i.send(position_column) <= position }.each{ |i| i.decrement_position }
        end        
        
        def decrement_positions_on_lower_items
          return unless in_list?
          list_reference.select(&:in_list?).select{ |i| i.send(position_column) > self.send(position_column) }.each{ |i| i.decrement_position }
        end
                
        def increment_positions_on_higher_items
          return unless in_list?
          list_reference.select(&:in_list?).select{ |i| i.send(position_column) < self.send(position_column) }.each{ |i| i.increment_position }
        end
        
        def increment_positions_on_lower_items(position)
          list_reference.select(&:in_list?).select{ |i| i.send(position_column) >= position }.each{ |i| i.increment_position }
        end                
                        
        def increment_positions_on_all_items
          list_reference.select(&:in_list?).each{ |i| i.increment_position }
        end
                
        def insert_at_position(position)
          remove_from_list
          increment_positions_on_lower_items( position )
          self[position_column] = position
        end
        
      end

    end
  end
end
