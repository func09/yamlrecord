require 'yaml/store'

class YAMLRecord
  
  @@db_file = "#{RAILS_ROOT}/db/yamlrecord/#{self.to_s.underscore}_#{RAILS_ENV}.yml"
  @@yaml_db = YAML::Store.new @@db_file

  def self.field_names
    @@yaml_fields
  end
  
  def self.save
    @@yaml_db.transaction do
      @@yaml_fields.each do |yaml_field|
        @@yaml_db[yaml_field] = instance_variable_get("@inheritable_attributes")[yaml_field.to_sym]
      end
    end
  end

  def self.reload
    @@yaml_db.transaction do
      @@yaml_fields.each do |yaml_field|
        method("#{yaml_field}=").call(@@yaml_db[yaml_field])
      end
    end
  end
  
  def self.attr_yaml_field(*fields)
    fields.each do |field|
      class_inheritable_accessor field
      (@@yaml_fields ||= []) << field.to_s
      @@yaml_fields.uniq!
    end
    reload
  end
  
end
