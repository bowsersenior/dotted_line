module DottedLine
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def signs_on_the_dotted_line(opts={:for => :all, :require_explanation_for => [], :default_action => 'create'})
      keep_track_of(*opts[:for]) unless opts[:for].blank?

      has_many :signatures, :as => :signable, :validate => false
      validates_associated :signatures
      accepts_nested_attributes_for :signatures
            
      cattr_accessor :require_explanation_for, :default_action, :tracked_associations, :require_signature_for_update
      self.require_explanation_for      = opts[:require_explanation_for]
      self.default_action               = opts[:default_action]
      self.require_signature_for_update = opts[:require_signature_for_update]
    
      attr_accessor :details_for_signature, :already_signed, :suppressed_errors
      
      after_save :record_signature
      
      send :include, InstanceMethods
    end
  end

  module InstanceMethods
    def record_details_for_signature(*args)
      self.details_for_signature = *args
      archive_self_for_signature
    end
    alias_method :sign, :record_details_for_signature
    
    def archive_self_for_signature
      ghost = self.clone
        
      self.dirty_associations.each do |assoc|
        ghost.send( "#{assoc}=" , self.send(assoc) )
      end
          
      self.details_for_signature[:ghost] = ghost
      self.details_for_signature[:new_record?] = self.new_record?
      
      true
    end
    
    def record_signature
      unless self.already_signed
        raise_error DetailsMissingError.new("details_for_signature is blank!") if self.details_for_signature.blank?

        # If there was a problem with the above, don't create a signature at all.
        # This situation will happen if a model has signatures enabled, but an instance is updated without calling the sign method.
        # Setting `require_signature_for_update` to true will raise an error, otherwise the signature is silently skipped
        if self.suppressed_errors.blank?  
          required_details_for_signature = %w( signer action ghost )
          required_details_for_signature.each do |field|
            raise_error DetailsMissingError.new("#{field} is blank in details_for_signature") if self.details_for_signature[field.intern].blank?
          end
        
          ghost = self.details_for_signature[:ghost]
          action = self.details_for_signature[:action].to_s
          signer = self.details_for_signature[:signer]
          explanation = self.details_for_signature[:explanation]
      
          ghost.enable_dirty_associations do
            ghost.attributes = self.attributes

            self.dirty_associations.each do |assoc|
              ghost.send "#{assoc.to_s}=", self.send(assoc)
            end

            what_changed = RecordChange.new(ghost, :new_record? => self.details_for_signature[:new_record?])
        
            create_signature(action, signer, explanation, what_changed)
          end
        end
      end
    end

    def explanation_from_signer_required_for(action)
      case self.class.require_explanation_for 
      when :all 
        true
      when :none
        false
      when nil
        false
      else
        self.class.require_explanation_for.include?(action.to_s)
      end
    end

    def create_signature(action, signer, explanation="", what_changed=nil)    
      self.signatures.create(
        :signable                 => self,
        :user                     => signer, 
        :action                   => action.to_s, 
        :name_of_signer           => signer.to_s,
        :target                   => self.to_s,
        :explanation_from_signer  => explanation,
        :what_changed             => what_changed
      )
      
      self.already_signed = true  # prevent duplicates
    end    
    
    def raise_error(error)
      if self.class.require_signature_for_update
        raise(error) 
      else
        self.suppressed_errors ||= []
        self.suppressed_errors << error
      end
    end
    
  end
  
  class DetailsMissingError < StandardError; end
  
end

ActiveRecord::Base.send :include, DottedLine