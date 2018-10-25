#!/usr/bin/env ruby
require 'canvas-api'
require 'json'

# Take the course id from argument
courses = ["533686"]
# start and end time for check period
period_start = "2018-10-10T00:00:00-05:00"
end_time_str = "2018-10-25T00:00:00-05:00"

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

mojave = Array.new
totalcount = 0
courses.each do |c|

  # Get all students/ might need to change this and get students from sections endpoint so to get remove transfers and withdrawals
  list_student = canvas.get("/api/v1/courses/" + c + "/students")
  students = Array.new(list_student)

  list_pending = canvas.get("/api/v1/courses/" + c + "/search_users", {'enrollment_type[]' => 'student', 'enrollment_state[]' => 'invited'})

  while list_pending.more? do
    list_pending.next_page!
  end
  pending = Array.new(list_pending)

  # p = Axlsx::Package.new

  skipped = Array.new
  conflict = ""
  classcount = 0

  students.each do |student|
    next if student['sortable_name'].to_s == conflict #go to next student
    next if student['id'].to_s == "754859" || student['id'].to_s == "1848148" || student['id'].to_s == "1588479" || student['id'].to_s == "756103" || student['id'].to_s == "43149" || student['id'].to_s == "820975"# Skip Eric, Josh, McNels, Karsing, Cindy ... include other staff members here in an OR clause

    # if student's name is an empty string// student is the Test student//add transfers and withdrawals manually for now temporary solution
    if student['sortable_name'].to_s == "Student, Test" || student['sortable_name'] == "" || student['id'].to_s == '1861484' || student['id'].to_s == '1861096' || student['id'].to_s == '1853138' || student['id'].to_s == '1855010' || student['id'].to_s == '1854626' || student['id'].to_s == '1857372' || student['id'].to_s == '774933' || student['id'].to_s == '1855030'
      skipped.push(student['id'])
    end
    next if student['sortable_name'].to_s == "Student, Test"
    # Account for pending, withdraws, and other weird cases
    isPending = false
    pending.each do |pending|
      if student['id'].to_s == pending['id'].to_s
        isPending = true
        skipped.push(student['id'])
        break
      end
    end

    next if isPending

    next if student['id'].to_s == '1863490' || student['id'].to_s == '1859088' || student['id'].to_s == '1863550' #id of test student
    # next if student['id'].to_s == '1861096' || student['id'].to_s == '1861484' || student['id'].to_s == '1853138' || student['id'].to_s == '1855010' || student['id'].to_s == '1854626' || student['id'].to_s == '1857372' || student['id'].to_s == '774933' || student['id'].to_s == '1855030'#pending students
    next if student['sortable_name'] == ""

    conflict = student['sortable_name'].to_s
    user_id = student['id'].to_s

    # p.workbook.add_worksheet do |sheet|
      # Get page views activity for each student who submitted a quiz
    page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> period_start, 'end_time' => end_time_str, 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    while page_views.more?  do
        page_views.next_page!
    end

    page_views.each do |x|
      if x['user_agent'].to_s.include? "Mac OS X 10_14"
        puts student['sortable_name'].to_s + " is running Mojave !"
        mojave.push(student['id'].to_s + " " + student['sortable_name'].to_s)
        classcount = classcount + 1
        break
      end
    end

    puts student['sortable_name'].to_s + " done"
    puts classcount.to_s + " so far in " + c.to_s
    totalcount = totalcount + classcount
  end

  puts c.to_s + " done"

end

File.open("mojave5014.txt", 'w+') do |f|
  f.puts(mojave)
end
puts mojave
puts totalcount
