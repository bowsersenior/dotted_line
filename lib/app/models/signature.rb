# Signatures provide an audit trail that shows who was responsible for making a change to a record
#
# Signature.what_changed will store the changes made by the signature's action.
#
# @example If a service agreement was approved and modified, what_changed could look like this:
#   { :attributes => [ 
#       { :name => 'status', 
#           :old => 'submitted', 
#           :new => 'approved'}
#       ],
#       :associations => [
#         { :name     => 'services',
#           :added    => [1],
#           :removed  => [3,4]
#         }
#       ]
#   }
#
# To require an explanation for an action (otherwise validations will fail)
# create a method on the signable class called `explanation_from_signer_required_for`
# that takes the signature action as a parameter and returns true or false
#
# @example Require an explanation when denying or modifying a service agreement
#   class ServiceAgreement < ActiveRecord::Base  
#     def explanation_from_signer_required_for(action)
#       ['deny', 'modify'].include? action
#     end
#   end
class Signature
  include Mongoid::Document
  include Mongoid::Timestamps
  
  include ScopedSearch::Model  
  
  field :action
  field :target

  field :name_of_signer
  field :signer_id
  field :signer_class, :default => 'User'
  
  field :description
  field :explanation_from_signer
  field :what_changed

  field :signable_id
  field :signable_type


  validates :signable_id, :presence => true
  validates :signable_type, :presence => true
    
  validates :signer_id, :presence => true  
  validates :name_of_signer, :presence => true


  
  before_validation :generate_description, :on => :create

   
  def signable
    signable_type.constantize.find(signable_id)
  end 
  
  def signer
    signer_class.constantize.find(signer_id)
  end
  
  # The description field is designed to capture all the details of this signature.
  # This way, an unambiguous audit trail exists without any dependency on lookups in the database for associated models.
  def generate_description(line_break="<br />")
    now = DateTime.now

    desc = "On #{now.strftime("%b %d, %Y")} at #{now.strftime('%I:%M%p')}" +
           ", #{name_of_signer} (user types: #{signer.user_types.map(&:name).join(', ')}) signed off on" +
           " a '#{action}' action on the following #{signable_type}: #{signable.to_s}"
                        
    desc += ".#{line_break} Explanation from signer: #{explanation_from_signer}" unless explanation_from_signer.blank?
    desc += ".#{line_break} Changes made:#{line_break} #{what_changed.to_s}" unless what_changed.blank?
    
    self.description = desc
  end  
   
  def what_changed
    RecordChange  # calling RecordChanged will ensure that it is loaded before what_changed is instantiated
    YAML::load(self.attributes['what_changed'])
  end
    
end