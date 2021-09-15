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
require "clipboard"

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
@current_vaccinations_csv = nil
@current_vaccinations_html = nil
@population_in_essen = 588812
# Getting the website into Nokogiri
page                = Nokogiri::HTML(open(CORONA_UPDATES_IN_ESSEN))
# Getting todays date in the two required formats
todays_date_german  = Time.now.strftime("%d.%m.%Y")
todays_date_iso     = Time.now.strftime("%Y-%m-%d")
#todays_date_german  = "19.07.2021"
#todays_date_iso     = "2021-07-19"

# Getting all paragraphs from the website, stepping through them
page.css('p').each{ |p|
	# We are interested in paragraphs with bold headings, starting with todays date
	if p.css('strong').text.start_with?(todays_date_german)
		# We search for the number of todays cases and store it in a named
		# matching group
		cases_result = /(sind|haben) in Essen \D*(?<number>\d*\.*\d*) Personen/.match(p.text)
		vaccinations_result = /(?<number>\d*\.*\d*) (Schutzimpfungen gegen das Coronavirus wurden|Personen wurden bisher( im Impfzentrum Essen)? gegen das Coronavirus in Essen geimpft|Personen in Essen gegen das Coronavirus geimpft|Personen, die in Essen gegen das Coronavirus geimpft sind)/.match(p.text)
		unless cases_result.nil?
			# If we are here, we found a result for cases and we store the numbers 
			# for cases and vaccinations in instance variables,
			# removing the thousands seperator for our csv in the process
			@current_corona_cases_csv = cases_result["number"].delete('^0-9')
			@current_corona_cases_html = cases_result["number"]
			@current_vaccinations_csv = vaccinations_result["number"].delete('^0-9')
			@current_vaccinations_html = vaccinations_result["number"]
			# We also store the date and time from the bold heading
			#@current_date_and_time = DateTime.parse(p.css('strong').text).strftime("%Y-%m-%d, %H:%M")
			@current_date_and_time = DateTime.parse("15.09.2021, 9:45").strftime("%Y-%m-%d, %H:%M")
		end
	end
}

# If we filled the instance variable for cases, we proceed here
unless @current_corona_cases_csv.nil?
	# This is the new part of the html page
	html_text = "#{@current_date_and_time}: #{@current_corona_cases_html}."
	vacc_count = "#{@current_vaccinations_html}"
	vacc_percent = (@current_vaccinations_csv.to_f / @population_in_essen.to_f * 100).round(2).to_s
	# This is the new line for the csv
	csv_line  = "#{todays_date_iso},#{@current_corona_cases_csv},#{@current_vaccinations_csv},#{vacc_percent}"
	#p csv_line
	#p html_text

	# We search the last line in the csv file and check if we already wrote it today
	last_line = nil
	File.open('cases.csv').each do |line|
		last_line = line if(!line.chomp.empty?)
	end
	if last_line.start_with?(todays_date_iso)
		puts "Die Werte #{@current_corona_cases_html} Fälle und #{@current_vaccinations_html} Impfungen vom #{todays_date_german} haben wir schon notiert."
	else
		puts "Wir notieren #{@current_corona_cases_html} Fälle und #{@current_vaccinations_html} Impfungen vom #{todays_date_german} in HTML und CSV."

		# If we are here we append the new csv line to the csv file
		File.open('cases.csv', 'a') { |f|
			f.puts csv_line
		}

		# And we write a new html file by filling in the template and writing it
		# out to the html file.
		text = File.read('index.html.template')
		new_contents = text.gsub(/PLEASE_REPLACE_ME_WITH_CURRENT_DATA/, html_text).gsub(/PLEASE_INSERT_CURRENT_VACCS_HERE/, vacc_count).gsub(/PLEASE_INSERT_CURRENT_VACC_PERCENTAGE_HERE/, vacc_percent)

		File.open('index.html', "w") {|f|
			f.puts new_contents
		}

		# And we put a nice commit line in our clipboard
		commit_line = "g ci -am \"Now at #{@current_corona_cases_html} cases and #{@current_vaccinations_html} vaccinations.\""
		Clipboard.copy(commit_line)
	end # end if/else
else
	puts "Heute (#{todays_date_german}) noch keine neuen Zahlen online."
end # end unless
exit
