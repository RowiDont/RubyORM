require_relative 'associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

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
end
