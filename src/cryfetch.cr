#
# WARNING!!!!!!!!!!!!
# THE FOLLOWING CODE IS UNSTABLE! 
# IT CONTAINS VOODOO, AND WILL LIKELY WREAK 
# TOTAL YOTADEATH UPON THE MULTIVERSE
# USE AND MODIFY AT YOUR OWN RISK (of sanity)
# 

# Cryfetch
# A silly little neofetch clone for macOS
# Written in Crystal v1.12.1
# LLVM v18.1.4
# 
# Built with the Crystal compiler on macOS 14.4.1

require "system/user"
require "time"

APP_NAME  = "Cryfetch"
VERSION   = "alpha 0.4"
LICENSE   = "MIT License"
COPYRIGHT = "Copyright (c) 2024 Lilith Parker"

# silly struct for defining wtf these properties are supposed to be.
# also only using 4 character names because I like it when things are aligned
# and I don't feel like writing any more than I already have to.
struct SystemInfo
  property ausr : String
  property husr : String
  property opsy : String
  property kern : String
  property arch : String
  property time : String
  property pkgs : String
  property shll : String
  property cpux : String
  property gpux : String
  property ramx : String
  property intf : String
  property ipv4 : String
  property ipv6 : String

  def initialize(@ausr, @husr, @opsy, @kern, @arch, @time, @pkgs, @shll, @cpux, @gpux, @ramx, @intf, @ipv4, @ipv6); end
end

# version info, accessible with `-v`
def version_info
  puts "                                                "
  puts "  #{APP_NAME} Version #{VERSION}                "
  puts "  #{COPYRIGHT}                                  "
  puts "  Released and Distributed under the #{LICENSE} "
  puts "                                                "
end

# help info, accessible with `-h`
def help_info
  puts "  Usage: Cryfetch [options]                     "
  puts "                                                "
  puts "  Options                                       "
  puts "    Help Options                                "
  puts "    -h, --help: print this help message         "
  puts "    -v, --version: print version and exit       "
  puts "    -L, --license: print license and exit       "
  puts "                                                "
  puts "    Technical Options                           "
  puts "    -C, --cpu: print cpu info and exit          "
  puts "    -H, --host: print host info and exit        "
  puts "    -M, --memory: print memory info and exit    "
  puts "    -G, --gpu: print gpu info and exit          "
  puts "    -P, --path: print path info and exit        "
  puts "    -S, --shell: print shell info and exit      "
  puts "    -T, --terminal: print terminal info and exit"
end

