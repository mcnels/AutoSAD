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
end_time = DateTime.parse("2017-09-27T00:00:00-00:00")
#end_time = DateTime.now

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get all students/ might need to change this and get students from sections endpoint so to get remove transfers and withdrawals
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
# array containing all problematic students
skipped = Array.new
conflict = ""
i = 1
count = 0
#For each student in the course, do this...
students.each do |student|
  next if student['sortable_name'].to_s == conflict #go to next student
  next if student['id'].to_s == "754859" # Skip Eric
    # if student's name is an empty string//add transfers and withdrawals manually for now temp sol
  if student['sortable_name'] == "" || student['id'].to_s == '1856732' || student['id'].to_s == '1857392' || student['id'].to_s == '1856104' || student['id'].to_s == '1857696' || student['id'].to_s == '1856206' || student['id'].to_s == '1849586' || student['id'].to_s == '1023182' || student['id'].to_s == '777953'
    skipped.push(student['id'])
  end
  next if student['id'].to_s == '1856840' || student['id'].to_s == '1856732' || student['id'].to_s == '1857392' || student['id'].to_s == '1856104' #id of test student
  next if student['id'].to_s == '1857696' || student['id'].to_s == '1856206' || student['id'].to_s == '1849586' || student['id'].to_s == '1023182' || student['id'].to_s == '777953' #pending students
  next if student['sortable_name'] == ""

  conflict = student['sortable_name'].to_s
  user_id = student['id'].to_s
  j = 1

  currstudent = ""
    count = count + 1
  #next if count != 13
  # Create a worksheet for current student
  p.workbook.add_worksheet do |sheet|
    # Get page views activity for each student who submitted a quiz
    page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> period_start, 'end_time' => end_time, 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    while page_views.more?  do
      page_views.next_page!
    end

    escape = false

    # Print header row in Excel worksheet
    sheet.add_row ["url","controller","created_at","user_agent","participated","remote_ip", "unit test", "start", "stop", "IP Switch", "Browser Switch", "file name"]

    # Get all unit tests for course (this filters the list receives fro only the ones we want to check)
    quiz_list.each do |q|
      # Applying the filters...
      if (q['title'].include? "Test A") || (q['title'].include? "Test B")
        next if (q['title'].include? "Bonus") || (q['title'].include? "Proctored")
        quiz_id = q['id'].to_s

        if DateTime.parse(q['due_at'].to_s) > end_time && q['title'] == "Unit 9 Test B"
          escape = true
        end
        #puts quiz_id
        # Skip checking tests whose due dates are before the period start (q['lock_info']['lock_at'].to_s) | not all quizzes have this info... be careful
        next if DateTime.parse(q['due_at'].to_s) < DateTime.parse(period_start.to_s) #subject to change/need to check how due dates are received compared to how they are on the website
        # Skip checking tests whose due dates are after end_time
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

          if student['id'].to_s == submission['user_id'].to_s #&& (submission['started_at'] != "null" || submission['finished_at'] != "null")
            # Assign worksheet names based on student's user id
           # students.each do |student|
              #if user_id == student['id'].to_s
                currstudent = student['sortable_name'] # might need to change this to username
              #end
            #end

            # Print to console
            puts currstudent+" started"

            stuRec[i][j] = {:stime => submission['started_at'], :sbmtime => submission['finished_at'], :unit => q['title']}
            tookTest = "Y"
            break if tookTest == "Y"
          #else
            #students.each do |student|
             # if user_id == student['id'].to_s
             #    currstudent = student['sortable_name'] # might need to change this to username
             #    puts currstudent+" started"
              #end
            #end
          end
        end

        #break if stuHasSubm == "false"
        # if the student didn't take the test or for some reason the information is missing/ can be moved into the else part of the previous if/else statement
        if tookTest == "N"
          currstudent = student['sortable_name'] # might need to change this to username
          puts currstudent+" started"
           stuRec[i][j] = {:stime => "missing", :sbmtime => "missing", :unit => q['title']}
        end

        # If there's no record then write "missing"
        if  stuRec[i][j][:stime] == "missing" || stuRec[i][j][:sbmtime] == "missing"
          sheet.add_row ["missing", "missing", "missing", "missing", "missing", "missing", stuRec[i][j][:unit].to_s, "missing", "missing", "missing", "missing"], :types => [:string, :string, :string, :string, :string, :string, :string, :string, :string, :string, :string]
        else
          itcount = 0
          cur_ip = ""
          cur_browser = ""

          # Define styles
          acceptableFile = sheet.styles.add_style :bg_color => "66cdaa", :fg_color => "006400", :b => true
          fileInBetween = sheet.styles.add_style :bg_color => "ffec8b", :fg_color => "cd3700", :b => true

          # Print the page views activity for the period between the start time and the submission time
          page_views.each do |x|
            itcount = itcount + 1
            if itcount >= 2
              if cur_ip != x['remote_ip']
                ipAns = "Different IP"
              else
                ipAns = "Same IP"
              end
              cur_ip = x['remote_ip']
              if cur_browser != x['user_agent']
                browsAns = "Different Browser"
              else
                browsAns = "Same Browser"
              end
              cur_browser = x['user_agent']
            end

            # if x['url'].contains(id of file)
            # Skip if activity is not between 6 minutes before start time and submission time
            next if DateTime.parse(x['created_at']) <= (DateTime.parse(stuRec[i][j][:stime])-(0.1/24.0)) || DateTime.parse(x['created_at']) > (DateTime.parse(stuRec[i][j][:sbmtime]))

            if x['controller'].to_s == "files"# && (DateTime.parse(x['created_at']) >= DateTime.parse(stuRec[i][j][:stime]) && DateTime.parse(x['created_at']) <= DateTime.parse(stuRec[i][j][:sbmtime]))
              if x['url'].to_s.include?("download?download") || x['url'].to_s.include?("module_item_id")
                sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stuRec[i][j][:unit].to_s, stuRec[i][j][:stime].to_s, stuRec[i][j][:sbmtime].to_s, ipAns, browsAns], :types => [nil, nil, :string, :string, :string, :string, :string, :string, :string, :string, :string], :style => fileInBetween
            #elsif x['controller'].to_s == "files" && (DateTime.parse(x['created_at']) >= DateTime.parse(stuRec[i][j][:stime]) && DateTime.parse(x['created_at']) <= DateTime.parse(stuRec[i][j][:sbmtime]))
              elsif x['url'].to_s.include? "preview"
                sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stuRec[i][j][:unit].to_s, stuRec[i][j][:stime].to_s, stuRec[i][j][:sbmtime].to_s, ipAns, browsAns], :types => [nil, nil, :string, :string, :string, :string, :string, :string, :string, :string, :string], :style => acceptableFile
              else
                sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stuRec[i][j][:unit].to_s, stuRec[i][j][:stime].to_s, stuRec[i][j][:sbmtime].to_s, ipAns, browsAns], :types => [nil, nil, :string, :string, :string, :string, :string, :string, :string, :string, :string], :style => acceptableFile
              end
            #elsif x['url'].to_s.include?("ussr_id=xxxx") && xxxx !=  q['id']
            else
              sheet.add_row [x['url'], x['controller'], x['created_at'], x['user_agent'], x['participated'], x['remote_ip'], stuRec[i][j][:unit].to_s, stuRec[i][j][:stime].to_s, stuRec[i][j][:sbmtime].to_s, ipAns, browsAns], :types => [nil, nil, :string, :string, :string, :string, :string, :string, :string, :string, :string]
            end
          end
        end
        # add new line after each quiz results
        sheet.add_row [""]

        # rename sheet and add given name to sheetnames array
        if currstudent == '' || currstudent == "" || currstudent == ' ' || currstudent == " "
          currstudent = student['id'].to_s
          sheet.name = currstudent
        else
          sheet.name = currstudent
        end

        # Print to console
        puts "Info for " + q['title'].to_s + " recorded"

        # Create the Excel document
        p.serialize('/Users/lkangas/Documents/Tests/5011tifsesummer.xlsx')
        j = j + 1
        # Print to console
        # puts "submission info recorded for "+  student['sortable_name'] + " for " + q['title'].to_s
      else
        # Print to console
        #puts "test does not fit ASC's criteria"
      end
    end
    break if escape
  end
  puts currstudent+" done"
  puts count
  i = i + 1
end
puts "all done"
puts skipped
# Print matrix to console
# stuRec.each { |x|
#   puts x.join(" ")
# }
