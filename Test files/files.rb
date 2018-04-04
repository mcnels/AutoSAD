#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

# Use bearer token
canvas = Canvas::API.new(:host => "https://fit.instructure.com", :token => "1059~YUDPosfOLaWfQf4XVAsPavyXFYNjGnRHzqSbQuwFs6eQDANaeShDaGPVEDufVAEj")
course_id = "494716"

list_files = canvas.get("/api/v1/courses/" + course_id + "/folders/")
#files = Array.new(list_files['files_url'])
while list_files.more? do
  list_files.next_page!
end

folders = Array.new
subf = Array.new
files = Array.new

list_files.each do |file|
  # save needed folders in folders array
  if file['name'] == "Course Resources" || file['name'] == "Instructor Materials"
    folders.push(file['id'])
  end
end

folders.each do |f|
  sub = canvas.get("/api/v1/folders/"+ f.to_s + "/folders")
  while sub.more? do
    sub.next_page!
  end
  sub.each do |sub|
    # save needed sub folders in subf array
    if sub['name'] == "PPT" || sub['name'] == "Reading Assignment" || sub['name'] == "SAFMEDS" || sub['name'] == "StudyGuide" || sub['full_name'].include?("Instructor Materials")
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

files.each do |print|
  puts print[:name].to_s
end
#puts files.count