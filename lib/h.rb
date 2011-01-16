require "rubygems"
require "hpricot"

doc = Hpricot(open("document.mwb.xml"))

doc.search("value[@type='list'][@content-struct-name='db.mysql.Table'][@key='tables']/value[@type='object'][@struct-name='db.mysql.Table']").each do |table|
  table_id = table.attributes["id"]
  puts table.search("/value[@type='string'][@key='name']").first.inner_html + "\t" + table_id
  table.search("value[@type='list'][@content-type='object'][@content-struct-name='db.mysql.Column'][@key='columns']") do |columns|
    columns.search("value[@type='object'][@struct-name='db.mysql.Column']") do |column|
      puts "\t" + (column/"value[@type='string'][@key='name']").inner_html + "\t" + column.attributes["id"]
    end
  end

  table.search("value[@type='list'][@content-type='object'][@content-struct-name='db.mysql.ForeignKey'][@key='foreignKeys']/value[@type='object'][@struct-name='db.mysql.ForeignKey']") do |fk|
    pp (fk/"link[@type='object'][@struct-name='db.mysql.Table'][@key='referencedTable']").first
    pp (fk/"value[@type='string'][@key='name']").inner_html
  end

end