# simple clock to check systems current uptime
def clck
  # fetch boot time from system
  boot_time_output = `sysctl -n kern.boottime`
  boot_time_match = boot_time_output.match(%r{\{ sec = (\d+),})
  boot_time = boot_time_match[1].to_i if boot_time_match

  if boot_time
    # literal magic, something to do with the UNIX Epoch
    now = Time.utc
    boot_time_obj = Time.utc(1970, 1, 1) + Time::Span.new(seconds: boot_time, nanoseconds: 0)
    uptime_seconds = now - boot_time_obj

    # basic math to convert seconds to days, hours, minutes
    days = uptime_seconds / (60 * 60 * 24)
    hours = (uptime_seconds.to_i / (60 * 60)) % 24
    minutes = (uptime_seconds.to_i / 60) % 60

    # make it pretty
    uptime = ""
    uptime += "#{days.to_i}d, " if days.to_i > 0
    uptime += "#{hours.to_i}h, " if hours > 0
    uptime += "#{minutes.to_i}m"

    uptime.chomp(", ")
  else
    # in the event that my system is even more cucked than it already is
    # return meaningless error message
    "Error: Failed to retrieve boot time."
  end
end

def pack : String
  package_counts = {} of String => Int32

  # Check if Brew is available
  brew_output = `which brew`
  if !brew_output.nil? && !brew_output.strip.empty?
    brew_packages_count_output = `brew list | wc -l`
    if brew_packages_count_output
      brew_packages_count = brew_packages_count_output.strip.chomp(".").to_i
      package_counts["brew"] = brew_packages_count
    end
  end

  # Check if MacPorts is available
  port_output = `which port`
  if !port_output.nil? && !port_output.strip.empty?
    macports_packages_count_output = `port installed | wc -l`
    if macports_packages_count_output
      macports_packages_count = macports_packages_count_output.strip.chomp(".").to_i
      package_counts["port"] = macports_packages_count
    end
  end

  # Check if pkgutil is available
  pkgutil_output = `which pkgutil`
  if !pkgutil_output.nil? && !pkgutil_output.strip.empty?
    pkgutil_packages_count_output = `pkgutil --packages | wc -l`
    if pkgutil_packages_count_output
      pkgutil_packages_count = pkgutil_packages_count_output.strip.chomp(".").to_i
      package_counts["pkgutil"] = pkgutil_packages_count
    end
  end

  # Generate the output string
  if package_counts.empty?
    "No package manager installed or no packages found"
  else
    package_counts.map { |k, v| "(#{k}) #{v}" }.join(", ")
  end
end

# why tf is i32 the default just make it i64
# there HAS to be an easier way to do this
# but macOS would rather contain the most cucked rewrites of GNU utilities
# rather than just having the God given easy to use GNU utilities
def ram : String
  hw_pagesize = `sysctl -n hw.pagesize`.strip.to_i64
  mem_total = (`sysctl -n hw.memsize`.strip.chomp(".").to_i64 / 1024 / 1024 / 1024).to_i64
  pages_app = (`sysctl -n vm.page_pageable_internal_count`.strip.chomp(".").to_i64 - `sysctl -n vm.page_purgeable_count`.strip.chomp(".").to_i64) # literally just me eating the string until it containes nothing but what is needed
  pages_wired = `vm_stat | awk '/ wired/ { print $4 }'`.strip.chomp(".").to_i64
  pages_compressed = `vm_stat | awk '/ occupied/ { printf $5 }'`.strip.chomp(".").to_i64 || 0
  mem_used = ((pages_app + pages_wired + pages_compressed) * hw_pagesize / 1024 / 1024 / 1024).to_i64
  mem_free = mem_total - mem_used
  "Total: #{mem_total} GB | Free: #{mem_free} GB | Used: #{mem_used} GB"
end

module SystemInfoFetcher
  extend self

  def fetch_info : SystemInfo
    ausr = System::User.find_by(name: ENV["USER"]).username # Extracting the name from System::User
    husr = "#{ausr}".strip("(501)").strip(" ") + "@#{`hostname`.strip}" # Stupid User (You)
    opsy = "#{`sw_vers | grep "ProductName:"`.strip("ProductName:").strip} " + " #{`sw_vers | grep "ProductVersion:"`.strip("ProductVersion:").strip}" # Why doesn't neofetch do this??? Does no one seriously know about sw_vers????????
    kern = "#{`uname`.chomp} " + "#{`uname -r`.strip}" # It's all Darwin? Always has been.
    arch = "#{`uname -m`.chomp}"
    time = clck
    pkgs = "#{pack}"
    # fetches launch shell because I couldn't be bothered to fetch the current user shell.
    # also because I didn't feel like adding support for Xonsh
    shll = `echo $SHELL`.strip
    # It's literally just Apple Silicon, what else do you want from me
    cpux = "#{`sysctl -a | grep brand`.strip("machdep.cpu.brand_string:").strip(" ").chomp}" + " // " + "#{System.cpu_count} Cores".chomp
    gpux = "#{`system_profiler SPDisplaysDataType | grep "Chipset Model:"`.strip("Chipset Model:")}".chomp
    ramx = "#{ram}"
    # Couldn't be bothered to read the networking docs for crystal
    intf = `ifconfig en0 | awk '/^[a-z]/ {print $1}'`.strip.strip(":")
    ipv4 = `ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}'`.strip
    ipv6 = `ifconfig en0 | grep inet6 | grep fe80 | awk '{print $2}'`.strip.strip("%en0")

    SystemInfo.new(ausr, husr, opsy, kern, arch, time, pkgs, shll, cpux, gpux, ramx, intf, ipv4, ipv6)
  end
end

# HOLY SHIT FUCKING IMPORTANT NOTE! 
# DUE TO THE WAY HEREDOC WORKS ON CRYSTAL, YOU MUST 
# ASCII ART NEED TO BE 13 LINES EXACTLY OR ELSE IT WILL RESULT IN AN INDEX OUT OF BOUNDS ERROR
def print_system_info(info : SystemInfo)
  ascii_art = <<-ASCII
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⡿⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⢀⣠⣤⣤⣤⣀⣀⠈⠋⠉⣁⣠⣤⣤⣤⣀⡀⠀⠀
    ⠀⢠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀
    ⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀
    ⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣀
    ⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁
    ⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀
    ⠀⠀⠀⠈⠙⢿⣿⣿⣿⠿⠟⠛⠻⠿⣿⣿⣿⡿⠋⠀⠀⠀  
  ASCII

  # done to allow for easy addition of more ascii variants
  info_str = <<-INFO
    user - #{info.husr}
    opsy - #{info.opsy}
    kern - #{info.kern}
    arch - #{info.arch}
    time - #{info.time}
    pkgs - #{info.pkgs}
    shll - #{info.shll}
     cpu - #{info.cpux}
     gpu - #{info.gpux}
     ram - #{info.ramx}
    intf - #{info.intf}
    ipv4 - #{info.ipv4}
  ipv6 - #{info.ipv6}
  INFO

  # Splitting the ASCII art into lines
  ascii_lines = ascii_art.chomp.split("\n")

  # Splitting the system info into lines
  info_lines = info_str.chomp.split("\n")

  # Pad the system info lines with spaces to align with ASCII art
  padded_info_lines = info_lines.map { |line| line.ljust(31) }

  # Combine ASCII art and system info
  combined_lines = ascii_lines.zip(padded_info_lines).map { |ascii_line, info_line| "#{ascii_line}    #{info_line}" }

  # Print the combined result
  puts combined_lines.join("\n")
end

def main
  if ARGV.empty? # done to fix 
    info = SystemInfoFetcher.fetch_info
    print_system_info(info)
  else
    case ARGV[0]
    when "-h"
      help_info
    when "-v"
      version_info
    else
      puts "Invalid option. Use '-h' for help."
    end
  end
end

main
