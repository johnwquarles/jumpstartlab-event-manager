require 'csv'
require 'sunlight/congress'
require 'erb'
require 'time'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("../output") unless Dir.exists?("../output")

  filename = "../output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def dasherize_phone(phone_number)
  return phone_number.insert(6, "-").insert(3, "-")
end

def clean_phone(phone_number)
  digits = []
  phone_number.split('').each {|char| digits << char if ("0".."9").include?(char)}
  return dasherize_phone("0000000000") if ( digits.length < 10 || digits.length > 11 || (digits.length == 11 && digits[0] != "1") )
  if digits.length == 11 && digits[0] == "1"
    digits.shift
    return dasherize_phone(digits.join(''))
  end
  return dasherize_phone(digits.join(''))
end

def save_phone_numbers(first_name, last_name, phone_number)
  filename = "../output/phone_numbers.txt"
  File.open(filename, 'a') do |file|
    name = "#{last_name}, #{first_name}:"
    file.printf "%-20s %s\n", name, phone_number
  end
end

def save_reg_info(hash, filename)
  filename = "../output/registration_analysis_#{filename}.txt"
  File.open(filename, 'w') do |file|
    hash.sort_by {|key, value| -value}.each do |key, value| 
      plural = ""
      plural = "s" if value > 1
      file.printf "%-10s %s\n", "#{key}:", "#{value} registration#{plural}"
      #file.puts "#{key}: #{value} registration#{plural}"
    end
  end
end

puts "EventManager initialized."

contents = CSV.open '../event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "../form_letter.erb"
erb_template = ERB.new template_letter

days = Hash.new(0)
hours = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letters(id,form_letter)
  
  last_name = row[:last_name]
  phone_number = clean_phone(row[:homephone])
  save_phone_numbers(name, last_name, phone_number)
  
  reg_date = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
  hours[reg_date.strftime('%l %p')] += 1
  days[reg_date.strftime('%A')] += 1
end

save_reg_info(days, "days")
save_reg_info(hours, "hours")

