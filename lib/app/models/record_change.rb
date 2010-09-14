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

      # @associations = object.associations.map do |assoc_name, assoc_obj|  
      #   added = object.send(assoc_name)
      #   added = [added] unless added.respond_to?(:join)   # turn it into an array unless it's a collection (deal with has_one)
      #   added.map!{ |a| OpenStruct.new({:id => a.id, :to_ess => a.to_s}) }
      # 
      #   unless added.empty?
      #     OpenStruct.new({ 
      #       :name => assoc_name, 
      #       :added => added, 
      #       :removed => ''
      #     }) 
      #   end
      # end.compact
      
      nil
    else                    
      # for changed records, we need to compare against the previous version    
      # attributes are easy, using ActiveRecord's Dirty Module's `changes` method
      @attributes = object.changes.map do |k,v|
        # person.changes    #=> { 'name' => ['Bill', 'bob'] }      
        OpenStruct.new({    
          :name => k,
          :old  => v[0],
          :new  => v[1]
        })
      end

      # associations are trickier
      # @associations = object.associations.map do |assoc_name, assoc_obj|
      #   if object.send("#{assoc_name}_changed?")
      #     association_ids = object.send("#{assoc_name.to_s.chop}_ids_added")
      # 
      #     association_class = assoc_obj.options.class_name.blank? ? assoc_name.camelcase.constantize : assoc_obj.options.class_name.constantize
      #     
      #     added = association_class.find(association_ids)
      #     added.map!{ |a| OpenStruct.new({:id => a.id, :to_ess => a.to_s}) }
      #     
      #     removed = object.send("#{assoc_name}_removed")
      #     removed.map!{ |a| OpenStruct.new({:id => a.id, :to_ess => a.to_s}) }
      #     
      #     OpenStruct.new({ 
      #       :name => assoc_name, 
      #       :added => added, 
      #       :removed => removed
      #     })
      #   end
      # end.compact
    end
    
    # disable associations for now
    @associations = []
    
    self
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