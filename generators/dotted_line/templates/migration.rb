class CreateSignatures < ActiveRecord::Migration
  def self.up
    create_table "signatures", :force => true do |t|
      t.string   "action"
      t.string   "target"
      t.string   "name_of_signer"
      t.text     "description"
      t.integer  "signable_id"
      t.string   "signable_type"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "explanation_from_signer"
      t.text     "what_changed"
    end
  end
  
  def self.down
    drop_table :signatures
  end
end