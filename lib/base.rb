require "rubygems"
require "nokogiri"
require 'pp'
require 'active_support'
require 'active_support/inflector'

module ActiveBench
  class Schema
    def add_table id, name
      @tables_ids ||= {}
      @tables_names ||= {}
      @tables_ids[id] = @tables_names[name] = Table.new(self, id, name)
    end

    def tables
      @tables_ids.values
    end

    def table_by_id id
      @tables_ids[id]
    end

    def table_by_name name
      @tables_names[name]
    end

    def generate
      
    end
  end
  
  class Table
    attr_reader :name, :id

    def initialize schema, id, name
      @schema = schema
      @id = id
      @name = name
      @columns_ids ||= {}
      @columns_names ||= {}
      @fks_ids ||= {}
      @fks_names ||= {}
    end

    def add_fk id, name, *opts
      opts = *opts
      @fks_ids[id] = @fks_names[name] = FK.new(self, id, name, opts[:many], opts[:assoc])
    end

    def fks
      @fks_ids.values
    end

    def add_column id, name
      @columns_ids[id] = @columns_names[name] = Column.new(self, id, name)
    end

    def columns
      @columns_ids.values
    end

    def column_by_name name
      @columns_names[name]
    end

    def column_by_id name
      @columns_ids[name]
    end

    def plural?
      @name == class_name.tableize
    end

    def class_name
      @name.classify
    end

    def to_model
      set_table_name = ""
      unless plural?
        # need to set table name with set_table_name()
        set_table_name = "\n  set_table_name(\"#{@name}\")"
      end
      associations = ""
      fks.each do |fk|
        associations << fk.to_assotiation
      end

      "class #{class_name}#{set_table_name}#{associations}\nend"
    end
  end

  class Column
    attr_reader :name, :id, :table
    
    def initialize table, id, name
      @table = table
      @id = id
      @name = name
    end
  end

  class FK
    attr_reader :name, :id
    attr_accessor :ref_table

    def initialize table, id, name, many = false, assoc = :belongs
      @table = table
      @id = id
      @name = name
      @many = many
      @assoc = assoc
    end

    def is_many?
      @many == true
    end

    def columns
      @columns
    end

    def ref_columns
      @ref_columns
    end

    def add_column(col)
      @columns ||= []
      @columns << col
    end
    
    def add_ref_column(col)
      @ref_columns ||= []
      @ref_columns << col
    end

    def to_assotiation
      # belongs_to assotiation
      if @assoc == :belongs
        pkey = ""
        if @ref_columns.size > 1
        else
          #@ref_columns.collect { |col| "#{col.table.name}.#{col.name}

          if @ref_columns.first.name != 'id'
            pkey = ", :primary_key = \"#{@ref_columns.first.name}\""
          end
        end

        fkey = ""
        if @columns.size > 1
        else
          #@ref_columns.collect { |col| "#{col.table.name}.#{col.name}
          if @columns.first.name != ref_table.class_name.tableize.singularize.foreign_key
            fkey = ", :foreign_key => \"#{@columns.first.name}\""
          end
        end
        "\n  belongs_to :#{ref_table.class_name.tableize.singularize}#{ref_table.plural? ? "" : ", :class_name => \"#{ref_table.class_name}\""}#{fkey}#{pkey}" # :#{@columns.collect { |col| "#{col.table.name}.#{col.name}" }} >> :#{@ref_columns.collect { |col| "#{col.table.name}.#{col.name}" }}"
      else

        pkey = ""
        if @columns.size > 1
        else
          #@ref_columns.collect { |col| "#{col.table.name}.#{col.name}
          if @columns.first.name != 'id'
            pkey = ", :primary_key = \"#{@ref_columns.first.name}\""
          end
        end

        fkey = ""
        if @ref_columns.size > 1
        else
          if @ref_columns.first.name != @table.class_name.tableize.singularize.foreign_key
            fkey = ", :foreign_key => \"#{@ref_columns.first.name}\""
          end
        end

        "\n  #{@many ? "has_many :" + ref_table.class_name.tableize : "has_one :" + ref_table.class_name.tableize.singularize}#{ref_table.plural? ? "" : ", :class_name => \"#{ref_table.class_name}\""}#{fkey}#{pkey}" # :#{@columns.collect { |col| "#{col.table.name}.#{col.name}" }} >> :#{@ref_columns.collect { |col| "#{col.table.name}.#{col.name}" }}"
      end
    end
  end
end