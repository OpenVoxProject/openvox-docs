#!/usr/bin/env ruby
# USAGE:
#  ./linkmunger.rb [-n] <PATH>
# Takes a path to the folder acting as site root as argument, or else
# assumes it should treat the cwd as the site root.
# OPTIONS:
#  -n: run in no-op mode

def relativepath(path, relative_to)
  if path == relative_to
    return '.' if (path[-1] == '/') && (relative_to[-1] == '/')

    return File.basename(path)

  end

  if path == "#{relative_to}/"
    # from /a to /a/
    return File.basename(path) + '/'
  end

  if "#{path}/" == relative_to
    # from /a/ to /a
    return '../' + File.basename(path)
  end

  path = path.chomp('/')
  path = if path == ''
           ['']
         else
           # The negative limit ensures that empty values aren't dropped.
           path.split(File::SEPARATOR, -1)
         end

  relative_to = relative_to.chomp('/')
  relative_to = if relative_to == ''
                  ['']
                else
                  # The negative limit ensures that empty values aren't dropped.
                  relative_to.split(File::SEPARATOR, -1)
                end

  while path.length.positive? && (path.first == relative_to.first)
    path.shift
    relative_to.shift
  end

  if relative_to.empty? && path.empty?
    throw 'BUG: Processed paths were equivalent when raw paths were the same'
  elsif relative_to.empty?
    path.join(File::SEPARATOR)
  elsif path.empty? && (relative_to.length == 1)
    '.'
  else
    ((['..'] * (relative_to.length - 1)) + path).join(File::SEPARATOR)
  end
end

noop = ARGV.first == '-n'
if noop
  ARGV.shift
  puts 'Running in no-op mode'
end

Dir.chdir(ARGV.shift) if ARGV.first

regex = %r{
  (href|src)=
  # The first quote, which must be matched by the final quote
  (['"])
    # The value is either a single /, or it starts with / but not //, since
    # that's a URL with a host but no protocol. Sometimes it will incorrectly
    # have a quote that's different from the one that starts the attribute.
    (
      /(?:[^/'"].*?)?
    )
  # Look for a matching quote.
  \2
}xi

changed = 0
prev_dir = ''
Dir['**/*.html'].each do |page_path|
  if File.dirname(page_path) != prev_dir
    prev_dir = File.dirname(page_path)
    puts "Processing: #{prev_dir}/"
  end
  results = File.read(page_path).gsub(regex) do |_match|
    changed += 1
    "#{Regexp.last_match(1)}=#{Regexp.last_match(2)}" + relativepath(Regexp.last_match(3),
                                                                     '/' + page_path) + Regexp.last_match(2)
  end

  File.write(page_path, results) unless noop
end

puts "Updated #{changed} links"
