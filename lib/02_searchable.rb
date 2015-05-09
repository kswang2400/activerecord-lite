require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    require 'rails'
    where_line = []
    values = []

    params.each do |key, value|
      where_line << "#{key} = ?"
      values << value
    end

    where_line = where_line.join(" AND ")

    attributes = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL

    attributes.map { |att| self.new(att.symbolize_keys!) }
  end
end

class SQLObject
  extend Searchable
end
