class DottedLineGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', "db/migrate", :migration_file_name => 'create_signatures'
    end
  end
end