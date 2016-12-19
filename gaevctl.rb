#!/usr/bin/env ruby

Usage =<<"__HERE__"

gaevctl helps you to dealing with GAE version management.
It list, delete versions squeezed by time based queries.

Usage:
  gaevctl.rb <command> <sort> <num>

  List versions:
    gaevctl.rb list older 20
    gaevctl.rb list newer 20

  Delete versions:
    gaevctl.rb delete older 20

  Delete versions by time passed since last-deployed (recommended)
    gaevctl.rb delete passed 7d
    gaevctl.rb delete passed 2w

Note:
  Deleteing command never deletes working versions whose TRAFFIC_SPLIT more than 0,
  nor bulit-in version whose name include "builtin".

__HERE__


GET_LIST = "gcloud app versions list"
DELETE_VERSION = "gcloud app versions delete \"%s\" -q" # delete without confirmation

CACHE_LIFETIME = 3 * 60 # sec

require "time"


def main
	cmd, sort, num = ARGV
	if (!cmd && !sort) || cmd == "help"
		puts Usage
		exit 1
	end

	sorted = Object.send sort.to_sym, src, num
	Object.send cmd.to_sym, sorted
end

def list s
	puts s
end

def delete s
	s.each { |line|
		v = col line, :version

		if col(line, :traffic_split).to_f != 0
			puts "\nskipping (traffic-splitted)", "#{line}\n\n"
		elsif v.match(/(builtin|main)/)
			puts "\nskipping (builtin)", "#{line}\n\n"
		else
			puts "deleting.. ", line
			cmd = sprintf DELETE_VERSION, v
			puts `#{cmd}`
		end
	}
end

def src
	s = touch_cache
	unless s
		s = `#{GET_LIST}`
		File.open("#{__FILE__}.cache.#{Time.now.to_i}", "w+") {|f| f.puts s}
	end
	s = s.split(/\n/)
	s.shift if s[0].match(/^SERVICE/)
	s
end

def touch_cache
	s = nil
	f = Dir.glob("#{__FILE__}.cache.*").last
	if f
		lifetime = f.match(/\.(\d+)$/)[-1].to_i
		if lifetime > Time.now.to_i - CACHE_LIFETIME
			s = File.read f
		else
			File.delete f
		end
	end
	s
end

def passed s, num
	unit = case num[-1]
	       when "w" then 7 * 24 * 60 * 60
	       when "d" then 24 * 60 * 60
	       when "h" then 60 * 60
	       when "m" then 60
	       else 1
	       end
	th = Time.now.to_i - num.to_i * unit
	s.find_all {|line|
		Time.parse(col(line, :last_deployed)).to_i < th
	}
end

def older s, num
	s.sort! { |a, b| col(a, :last_deployed) <=> col(b, :last_deployed) }
	s = s[0..((num.to_i) - 1)] if num
	s
end

def newer s, num
	s.sort! { |a, b| col(b, :last_deployed) <=> col(a, :last_deployed) }
	s = s[0..((num.to_i) - 1)] if num
	s
end

def col line, part
	keys = [:service, :version, :traffic_split, :last_deployed, :serving_status]
	cols = line.split(/\s+/)
	if keys.include? part
		cols[keys.index part]
	else
		cols
	end
end

if __FILE__ == $0
	main
end
