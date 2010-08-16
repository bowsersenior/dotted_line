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
class Signature < ActiveRecord::Base
  belongs_to :signable, :polymorphic => true
  belongs_to :user

  validates_presence_of :signable, :name_of_signer
  
  serialize :what_changed, RecordChange
  
  # validates_presence_of :explanation_from_signer, :if => Proc.new{|signature| signature.signable.explanation_from_signer_required_for?(signature.action)}
  
  before_validation_on_create :generate_description
    
  # The description field is designed to capture all the details of this signature.
  # This way, an unambiguous audit trail exists without any dependency on lookups in the database for associated models.
  def generate_description(line_break="<br />")
    now = DateTime.now
    self.description =  "On #{now.strftime("%b %d, %Y")} at #{now.strftime('%I:%M%p')}"
    self.description += ", #{name_of_signer} (user types: #{user.user_types}) signed off on"
    self.description += " a '#{action}' action on the following #{signable.class.to_s.titleize}: #{signable.to_s}"
    self.description += ".#{line_break} Explanation from signer: #{explanation_from_signer}" unless explanation_from_signer.blank?
    self.description += ".#{line_break} Changes made:#{line_break} #{what_changed}" unless what_changed.blank?
  end
  
  
    
end