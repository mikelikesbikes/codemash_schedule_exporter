require 'rubygems'
require 'csv'
require 'json'
require 'ostruct'
require 'open-uri'
require 'delegate'
require 'active_support'
require 'active_support/time'
require 'active_support/time_with_zone'
Time.zone = "Eastern Time (US & Canada)"

class SessionList
  def self.fetch
    fetch_json.map do |session|
      Session.new(session.convert_keys(:underscore))
    end
  end

  private

  def self.fetch_json
    JSON.parse(open("http://rest.codemash.org/api/sessions.json").read)
  end
end

MASTER_SCHEDULE = Hash[{
  "2013-01-08 7:00AM" => "2013-01-08 8:30AM",
  "2013-01-08 8:30AM" => "2013-01-08 12:30AM",
  "2013-01-08 12:30PM" => "2013-01-08 1:30PM",
  "2013-01-08 1:30PM" => "2013-01-08 5:30PM",
  "2013-01-08 6:00PM" => "2013-01-08 8:00PM",
  "2013-01-09 7:00AM" => "2013-01-09 8:30AM",
  "2013-01-09 8:30AM" => "2013-01-09 12:30PM",
  "2013-01-09 12:30PM" => "2013-01-09 1:30PM",
  "2013-01-09 1:30PM" => "2013-01-09 5:30PM",
  "2013-01-09 5:30PM" => "2013-01-09 7:00PM",
  "2013-01-09 7:00PM" => "2013-01-09 8:30PM",
  "2013-01-10 7:00AM" => "2013-01-10 8:00AM",
  "2013-01-10 8:15AM" => "2013-01-10 9:30AM",
  "2013-01-10 9:45AM" => "2013-01-10 10:45AM",
  "2013-01-10 11:00AM" => "2013-01-10 12:00PM",
  "2013-01-10 12:15PM" => "2013-01-10 1:30PM",
  "2013-01-10 1:45PM" => "2013-01-10 2:45PM",
  "2013-01-10 3:00PM" => "2013-01-10 3:20PM",
  "2013-01-10 3:35PM" => "2013-01-10 4:35PM",
  "2013-01-10 4:50PM" => "2013-01-10 5:50PM",
  "2013-01-10 6:00PM" => "2013-01-10 7:00PM",
  "2013-01-10 7:00PM" => "2013-01-11 2:00AM",
  "2013-01-11 8:15AM" => "2013-01-11 9:15AM",
  "2013-01-11 9:30AM" => "2013-01-11 10:30AM",
  "2013-01-11 10:45AM" => "2013-01-11 11:45AM",
  "2013-01-11 12:00PM" => "2013-01-11 1:30PM",
  "2013-01-11 1:45PM" => "2013-01-11 2:45PM",
  "2013-01-11 3:00PM" => "2013-01-11 3:20PM",
  "2013-01-11 3:35PM" => "2013-01-11 4:35PM",
  "2013-01-11 4:40PM" => "2013-01-11 5:40PM",
  "2013-01-11 6:00PM" => "2013-01-11 8:00PM",
  "2013-01-11 8:00PM" => "2013-01-11 11:00PM"} \
  .map { |k, v| [Time.zone.parse(k), Time.zone.parse(v)] }]

class Session < OpenStruct
  # [:title, :abstract, :start, :end, :room, :difficulty, :speaker_name, :technology, :uri, :event_type, :id, :session_lookup_id, :speaker_uri]
  def to_row
    # ["Session Title", "Date", "Time Start", "Time End", "Room/Location", "Schedule Track (Optional)", "Description (Optional)"]
    [:title_with_speaker_name, :date, :start_time, :end_time, :room, :technology, :abstract].map { |method|
      self.send(method)
    }
  end

  def title_with_speaker_name
    "#{speaker_name}: #{title}"
  end

  def date
    Time.zone.parse(self.start).strftime("%m/%d/%Y")
  end

  def start_time
    Time.zone.parse(self.start).strftime("%l:%M %p").strip if self.start
  end

  def end_time
    time = self.end.nil? ? MASTER_SCHEDULE[Time.zone.parse(self.start)] : Time.zone.parse(self.end)
    puts self unless time
    time.strftime("%l:%M %p").strip if time
  end
end

class SessionListCSV
  HEADERS = ["Session Title", "Date", "Time Start", "Time End", "Room/Location", "Schedule Track (Optional)", "Description (Optional)"]

  def initialize(session_list)
    @session_list = session_list
  end

  def generate
    CSV.generate do |csv|
      csv << HEADERS
      @session_list.each do |session|
        csv << session.to_row
      end
    end
  end
end

class String
  def underscore
    self.gsub(/::/, '/') \
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2') \
        .gsub(/([a-z\d])([A-Z])/,'\1_\2') \
        .tr("-", "_") \
        .downcase
  end
end

class Symbol
  def underscore
    self.to_s \
        .gsub(/::/, '/') \
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2') \
        .gsub(/([a-z\d])([A-Z])/,'\1_\2') \
        .tr("-", "_") \
        .downcase \
        .to_sym
  end
end

class Hash
  def convert_keys(method = :identity, &block)
    new_map = self.map do |k,v|
      key = if block_given?
              yield k
            else
              k.send(method)
            end
      [key, v]
    end
    Hash[new_map]
  end
end

class Object
  def identity
    self
  end
end

list = SessionList.fetch
File.open("./codemash_schedule.csv", "w") do |file|
  file << SessionListCSV.new(list).generate
end
