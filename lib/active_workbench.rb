require "active_workbench/base"

module ActiveWorkbench
  class Runner
    def initialize file, options
      @options = options
      @doc = Nokogiri::XML(file)
      @schema = Schema.new
    end

    def run
      xml_tables = @doc.xpath("/data//value[@type='list'][@content-struct-name='db.mysql.Table'][@key='tables']/value[@type='object'][@struct-name='db.mysql.Table']")
      xml_tables.each do |table|
        table_id = table.attributes["id"].to_s
        table_name = table.xpath("value[@type='string'][@key='name']").first.content.to_s
        schema_table = @schema.add_table(table_id, table_name)
        if @options[:verbose]
          puts "Found table: #{schema_table.name}" # + "\t" + schema_table.id
        end

        table.xpath("value[@type='list'][@content-type='object'][@content-struct-name='db.mysql.Column'][@key='columns']").each do |columns|
          columns.xpath("value[@type='object'][@struct-name='db.mysql.Column']").each do |column|
            col = schema_table.add_column(column.attributes["id"].to_s, column.xpath("value[@type='string'][@key='name']").first.content.to_s)
            if @options[:verbose]
              puts "\t column: " + col.name # + "\t" + col.id
            end
          end
        end
      end

      xml_tables.each do |table|
        schema_table = @schema.table_by_id(table.attributes["id"].to_s)

        table.xpath("value[@type='list'][@content-type='object'][@content-struct-name='db.mysql.ForeignKey'][@key='foreignKeys']/value[@type='object'][@struct-name='db.mysql.ForeignKey']").each do |fk|
          ref_table = @schema.table_by_id(fk.xpath("link[@type='object'][@struct-name='db.mysql.Table'][@key='referencedTable']").first.content.to_s)

          many = fk.xpath("value[@type='int'][@key='many']").first.content.to_i == 1 ? true : false

          delete_rule = fk.xpath("value[@type='string'][@key='deleteRule']").first.content.to_s
          update_rule = fk.xpath("value[@type='string'][@key='updateRule']").first.content.to_s

          # belongs_to associations
          schema_fk = schema_table.add_fk(fk.attributes["id"].to_s, fk.xpath("value[@type='string'][@key='name']").first.content.to_s, :many => many, :assoc => :belongs)
          schema_fk.ref_table = ref_table

          # has_one, has_many associations
          ref_fk = ref_table.add_fk(fk.attributes["id"].to_s, fk.xpath("value[@type='string'][@key='name']").first.content.to_s, :many => many, :assoc => :has)
          ref_fk.ref_table = schema_table

          fk.xpath("value[@type='list'][@content-type='object'][@content-struct-name='db.Column'][@key='columns']/link[@type='object']").each do |col|
            c = schema_table.column_by_id(col.content.to_s)
            schema_fk.add_column(c)
            ref_fk.add_ref_column(c)
          end

          fk.xpath("value[@type='list'][@content-type='object'][@content-struct-name='db.Column'][@key='referencedColumns']/link[@type='object']").each do |ref_col|
            c = ref_table.column_by_id(ref_col.content.to_s)
            schema_fk.add_ref_column(c)
            ref_fk.add_column(c)
          end
        end
      end
      if @options[:create]
        @schema.tables.each do |table|
          f = File.new(File.join(@options[:create], table.name.classify.tableize.singularize + ".rb"), File::CREAT|File::TRUNC|File::RDWR)
          f.write table.to_model
          f.close
          puts "Write: " + File.join(@options[:create], table.name.classify.tableize.singularize + ".rb")
        end
      else
        @schema.tables.each do |table|
          puts table.to_model
          puts
        end
      end
    end
  end
end


