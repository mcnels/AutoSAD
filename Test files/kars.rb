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
end_time = DateTime.parse("2018-04-26T00:00:00-00:00") # careful when setting this as there might be a difference because of the timezones (3 am instead of midnight)
#end_time = DateTime.now

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")

# Get all students/ might need to change this and get students from sections endpoint so to get remove transfers and withdrawals
list_student = canvas.get("/api/v1/courses/" + course_id + "/students")
# only gets active students (pending removed)
# list_student = canvas.get("/api/v1/courses/" + course_id + "/search_users", {'enrollment_type[]' => 'student', 'enrollment_state[]' => 'active'})
students = Array.new(list_student)

list_pending = canvas.get("/api/v1/courses/" + course_id + "/search_users", {'enrollment_type[]' => 'student', 'enrollment_state[]' => 'invited'})
while list_pending.more? do
  list_pending.next_page!
end
pending = Array.new(list_pending)

# Create workbook for student
p = Axlsx::Package.new

# Get the quizzes
quiz_list = canvas.get("/api/v1/courses/" + course_id + "/quizzes", {'per_page' => '100'})

# Get all the quizzes
while quiz_list.more? do
  quiz_list.next_page!
end

# there should be a better way for this, otherwise I would have to specify the amount of tests to check for every time
# I should have a condition here that looks at the course ID to determine a tentative size for the array... or not
stuRec = Array.new((students.size)+1){Array.new(19)}

# array containing all students skipped during check
skipped = Array.new
# array containing id of the bonus tests
bonusTests = Array.new

# arrays for file system
folders = Array.new
subf = Array.new
files = Array.new
pumpkin = Array.new

list_files = canvas.get("/api/v1/courses/" + course_id + "/folders/")
while list_files.more? do
  list_files.next_page!
end

list_files.each do |fi|
  # save needed folders in folders array
  if fi['name'] == "Course Resources" || fi['name'] == "Instructor Materials"
    folders.push(fi['id'])
  end
end

folders.each do |fol|
  sub = canvas.get("/api/v1/folders/"+ fol.to_s + "/folders")
  while sub.more? do
    sub.next_page!
  end
  sub.each do |sub|
    # save needed sub folders in subf array
    if sub['name'] == "PPT" || sub['name'] == "ReadingAssignment" || sub['name'] == "SAFMEDS" || sub['name'] == "StudyGuide" || sub['full_name'].include?("Instructor Materials")
      subf.push(sub['id'])
    end
  end
end

subf.each do |sf|
  docs = canvas.get("/api/v1/folders/"+ sf.to_s + "/files")
  while docs.more? do
    docs.next_page!
  end
  docs.each do |doc|
    # save needed files' urls in files array
    files.push(:id => doc['id'], :name => doc['filename'])
  end
end

conflict = ""
i = 1 # index student in the response
count = 0 # count of students

