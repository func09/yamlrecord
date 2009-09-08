require 'yaml/store'

class YAMLRecord

  def self.inherited(subclass)
    subclass.instance_eval %-
      @field_table = {}
      @db_file = "#{RAILS_ROOT}/db/yamlrecord/#{subclass.to_s.underscore}.yml"
      @yaml_db = YAML::Store.new @db_file
    -
  end

  def self.field_names
    @field_table.map{|name,key| name}
  end
  
  def self.save
    success = false
    @yaml_db.transaction do
      @yaml_db[RAILS_ENV] ||= {}
      @field_table.each do |name,type|
        value = case type
                when "string"
                  method("#{name}").call.to_s
                when "integer"
                  method("#{name}").call.to_i
                when "boolean"
                  !!method("#{name}").call.to_s.match(/true|1|t/)
                end
        @yaml_db[RAILS_ENV][name] = value
      end
      success = true
    end
    success
  end

  def self.reload
    @yaml_db.transaction do
      if @yaml_db[RAILS_ENV]
        @field_table.each do |name, type|
          if respond_to?("#{name}=") && @yaml_db[RAILS_ENV][name]
            value = case type
                    when "string"
                      @yaml_db[RAILS_ENV][name].to_s
                    when "integer"
                      @yaml_db[RAILS_ENV][name].to_i
                    when "boolean"
                      !!@yaml_db[RAILS_ENV][name].to_s.match(/true|1|t/)
                    end
            method("#{name}=").call(value)
          end
        end
      end
    end
  end

  # @param field_type :string, :integer, :boolean, :date, :datetime, :time, :timestamp
  def self.attr_yaml_field(field_name, field_type, options = {})
    
    field = {
      :field_name => field_name,
      :field_type => field_type,
    }

    @field_table[field_name.to_s] = field_type.to_s
    class_inheritable_accessor field_name
    
    reload
  end
  
end
