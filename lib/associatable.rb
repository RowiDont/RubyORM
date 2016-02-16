require_relative 'searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    fk = options[:foreign_key]
    pk = options[:primary_key]
    cn = options[:class_name]

    @foreign_key =  fk || "#{name}Id".underscore.to_sym
    @primary_key = pk || :id
    @class_name = cn || "#{name}".singularize.capitalize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    fk = options[:foreign_key]
    pk = options[:primary_key]
    cn = options[:class_name]

    @foreign_key =  fk || "#{self_class_name}Id".underscore.to_sym
    @primary_key = pk || :id
    @class_name = cn || "#{name}".singularize.capitalize
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)
    relation = assoc_options[name]
    define_method(name) do
      foreign_key = self.send(relation.foreign_key)
      belongs_to_class = relation.model_class
      belongs_to_class.where(id: foreign_key).first
    end
  end

  def has_many(name, options = {})
    # p options
    assoc_options[name] = HasManyOptions.new(name, self.to_s, options)
    relation = assoc_options[name]
    define_method(name) do
      has_many_class = relation.model_class
      id = self.send(relation.primary_key)
      relation.foreign_key
      has_many_class.where(relation.foreign_key => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
