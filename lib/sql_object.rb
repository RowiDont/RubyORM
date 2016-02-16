require_relative 'db_connection'
require 'active_support/inflector'
require_relative 'searchable'


class SQLObject
  
  def self.columns
    unless @columns
      result = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
        LIMIT
          1
      SQL

      @columns = result[0].map(&:to_sym)
    end

    @columns
  end

  def self.finalize!
    self.columns.each do |column|

      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    cats = []
    results.each do |row|
      cats << self.new(row)
    end
    cats
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    result = parse_all(result).first
    result ? result : nil
  end

  def initialize(params = {})
    columns = self.class.columns
    self.class.finalize!

    params.each do |column, value|
      column = column.to_sym
      raise "unknown attribute '#{column}'" unless columns.include?(column)

      self.send("#{column}=", value)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    values = (["?"] * attribute_values.length).join(", ")
    columns = self.class.columns[1..-1].join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{columns})
      VALUES
        (#{values})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    column_names = self.class.columns
    columns = column_names[1..-1].map do |column|
      "#{column} = ?"
    end.join(", ")
    id_val = attributes[:id]

    DBConnection.execute(<<-SQL, *attribute_values[1..-1], attributes[:id])
      UPDATE
        #{self.class.table_name}
      SET
        #{columns}
      WHERE
        id = ?
    SQL
  end

  def save
    if attributes[:id].nil?
      self.insert
    else
      self.update
    end
  end
end
