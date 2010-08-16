require 'ostruct'

class RecordChange < Object
  attr_reader :attributes, :associations
  # TODO: create an option to specify which attributes are tracked
  
  def initialize(object, opts={:new_record? => false})    
    if opts[:new_record?]   # for newly created records, we just record everything
      @attributes = object.attributes.map do |arr|
        unless arr[1].blank? # don't record anything for blank values
        # TODO: create an option to track blank values
          OpenStruct.new({    
            :name => arr[0],
            :old  => '',
            :new  => arr[1]
          })
        end
      end.compact    

      @associations = object.dirty_associations.map do |one_association|  
        added = object.send(one_association)
        added = [added] unless added.respond_to?(:join)   # turn it into an array unless it's a collection (deal with has_one)

        unless added.empty?
          OpenStruct.new({ 
            :name => one_association, 
            :added => added, 
            :removed => ''
          }) 
        end
      end.compact
      
      nil
    else                    # for changed records, we need to compare against the previous version    
      # attributes are easy, using ActiveRecord's Dirty Module's `changes` method
      @attributes = object.changes.map do |k,v|
        # person.changes    #=> { 'name' => ['Bill', 'bob'] }      
        OpenStruct.new({    
          :name => k,
          :old  => v[0],
          :new  => v[1]
        })
      end

      # associations are trickier, relying on the dirty_associations plugin
      @associations = object.dirty_associations.map do |one_association|
        if object.send("#{one_association}_changed?")
          association_ids = object.send("#{one_association.to_s.chop}_ids_added")

          # don't use dirty_association's collection_added method because we are working with a cloned object here
          association_class = object.class.reflect_on_association(one_association).klass
          added = association_class.find association_ids

          removed = object.send("#{one_association}_removed")
          OpenStruct.new({ 
            :name => one_association, 
            :added => added, 
            :removed => removed
          })
        end
      end.compact
    end
  end
  
  def attributes_to_s(separator="<br />")
    returner = attributes.map do |a|
      "'#{a.name}' changed from '#{a.old}' to '#{a.new}'"
    end.join(separator) || ''
    
    returner.blank? ? 'No attributes changed' : "Changed attributes: #{returner}"
  end
  
  def associations_to_s(separator="<br />")
    returner = associations.map do |a|
      added_text = a.added.blank? ? 'none added' : 'added ' + a.added.join(', ')
      removed_text = a.removed.blank? ? 'none removed' : 'removed ' + a.removed.join(', ')
      "'#{a.name.to_s.titleize}' - #{separator} #{added_text} #{separator} #{removed_text}"
    end.join(separator) || ''
    
    returner.blank? ? 'No associations changed' : "Changed associations: #{returner}"    
  end
  
  def to_s(opts={:separator=>"<br />"})
    attributes_to_s + opts[:separator] + associations_to_s
  end
end