#For each student in the course, do this...
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
  j = 1 # index quiz in the response

  currstudent = ""
  count = count + 1
  suspicious = false
  # next if count < 283 || count > 285 # if we need to start at a specific position in the list of students

  # Create a worksheet for current student
  p.workbook.add_worksheet do |sheet|
    # Get page views activity for each student who submitted a quiz
    page_views = canvas.get("/api/v1/users/" + user_id + "/page_views?", {'start_time'=> period_start, 'end_time' => end_time, 'per_page' => '100'})

    # Keep loading the page views till we get them all!
    while page_views.more?  do
      page_views.next_page!
    end

    escape = false

    # Define styles
    fileInBetween = sheet.styles.add_style :bg_color => "ffec8b", :fg_color => "cd3700", :b => true
    unacceptableTest = sheet.styles.add_style :fg_color => "cd3700", :b => true
    separation = sheet.styles.add_style :bg_color => "7a1818", :fg_color => "ffffff", :b => true
    headers = sheet.styles.add_style :bg_color => "e5c5c5", :fg_color => "f30505", :b => true

    # Print header row in Excel worksheet
    sheet.add_row ["URL", "Created At", "IP used", "Browser used", "Unit Test", "controller", "remote_ip", "user_agent", "participated", "file name"], :style => headers

    # Get all unit tests for course (this filters the list receives fro only the ones we want to check)
    quiz_list.each do |q|
      # Applying the filters...
      if (q['title'].include? "Test A") || (q['title'].include? "Test B")
        # Save ids of bonus tests in array for later comparison
        if q['title'].include? "Bonus"
          bonusTests.push(q['id'].to_s)
        end
        # skip bonus and proctored tests
        next if (q['title'].include? "Bonus") || (q['title'].include? "Proctored")
        quiz_id = q['id'].to_s

        if DateTime.parse(q['due_at'].to_s) > end_time && q['title'] == "Unit 9 Test B"
          escape = true
        end

        # Skip checking tests whose due dates are before the period start (q['lock_info']['lock_at'].to_s) | not all quizzes have this info... be careful
        next if DateTime.parse(q['due_at'].to_s) < DateTime.parse(period_start.to_s) #subject to change/need to check how due dates are received compared to how they are on the website
        # Skip checking tests whose due dates are after end_time
        break if DateTime.parse(q['due_at'].to_s) > end_time && q['title'] == "Unit 9 Test B" # or if escape is true
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
            currstudent = student['sortable_name'] # might need to change this to username
            break if submission['started_at'].nil? || submission['finished_at'].nil?

            # Print to console
            puts currstudent+" started"
            stuRec[i][j] = {:stime => submission['started_at'], :sbmtime => submission['finished_at'], :unit => q['title']}
            tookTest = "Y"
            break if tookTest == "Y"
          end
        end

        # if the student didn't take the test or for some reason the information is missing
        if tookTest == "N"
            currstudent = student['sortable_name'] # might need to change this to username
            puts currstudent+" started"
            stuRec[i][j] = {:stime => "missing", :sbmtime => "missing", :unit => q['title']}
        end
        # block separator
        sheet.add_row [stuRec[i][j][:unit].to_s + " Block", "Start time: ", stuRec[i][j][:stime].to_s, "Submission time: " + stuRec[i][j][:sbmtime].to_s], :types => [:string, :string, :string, :string], :style => separation

        # If there's no record then write "missing" to the worksheet
        if  stuRec[i][j][:stime] == "missing" || stuRec[i][j][:sbmtime] == "missing"
          sheet.add_row ["missing"], :types => [:string]
          #sheet.add_row ["", "", "", "", "", "", "", "", "", "", ""], :style => separation
        else
          # arrays containing ips and browsers
          ipArray = Array.new
          browsArray = Array.new

          ipAns = 1
          browsAns = 1

          # Print the page views activity for the period between the start time and the submission time
          page_views.each do |x|
            # Skip if activity is not between 6 minutes before start time and submission time
            next if DateTime.parse(x['created_at']) < (DateTime.parse(stuRec[i][j][:stime])) || DateTime.parse(x['created_at']) > (DateTime.parse(stuRec[i][j][:sbmtime]))

            # Keep track of IPs
            newIP = true
            if ipArray.empty?
              newIP = false
              ipArray.push("IP "+ipAns.to_s+"   "+x['remote_ip'].to_s)
            else
              ipArray.each do |ip|
                if ip.to_s.include? x['remote_ip'].to_s
                  newIP = false
                  ipArray.push(ip.to_s)
                end
                break if ip.to_s.include? x['remote_ip'].to_s
              end
            end

            if newIP
              ipAns = ipAns + 1
              ipArray.push("IP "+ipAns.to_s+"    "+x['remote_ip'].to_s)
            end

            # Keep track of Browsers
            newBrows = true
            if browsArray.empty?
              newBrows = false
              browsArray.push("Brows "+browsAns.to_s+"   "+x['user_agent'].to_s)
            else
              browsArray.each do |brows|
                if brows.to_s.include? x['user_agent'].to_s
                  newBrows = false
                  browsArray.push(brows.to_s)
                end
                break if brows.to_s.include? x['user_agent'].to_s
              end
            end

            if newBrows && !(x['user_agent'].to_s.include? "RPNow")
              browsAns = browsAns + 1
              browsArray.push("Brows "+browsAns.to_s+"    "+x['user_agent'].to_s)
            end

            # File case
            fileFound = false
            if x['controller'].to_s == "files"
              files.each do |susp|
                if x['url'].to_s.include?(susp[:id].to_s)
                  fileFound = true
                  sheet.add_row [x['url'], x['created_at'], ipArray[-1][0..5], browsArray[-1][0..8], stuRec[i][j][:unit].to_s, x['controller'], x['remote_ip'], x['user_agent'], x['participated'], susp[:name].to_s], :types => [nil, :string, :string, nil, nil, :string, :string, :string, :string, :string, :string], :style => fileInBetween
                  sheet.sheet_pr.tab_color = "cd3700"
                  suspicious = true
                end
                break if x['url'].to_s.include?(susp[:id].to_s)
              end
              unless fileFound
                sheet.add_row [x['url'], x['created_at'], ipArray[-1][0..5], browsArray[-1][0..8], stuRec[i][j][:unit].to_s, x['controller'], x['remote_ip'], x['user_agent'], x['participated'], ""], :types => [nil, :string, :string, nil, nil, :string, :string, :string, :string, :string, :string]
              end

            # access submission for A while taking B
            elsif x['url'].to_s.include?("quizzes")
              hasBonus = false
              bonusTests.each do |bonus|
                if x['url'].to_s.include?(bonus)
                  hasBonus = true
                  break if hasBonus
                end
              end
              # Bonus tests are acceptable
              if hasBonus || x['url'].to_s.include?(q['id'].to_s)
                sheet.add_row [x['url'], x['created_at'], ipArray[-1][0..5], browsArray[-1][0..8], stuRec[i][j][:unit].to_s, x['controller'], x['remote_ip'], x['user_agent'], x['participated'], ""], :types => [nil, :string, :string, nil, nil, :string, :string, :string, :string, :string, :string]
              else
                sheet.add_row [x['url'], x['created_at'], ipArray[-1][0..5], browsArray[-1][0..8], stuRec[i][j][:unit].to_s, x['controller'], x['remote_ip'], x['user_agent'], x['participated'], ""], :types => [nil, :string, :string, nil, nil, :string, :string, :string, :string, :string, :string], :style => unacceptableTest
                sheet.sheet_pr.tab_color = "cd3700"
                suspicious = true
              end

            # regular case
            else
              sheet.add_row [x['url'], x['created_at'], ipArray[-1][0..5], browsArray[-1][0..8], stuRec[i][j][:unit].to_s, x['controller'], x['remote_ip'], x['user_agent'], x['participated'], ""], :types => [nil, :string, :string, nil, nil, :string, :string, :string, :string, :string, :string]
            end
          end

          ipArray.clear
          browsArray.clear
        end

        # rename sheet and add given name to sheetnames array
        if currstudent == '' || currstudent == "" || currstudent == ' ' || currstudent == " " || currstudent.to_s.include?("?") || currstudent.to_s.include?("'") || currstudent.to_s.include?("/") #|| currstudent.to_s.include?("\")
          currstudent = student['id'].to_s
          sheet.name = currstudent
        else
          sheet.name = currstudent
        end

        # Hide columns that are not immediately needed
        sheet.column_info[4].hidden = true
        sheet.column_info[5].hidden = true
        sheet.column_info[6].hidden = true
        sheet.column_info[7].hidden = true
        sheet.column_info[8].hidden = true
        #sheet.column_info[9].hidden = true # filename column

        # Print to console
        puts "Info for " + q['title'].to_s + " recorded"

        # Create the Excel document
        p.serialize('/Users/lkangas/Documents/Tests/5012_42818.xlsx')
        j = j + 1
      else
        # Print to console
        #puts "test does not fit ASC's criteria"
      end
    end
    break if escape
  end

  # Push cheaters' names to pumpkin array
  if suspicious
    pumpkin.push(currstudent)
  end

  puts currstudent+" done"
  puts count
  i = i + 1
end
puts "all done"

# Write cheaters' names to txt file
File.open("5012_43018.txt", 'w+') do |f|
  f.puts(pumpkin)
end
puts skipped
# Print matrix to console
# stuRec.each { |x|
#   puts x.join(" ")
# }
