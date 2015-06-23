require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.downcase + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name =  options[:class_name]  || name.to_s.camelcase
    @foreign_key = options[:foreign_key] || :"#{name}_id"
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name =  options[:class_name]  || name.to_s.singularize.camelbase
    @foreign_key = options[:foreign_key] || :"#{self_class_name.downcase}_id"
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name.to_s, options)
    define_method("#{options.class_name.downcase}") do
      # p options.foreign_key
      # p send(options.foreign_key)
      options.model_class.find(send(options.foreign_key))
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name.to_s, self.to_s, options)
    p options.model_class
    define_method(name) do
      p options.model_class.where(
        options.foreign_key => send(options.primary_key)
      )
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
