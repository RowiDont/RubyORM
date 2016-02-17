require_relative 'searchable'
require 'active_support/inflector'

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
    assoc_options[name] = HasManyOptions.new(name, self.to_s, options)
    relation = assoc_options[name]
    define_method(name) do
      has_many_class = relation.model_class
      id = self.send(relation.primary_key)
      relation.foreign_key
      has_many_class.where(relation.foreign_key => id)
    end
  end

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    define_method(name) do

      class1 = through_options.model_class
      table1 = through_options.table_name
      key1 = through_options.primary_key

      source_options = class1.assoc_options[source_name]
      class2 = source_options.model_class
      table2 = source_options.table_name
      key2 = source_options.foreign_key

      id = self.send(through_options.foreign_key)

      results = DBConnection.execute(<<-SQL, id)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{table1}
        JOIN
          #{table2} ON #{table1}.#{key2} = #{table2}.#{key1}
        WHERE
          #{table1}.#{key1} = ?
      SQL

      class2.parse_all(results).first

    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
