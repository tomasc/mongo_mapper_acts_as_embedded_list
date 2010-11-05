require 'test_helper'



# CLASS SETUP

class ListRoot
  include MongoMapper::Document
  many :embedded_list_items
end

class EmbeddedListItem
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::Plugins::ActsAsEmbeddedList
  key :original_id, Integer
  acts_as_embedded_list :column => :pos
end



# HELPER METHODS

class ActiveSupport::TestCase

	private

	def embedded_list_items_ids
		@list_root.embedded_list_items.sort.map(&:original_id)
	end

	def embedded_list_item(original_id)
		@list_root.embedded_list_items.detect{ |i| i.original_id == original_id }
	end

end



# LIST TEST

class ListTest < ActiveSupport::TestCase
  
  def setup
    @list_root = ListRoot.new
    (1..4).each do |counter| 
      @list_root.embedded_list_items.build(:pos => counter, :original_id => counter)
    end
    # @list_root.save
  end
  
  def test_position_column
    assert_equal @list_root.embedded_list_items.first.position_column, "pos"
  end
  
  def test_presence
    assert_equal @list_root.embedded_list_items.count, 4
  end
  
  def test_positions_on_save
    assert_equal [1,2,3,4], @list_root.embedded_list_items.sort.map(&:pos)
    assert_equal [1,2,3,4], embedded_list_items_ids
  end
  
  def test_reordering
    assert_equal [1,2,3,4], embedded_list_items_ids
    
    embedded_list_item(2).move_lower
    assert_equal [1,3,2,4], embedded_list_items_ids

    embedded_list_item(2).move_higher
    assert_equal [1,2,3,4], embedded_list_items_ids
    
    embedded_list_item(1).move_to_bottom
    assert_equal [2,3,4,1], embedded_list_items_ids
    
    embedded_list_item(1).move_to_top
    assert_equal [1,2,3,4], embedded_list_items_ids
    
    embedded_list_item(2).move_to_bottom
    assert_equal [1,3,4,2], embedded_list_items_ids

    embedded_list_item(4).move_to_top
    assert_equal [4,1,3,2], embedded_list_items_ids
  end
  
end