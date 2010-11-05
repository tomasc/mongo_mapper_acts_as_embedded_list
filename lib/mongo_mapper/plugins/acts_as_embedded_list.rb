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
        end
    
      end



      module InstanceMethods
        
        def <=>(another_item)
          self.send(position_column).to_i <=> another_item.send(position_column).to_i
        end
        
        def list_reference
          _parent_document.embedded_list_items.sort
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
          decrement_positions_on_lower_items
          assume_bottom_position
        end
        
        def move_to_top
          increment_positions_on_higher_items
          assume_top_position
        end
        
        def lower_item
          list_reference.detect{ |i| i.send(position_column) == self.send(position_column)+1 }
        end
        
        def higher_item
          list_reference.detect{ |i| i.send(position_column) == self.send(position_column)-1 }
        end
        
        def decrement_position
          self[position_column] = self.send(position_column)-1
        end
        
        def increment_position
          self[position_column] = self.send(position_column)+1
        end
        
        def decrement_positions_on_lower_items
          list_reference.select{ |i| i.send(position_column) > self.send(position_column) }.each{ |i| i.decrement_position }
        end
        
        def increment_positions_on_higher_items
          list_reference.select{ |i| i.send(position_column) < self.send(position_column) }.each{ |i| i.increment_position }
        end
        
        def assume_bottom_position
          self[position_column] = bottom_position_in_list(self).to_i+1
        end
        
        def assume_top_position
          self[position_column] = 1
        end
        
        def bottom_position_in_list(except=nil)
          item = bottom_item(except)
          item ? item.send(position_column) : 0
        end
        
        def bottom_item(except=nil)
          list_reference.reject{|i|i==except}.last
        end
        
      end

    end
  end
end
