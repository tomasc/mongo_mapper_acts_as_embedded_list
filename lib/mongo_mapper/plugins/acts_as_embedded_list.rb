module MongoMapper
	module Plugins
		module ActsAsEmbeddedList

			require 'mongo_mapper'
  
		  module ClassMethods
				def acts_as_embedded_list(options = {})
					configuration = { :column => "position", :scope => {} }
					configuration.update(options) if options.is_a?(Hash)
					
					# TODO if no scope specified, we can derive it from class name
					
				# 	configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/
				# 			
				# 	if configuration[:scope].is_a?(Symbol)
				# 		scope_condition_method = %(
				#               def scope_condition
				#                 { "#{configuration[:scope].to_s}" => send(:#{configuration[:scope].to_s}) }.symbolize_keys!
				#               end
				#             )
				# 	elsif configuration[:scope].is_a?(Array)
				# 		scope_condition_method = %(
				#               def scope_condition
				#                 attrs = %w(#{configuration[:scope].join(" ")}).inject({}) do |memo, column| 
				#                   memo[column.intern] = send(column.intern)
				# 					memo
				#                 end
				# 				attrs.symbolize_keys!
				#               end
				#             )
				# 	else
				# 		scope_condition_method = "def scope_condition() \"#{configuration[:scope]}\" end"
				# 	end
							
					class_eval <<-EOV
	          include MongoMapper::Plugins::ActsAsEmbeddedList::InstanceMethods

						def list_reference # TODO maybe better method name?
							_parent_document.embedded_list_items # TODO this needs to be based on scope!
						end

	          def position_column
	            '#{configuration[:column]}'
            end
          EOV
				end
		
		  end



		  module InstanceMethods
				# Insert the item at the given position (defaults to the top position of 1).
		    def insert_at(position = 1)
		      insert_at_position(position)
		    end
						
				# Swap positions with the next lower item, if one exists.
				def move_lower
					return unless lower_item
					lower_item.decrement_position
					increment_position
				end
							
		    # Swap positions with the next higher item, if one exists.
		    def move_higher
		      return unless higher_item
		      higher_item.increment_position
		      decrement_position
		    end
						
		    # Move to the bottom of the list. If the item is already in the list, the items below it have their
		    # position adjusted accordingly.
		    def move_to_bottom
		      return unless in_list?
		      decrement_positions_on_lower_items
		      assume_bottom_position
		    end
						
		    # Move to the top of the list. If the item is already in the list, the items above it have their
		    # position adjusted accordingly.
		    def move_to_top
		      return unless in_list?
		      increment_positions_on_higher_items
		      assume_top_position
		    end
		
				def update_position(value=nil)
					# FIXME this should be replaced by partial update
					self[position_column] = value
					_root_document.save!
				end

				# Removes the item from the list.
				def remove_from_list
					if in_list?
						decrement_positions_on_lower_items
						update_position( nil )
					end
				end

		    # Increase the position of this item without adjusting the rest of the list.
		    def increment_position
		      return unless in_list?
					update_position( self.send(position_column).to_i+1 )
		    end
						
		    # Decrease the position of this item without adjusting the rest of the list.
		    def decrement_position
		      return unless in_list?
					update_position( self.send(position_column).to_i-1 )
		    end
						
				# Return +true+ if this object is the first in the list.
				def first?
					return false unless in_list?
					self.send(position_column) == 1
				end
				
				# Return +true+ if this object is the last in the list.
				def last?
				  return false unless in_list?
				  self.send(position_column) == bottom_position_in_list
				end

        # Return the next higher item in the list.
        def higher_item
          return nil unless in_list?
					list_reference.detect{ |i| i[position_column] == send(position_column).to_i-1 }
        end
				
				# Return the next lower item in the list.
				def lower_item
					return nil unless in_list?					
					list_reference.detect{ |i| i[position_column] == send(position_column).to_i+1 }
				end
				
				# Test if this record is in a list
        def in_list?
          !send(position_column).nil?
        end
				
				# private

				def add_to_list_top
					increment_positions_on_all_items
				end

				def add_to_list_bottom
					self[position_column] = bottom_position_in_list.to_i+1
				end

				# def scope_condition() "1" end
					
				# Returns the bottom position number in the list.
				#   bottom_position_in_list    # => 2
				def bottom_position_in_list(except = nil)
					item = bottom_item(except)
					item ? item.send(position_column) : 0
				end
				
				# Returns the bottom item
				def bottom_item(except = nil)
					list_reference.select{ |i| i.id != except }.sort_by{ |i| i.send(position_column) }.last
				end
				
				# Forces item to assume the bottom position in the list.
				def assume_bottom_position
					update_position( bottom_position_in_list(self).to_i+1 )
				end
				
				# Forces item to assume the top position in the list.
				def assume_top_position
					update_position 1
				end
				
				# This has the effect of moving all the higher items up one.
				def decrement_positions_on_higher_items(position)
					list_reference.select{ |i| i[position_column] < position }.each do |i|
						i.update_position( i.send(position_column).to_i-1 )
					end
				end
				
				# This has the effect of moving all the lower items up one.
				def decrement_positions_on_lower_items
					return unless in_list?
					list_reference.select{ |i| i[position_column] > send(position_column).to_i }.each do |i|
						i.update_position( i.send(position_column).to_i-1 )
					end
				end				
					
				# This has the effect of moving all the higher items down one.
				def increment_positions_on_higher_items
					return unless in_list?
					list_reference.select{ |i| i[position_column] < send(position_column).to_i }.each do |i|
						i.update_position( i.send(position_column).to_i+1 )
					end
				end

				# This has the effect of moving all the lower items down one.
				def increment_positions_on_lower_items(position)
					list_reference.select{ |i| i[position_column] > position }.each do |i|
						i.update_position( i.send(position_column).to_i+1 )
					end
				end
				
        # Increments position (<tt>position_column</tt>) of all items in the list.
				def increment_positions_on_all_items
					list_reference.each do |i|
						i.update_position( i.send(position_column).to_i+1 )
					end
				end
				
        def insert_at_position(position)
					remove_from_list
					increment_positions_on_lower_items( position )
					update_position( position )
        end

		  end

		end
	end
end
