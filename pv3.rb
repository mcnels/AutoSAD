#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'

# Check for command line arguments
if (ARGV.length <= 0)
    puts "ERROR\n"
    puts "Usage:./page_views.rb canvas_course_id"
    exit
end

# Take the course id from argument
# Could potentially take start_time and end_time at command line as ARGV[1] and ARGV[2] then pass it as argument to the GET request
course_id = ARGV[0]
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get list of students in a course
list_student = canvas.get("/api/v1/courses/" + course_id + "/students")
user_id = ""

# Create worksheet for student
p = Axlsx::Package.new

# Generate page views for each student in course
list_student.each do |y|
  next if y['id'].to_s == user_id #go to next student
  p.workbook.add_worksheet do |sheet|
    # Define user ID and username, so they can later be used to name the worksheets
    user_id = y['id'].to_s
    sheet_name = y['login_id']

    # Get page views activity for each student for a time period
    page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> '2017-10-18T12:00:00-05:00', 'end_time' => '2017-10-22T23:59:00-05:00', 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    while page_views.more?  do
        page_views.next_page!
    end

    # create headers
    sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip"]#,"unit test","file name","IP Switch","Browser Switch","start/stop"

    # list page views activity for said student
    page_views.each do |x|
      sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip']], :types => [nil, nil, :string, :string, :string, :string]
    end

    puts sheet_name+" done"
    sheet.name = sheet_name
  end
  p.serialize('pvtest.xlsx')
end
