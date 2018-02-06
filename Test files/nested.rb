#!/usr/bin/env ruby
require 'canvas-api'
require 'json'
require 'axlsx'
require 'date'

students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
quizzes  = ["1A", "1B", "2A", "2B", "3A", "3B", "4A", "4B", "5A", "5B"]

i = 0
dnest = Array.new(10){Array.new(10)}
count = 0

students.each do |stu|
  j = 0
  quizzes.each do |q|
    dnest[i][j] = {:stime => "start", :sub => "subtime"}
    j = j + 1
    count = count + 1
  end
  i = i + 1
end

dnest.each { |x|
  puts x.join(" ")
}
#puts dnest
puts count
