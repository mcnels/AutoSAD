#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

# Check for command line arguments
if ARGV.length <= 0
  puts "ERROR\n"
  puts "Usage:./page_views.rb canvas_course_id check_period_start_time"
  exit
end

# Take the course id from argument
course_id = ARGV[0]
# start and end time for check period
period_start = ARGV[1]
end_time = DateTime.parse("2017-11-15T00:00:00+00:00")
#end_time = DateTime.now

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get all students
list_student = canvas.get("/api/v1/courses/" + course_id + "/students")
students = Array.new(list_student)

# Create workbook for student
p = Axlsx::Package.new

# Get the quizzes
quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

# Get all the quizzes
while quiz_list.more? do
  quiz_list.next_page!
end

# there should be a better way for this, otherwise I would have to specify the amount of tests to check for every time
# I should have a condition here that looks at the course ID to determine a tentative size for the array
stuRec = Array.new((students.size)+1){Array.new(19)}
conflict = ""
i = 1

#For each student in the course, do this...
students.each do |student|
  next if student['id'].to_s == conflict #go to next student
  next if student['id'].to_s == '1856840' #id of test student
  conflict = student['id'].to_s
  j = 1
  # boolean for students that have submssions
  #stuHasSubm = "false"

  # Get all unit tests for course (this filters the list receives fro only the ones we want to check)
  quiz_list.each do |q|
    # Applying the filters...
    if (q['title'].include? "Test A") || (q['title'].include? "Test B")
      next if (q['title'].include? "Bonus") || (q['title'].include? "Proctored")
      quiz_id = q['id'].to_s

      # Skip checking tests that happen after end_time
      #puts DateTime.parse(q['due_at'].to_s)
      break if DateTime.parse(q['due_at'].to_s) > end_time && q['title'] == "Unit 9 Test B"
      next if DateTime.parse(q['due_at'].to_s) > end_time

      # Get all submissions for each quiz
      submissions_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes/" + quiz_id + "/submissions?", {'per_page' => '100'})
      while submissions_list.more? do
        submissions_list.next_page!
      end

      tookTest = "N"

      # Labels for the rows and columns of the matrix receiving the start and submission times of the students
      stuRec[i][0] = student['id']
      stuRec[0][j] = q['title']
      # Add submissions info to array of records for student
      submissions_list.each do |submission|
        # break out of the quizzes loop

        # if the id of the current student being checked matches the user_id received from the submission data, then save info in the matrix
        #next if student['id'].to_s != submission['user_id'].to_s

        if student['id'].to_s == submission['user_id'].to_s #&& (submission['started_at'] != "null" || submission['finished_at'] != "null")
          stuRec[i][j] = {:stime => submission['started_at'], :sbmtime => submission['finished_at'], :unit => q['title']}
          #stuHasSubm = "true"
          tookTest = "Y"
          break if tookTest == "Y"
        end
      end

      #break if stuHasSubm == "false"
      # if the student didn't take the test or for some reason the information is missing
      if tookTest == "N"
         stuRec[i][j] = {:stime => "missing", :sbmtime => "missing", :unit => q['title']}
      end
      j = j + 1
      # Print to console
      puts "submission info recorded for "+  student['sortable_name'] + " for " + q['title'].to_s
    else
      # Print to console
      puts "test does not fit ASC's criteria"
    end
  end
  i = i + 1
end

# Print matrix to console
stuRec.each { |x|
  puts x.join(" ")
}

# sort matrix by studentname (I just realized this actually might not be needed - looks like the students are sorted by their last names :?)

# Iterate over student records matrix (starting at index 1 to skip the labels) to print page views activity
stuRec[1..-1].each do |test|
  # Assign use
  user_id = test[0].to_s

  next if user_id.to_s == conflict #go to next student
  conflict = user_id.to_s
  currstudent = ""
f
  # Assign worksheet names based on student's user id
  students.each do |student|
    if user_id.to_s == student['id'].to_s
      currstudent = student['sortable_name'] # might need to change this to username
    end
  end

  # Print to console
  puts currstudent+" started"

  # Create a worksheet for current student
  p.workbook.add_worksheet do |sheet|
    # Get page views activity for each student who submitted a quiz
    page_views = canvas.get("/api/v1/users/" + user_id.to_s + "/page_views?", {'start_time'=> period_start, 'end_time' => end_time, 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    while page_views.more?  do
      page_views.next_page!
    end

    # Print header row in Excel worksheet
    sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip", "unit test", "start/stop","file name","IP Switch","Browser Switch"]

    # Iterate over test records of each student
    test[1..-1].each do |rec|
      # If there's no record then write "missing"
      if rec[:stime] == "missing" || rec[:sbmtime] == "missing"
        sheet.add_row ["missing", "missing", "missing", "missing", "missing", "missing", rec[:unit].to_s], :types => [:string, :string, :string, :string, :string, :string, :string]
      else
        # Print the page views activity for the period between the start time and the submission time
        page_views.each do |x|
          next if DateTime.parse(x['created_at']) <= (DateTime.parse(rec[:stime])-(1/24.0)) || DateTime.parse(x['created_at']) >= (DateTime.parse(rec[:sbmtime])+(1/24.0))
          sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], rec[:unit].to_s], :types => [nil, nil, :string, :string, :string, :string, :string]
        end
      end
      # add new line after each quiz results
      sheet.add_row [""]
    end

    # rename sheet and add given name to sheetnames array
    sheet.name = currstudent

    # Print to console
    puts currstudent+" done"

    # Create the Excel document
    p.serialize('/Users/mcnels/Documents/CE/Canvas/5013test1.xlsx')
  end
end
# Print to console
puts "all done"
