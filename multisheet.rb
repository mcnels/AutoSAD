#!/usr/bin/env ruby
require 'spreadsheet'

Spreadsheet.client_encoding = 'UTF-8'
book = Spreadsheet::Workbook.new
#puts "hey"

# sheet1 = book.create_worksheet :name => 'test1'
# sheet1.row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
# sheet2 = book.create_worksheet :name => 'test2'
# sheet2.row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
# i = Array[0, 1 ,2]

# puts i

#canvas = Canvas::API.new(:host => CANVAS_URL, :token => CANVAS_TOKEN)
i = 1
numbers = Array[1, 2, 3, 4, 5]
#for i in 0..2
while i < 10
  #puts i
  sheet = book.create_worksheet
  sheet.row(0).push i.to_s
  numbers.each_with_index do |num, j|
    sheet.row(j+1).push num.to_s
  end
  sheet.name = i.to_s
  i += 1
end
  # sheet.each do |row|
#    row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
# #   # end

  # sheet.row(0).push "1","2"
# end

#puts 'url,context_id,controller,created_at,user_agent,participated,remote_ip'
# Spreadsheet.client_encoding = 'UTF-8'
# book = Spreadsheet::Workbook.new
# sheet(j) = book.create_worksheet :name => sheet_name
# sheet(j).row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
# sheet1 = book.create_worksheet :name => 'saddtest'
# sheet1.row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
  #sheet1.each do |row|
#book.worksheets.each do |sheet|
  #puts user_id
#   sheet.each do |row|
#     #puts user_id
#     row(0).push "url","controller","created_at","user_agent","participated","remote_ip"
#     page_views.each_with_index do |x, i|
#       row(i+1).push x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']
#       #sheet1.row(i+1).push x['url'], x['action'], x['created_at'], x['interaction_seconds'].to_s, x['remote_ip']
#     end
#   end
# end
      #page_views.each { |x| puts x['url'] + ',' + x['action'] + ',' + x['created_at'] + ',' + x['interaction_seconds'].to_s + ',' + x['remote_ip'] }

      #page_views = canvas.get("/api/v1/users/" + user_id + "/")
      #page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?per_page=100")
      #page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?per_page=100&start_time=2017-10-13T12:00:00Z")
      #page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?per_page=100", {'start_time'=> '2017-10-13T12:00:00Z', 'end_time' => '2017-10-20T23:59:00Z'})
      #time_period = canvas.get("/api/v1/users/" + user_id + "/page_views?start_time=2017-10-13T12:00:00-05:00&end_time=2017-10-20T23:59:00-05:00")

      # Set up the environment
      #Dotenv.load
      #CANVAS_URL = ENV['https://canvas.fit.edu/']
      #CANVAS_TOKEN = ENV['1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj']

book.write 'test.xls'
