
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    all_rows = DBConnection.execute2(<<-SQL)
      SELECT * FROM "#{table_name}"
    SQL

    all_rows[0].each do |col|
      define_method(col)       { attributes[col.to_sym] }
      define_method("#{col}=") { |value| attributes[col.to_sym] = value }
    end

    all_rows[0].map { |str| str.to_sym }
  end

  def self.finalize!
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || "#{self.to_s.downcase}s"
  end

  def self.all
    require 'rails'
    all_rows = DBConnection.execute(<<-SQL)
      SELECT * FROM "#{table_name}"
    SQL

    all_rows.each do |hashes|
      hashes.symbolize_keys!
    end

    self.parse_all(all_rows)
  end

  def self.parse_all(results)
    all = []
    results.each do |attributes|
      all << self.new(attributes)
    end

    all
  end

  def self.find(id)
    require 'rails'
    attr_hash = DBConnection.execute(<<-SQL, id)
      SELECT * FROM "#{table_name}" WHERE id = ?
    SQL

    return (attr_hash.empty?) ? nil : self.new(attr_hash.first.symbolize_keys!)
  end

  def initialize(params = {})
    columns = self.class.columns

    params.each do |h, k|
      raise "unknown attribute '#{h.to_s}'" unless columns.include?(h)
      attributes[h] = k
    end
  end

  def attributes
    @attributes ||= {} 
  end

  def attribute_values
    output = []
    @attributes.each do |key, value|
      output << value
    end

    output
  end

  def insert
    columns = "(#{self.class.columns[1..-1].join(", ")})"
    q_marks = "(#{(['?'] * attribute_values.length).join(", ")})"

    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} #{columns}
      VALUES
        #{q_marks}
    SQL

    attributes[:id] = DBConnection.instance.last_insert_row_id
  end

  def update
    update_values = []

    self.class.columns.each do |col|
      update_values << "#{col} = ?"
    end

    update_values = update_values.join(", ")

    DBConnection.execute(<<-SQL, attribute_values, attributes[:id])
      UPDATE
        #{self.class.table_name}
      SET
        #{update_values}
      WHERE
        id = ?
    SQL

  end

  def save
    if attributes[:id].nil?
      insert
    else
      update
    end
  end
end
