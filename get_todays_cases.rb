#!/usr/bin/env ruby
# encoding: utf-8

# Web Scraping according to http://ruby.bastardsbook.com/chapters/html-parsing/
# and http://ruby.bastardsbook.com/chapters/web-crawling/

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__==$0
	# Find the parent directory of this file and add it to the front
	# of the list of locations to look in when using require
	$:.unshift File.join(File.expand_path(File.dirname(__FILE__)))
end

# Require some gems
require "rubygems"
require "nokogiri"
require "open-uri"
require "fileutils"

# Where do we find the website and where are we located in the filesystem?
CORONA_UPDATES_IN_ESSEN = "https://www.essen.de/leben/gesundheit/corona_virus/coronavirus_updates.de.html"
WORKING_DIR = File.expand_path(File.dirname(__FILE__))

# Cross-platform way of finding an executable in the $PATH.
#   which('ruby') #=> /usr/bin/ruby
def which(cmd)
	exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
		exts.each { |ext|
			exe = File.join(path, "#{cmd}#{ext}")
			return exe if File.executable? exe
		}
	end
	return nil
end

# Setting the current cases to nil
@current_corona_cases_csv = nil
@current_corona_cases_html = nil
# Getting the website into Nokogiri
page                = Nokogiri::HTML(open(CORONA_UPDATES_IN_ESSEN))
# Getting todays date in the two required formats
todays_date_german  = Time.now.strftime("%d.%m.%Y")
todays_date_iso     = Time.now.strftime("%Y-%m-%d")
#todays_date_german  = "24.10.2020"
#todays_date_iso     = "2020-10-24"

# Getting all paragraphs from the website, stepping through them
page.css('p').each{ |p|
	# We are interested in paragraphs with bold headings, starting with todays date
	if p.css('strong').text.start_with?(todays_date_german)
		# We search for the number of todays cases and store it in a named
		# matching group
		result = /(sind|haben) in Essen \D*(?<number>\d*\.*\d*) Personen/.match(p.text)
		unless result.nil?
			# If we are here, we found a result and we store the number in instance variables,
			# removing the thousands seperator for our csv in the process
			@current_corona_cases_csv = result["number"].delete('^0-9')
			@current_corona_cases_html = result["number"]
			# We also store the date and time from the bold heading
			@current_date_and_time = DateTime.parse(p.css('strong').text).strftime("%Y-%m-%d, %H:%M")
		end
	end
}

# If we filled the instance variable, we proceed here
unless @current_corona_cases_csv.nil?
	# This is the new line for the csv
	csv_line  = "#{todays_date_iso},#{@current_corona_cases_csv}"
	# This is the new part of the html page
	html_text = "#{@current_date_and_time}: #{@current_corona_cases_html}."
	#p csv_line
	#p html_text

	# We search the last line in the csv file and check if we already wrote it today
	last_line = nil
	File.open('cases.csv').each do |line|
		last_line = line if(!line.chomp.empty?)
	end
	if last_line.start_with?(todays_date_iso)
		puts "Den Wert #{@current_corona_cases_html} vom #{todays_date_german} haben wir schon notiert."
	else
		puts "Wir notieren #{@current_corona_cases_html} vom #{todays_date_german} in HTML und CSV."

		# If we are here we append the new csv line to the csv file
		File.open('cases.csv', 'a') { |f|
			f.puts csv_line
		}

		# And we write a new html file by filling in the template and writing it
		# out to the html file.
		text = File.read('index.html.template')
		new_contents = text.gsub(/PLEASE_REPLACE_ME_WITH_CURRENT_DATA/, html_text)

		File.open('index.html', "w") {|f|
			f.puts new_contents
		}
	end # end if/else
else
	puts "Heute (#{todays_date_german}) noch keine neuen Zahlen online."
end # end unless
exit
