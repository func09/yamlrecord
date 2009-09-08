require 'yaml/store'

class YAMLRecord

  def self.inherited(subclass)
    subclass.instance_eval %-
      @yaml_fields = []
      @db_file = "#{RAILS_ROOT}/db/yamlrecord/#{subclass.to_s.underscore}.yml"
      @yaml_db = YAML::Store.new @db_file
    -
  end

  def self.field_names
    @yaml_fields
  end
  
  def self.save
    @yaml_db.transaction do
      @yaml_db[RAILS_ENV] ||= {}
      @yaml_fields.each do |yaml_field|
        @yaml_db[RAILS_ENV][yaml_field] = method("#{yaml_field}").call
      end
    end
  end

  def self.reload
    @yaml_db.transaction do
      if @yaml_db[RAILS_ENV]
        @yaml_fields.each do |yaml_field|
          if respond_to?("#{yaml_field}=") && @yaml_db[RAILS_ENV][yaml_field]
            method("#{yaml_field}=").call(@yaml_db[RAILS_ENV][yaml_field])
          end
        end
      end
    end
  end
  
  def self.attr_yaml_field(*fields)
    fields.each do |field|
      unless @yaml_fields.include?(field.to_s)
        class_inheritable_accessor field
        (@yaml_fields ||= []) << field.to_s
        @yaml_fields.uniq!
      end
    end
    reload
  end
  
end
