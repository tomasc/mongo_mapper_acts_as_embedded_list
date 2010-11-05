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
    (1..4).each{ |counter| @list_root.embedded_list_items.build(:pos => counter, :original_id => counter) }
  end
  
  def test_position_column
    assert_equal @list_root.embedded_list_items.first.position_column, "pos"
  end
  
  def test_presence
    assert_equal @list_root.embedded_list_items.count, 4
  end
  
  def test_positions
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
  
  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1,2,3,4], embedded_list_items_ids
    embedded_list_item(3).move_to_bottom
    assert_equal [1,2,4,3], embedded_list_items_ids
  end
  
  def test_next_prev
    assert_equal embedded_list_item(2), embedded_list_item(1).lower_item
    assert_nil embedded_list_item(1).higher_item
    assert_equal embedded_list_item(3), embedded_list_item(4).higher_item
    assert_nil embedded_list_item(4).lower_item
  end
  
  def test_insert
    new5 = @list_root.embedded_list_items.build(:original_id => 5)
    new5.add_to_list_bottom # FIXME this should be called automatically
    assert_equal 5, new5.pos
    assert !new5.first?
    assert new5.last?
    
    new6 = @list_root.embedded_list_items.build(:original_id => 6)
    new6.add_to_list_bottom # FIXME this should be called automatically
    assert_equal 6, new6.pos
    assert !new6.first?
    assert new6.last?
  end
  
  def test_insert_at
    assert_equal [1,2,3,4], embedded_list_items_ids
    
    embedded_list_item(4).insert_at(3)
    assert_equal 3, embedded_list_item(4).pos
    assert_equal [1,2,4,3], embedded_list_items_ids
    
    embedded_list_item(3).insert_at(2)
    assert_equal 2, embedded_list_item(3).pos
    assert_equal [1,3,2,4], embedded_list_items_ids
    
    embedded_list_item(4).insert_at(1)
    assert_equal 1, embedded_list_item(4).pos
    assert_equal [4,1,3,2], embedded_list_items_ids
    
    embedded_list_item(1).insert_at(4)
    assert_equal 4, embedded_list_item(1).pos
    assert_equal [4,3,2,1], embedded_list_items_ids
  end
  
  def test_delete_middle
    assert_equal [1,2,3,4], embedded_list_items_ids

    embedded_list_item(2).remove_from_list # FIXME this sould be called automatically
    @list_root.embedded_list_items.delete( embedded_list_item(2) ) 
    
    assert_equal [1,3,4], embedded_list_items_ids
    
    assert_equal 1, embedded_list_item(1).pos
    assert_equal 2, embedded_list_item(3).pos
    assert_equal 3, embedded_list_item(4).pos
    
    embedded_list_item(1).remove_from_list # FIXME this sould be called automatically
    @list_root.embedded_list_items.delete( embedded_list_item(1) )
    
    assert_equal [3,4], embedded_list_items_ids

    assert_equal 1, embedded_list_item(3).pos
    assert_equal 2, embedded_list_item(4).pos
  end
  
  def test_remove_from_list_should_then_fail_in_list? 
    assert embedded_list_item(1).in_list?
    embedded_list_item(1).remove_from_list
    assert !embedded_list_item(1).in_list?
  end
  
  def test_remove_from_list_should_set_position_to_nil 
    assert_equal [1,2,3,4], embedded_list_items_ids

    embedded_list_item(2).remove_from_list 

    assert_equal [2,1,3,4], embedded_list_items_ids

    assert_equal 1,   embedded_list_item(1).pos
    assert_equal nil, embedded_list_item(2).pos
    assert_equal 2,   embedded_list_item(3).pos
    assert_equal 3,   embedded_list_item(4).pos
  end
  
end



# POSITION ASSIGNMENT TEST

class PositionAssignmentTest < ActiveSupport::TestCase
  
  def setup
    @list_root = ListRoot.new
    (1..4).each{ |counter| @list_root.embedded_list_items.build(:original_id => counter) }
    @list_root.save
  end
  
  def test_presence
    assert_equal @list_root.embedded_list_items.count, 4
  end
  
  def test_assigned_positions
    assert_equal [1,2,3,4], @list_root.embedded_list_items.sort.map(&:pos)
    assert_equal [1,2,3,4], embedded_list_items_ids
  end
  
end
