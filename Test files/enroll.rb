#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")
course_id = "521612"

users = canvas.get("/api/v1/courses/" + course_id + "/search_users", {'enrollment_type[]' => 'student', 'enrollment_state[]' => 'invited'})

while users.more? do
  users.next_page!
end

puts users
puts users.count

puts ""
enroll = canvas.get("/api/v1/courses/" + course_id + "/enrollments", {'type[]' => 'StudentEnrollment', 'state[]' => 'active'})

while enroll.more? do
  enroll.next_page!
end

# puts enroll
# puts enroll.count

files = Array.new
enr = Array.new
exc = Array.new
users.each do |file|
  # save needed folders in folders array
  # if file['name'] == "Course Resources" || file['name'] == "Instructor Materials"
    files.push(file['id'].to_s)
  # end
end
puts files.count
 #puts files

# enroll.each do |e|
#     enr.push(e['user_id'].to_s)
# end
# puts enr.count

# (enr - files) | (files - enr)
# puts exc.count
# puts files

# list_files = canvas.get("/api/v1/courses/" + course_id + "/folders/")
# #files = Array.new(list_files['files_url'])
# while list_files.more? do
#   list_files.next_page!
# end
#
# enrolls = Array.new
# subf = Array.new
# files = Array.new
# list_files.each do |file|
#   # save needed folders in folders array
#   if file['name'] == "Course Resources" || file['name'] == "Instructor Materials"
#     folders.push(file['id'])
#   end
# end
