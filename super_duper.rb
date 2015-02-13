require 'pp'
require 'digest/sha1'
require 'optparse'

# run through directory hierarchy and identify duplicate files
def get_files()
    dir = $options[:directory] || "./"
    $options[:exclude_paths].map! { |path| File.join(dir, path) }

    output "Walking directory tree #{dir}\n"
    files = Hash.new { |h,k| h[k] = [] }
    inner_get_files_from_dir(dir, files)
    progress(true, "\n")
    return files
end

def inner_get_files_from_dir(dir, files)
    return if $options[:exclude_paths] && $options[:exclude_paths].include?(dir)
    Dir.foreach(dir) do |entry|
        next if entry == '.' || entry == '..'
        entry_path = File.join(dir, entry)
        if File.directory? entry_path then
            inner_get_files_from_dir entry_path, files
        else
            details = get_file_details(entry_path)

	    if files.has_key?(details[:short_digest]) && details[:full_digest].nil? then
            	full_digest = Digest::SHA1.file(details[:path]).hexdigest
            	details.merge!({:full_digest=>full_digest})
	    end
		
            files[details[:short_digest]] << details
            progress(files.size % 100 == 1, "\r- %d", files.size)
        end
    end
end

# get file details
# returns hash with file details and short hash for file contents
# hash contents are:
# :short_digest - sha1(first 4k + last 4k) if > 8k or sha1(content)
# :full_digest - sha1(file contents)
# :name - file basename
# :path - path to file
# :valid - true if file is a file
# :atime - access time
# :mtime - modify time
# :ctime - creation time
# :size - size
def get_file_details(file)
    details = {:short_digest => nil, :name => File.basename(file), :path => file, :valid => false}
    return details if !File.file? file
    stats = File.stat file
    short_digest = Digest::SHA1.new
    File.open(file) { |f|
        if stats.size < 8192 then
            short_digest << f.read
        else
            short_digest << f.read(4096)
            f.seek(-4096, IO::SEEK_END)
            short_digest << f.read(4096)
        end
    }
    details.merge!({:atime => stats.atime, :mtime => stats.mtime, :ctime => stats.ctime, 
                    :size => stats.size, 
                    :short_digest => short_digest.hexdigest, 
                    :full_digest => (stats.size < 8192) ? nil : short_digest.hexdigest 
                  })
end

def progress(flush, *args)
    if $options[:progress] then
        STDOUT.printf(*args)
        STDOUT.flush if flush
    end
end

def output(*args)
    return if $options[:quiet]
    STDOUT.printf *args
end

def print_dupes(hash)
    output "Detecting duplicates based on short hash from #{hash.size} files.\n"
    full_dupes = Hash.new { |h,k| h[k] = [] }
    hash.select { |k,v| v.size > 1 }.each { |short_hash, short_dupes|
        short_dupes.each { |details|
            full_dupes[details[:full_digest]] << details
            progress(full_dupes.size % 100 == 1, "\rDuplicates based on full digest: %d", full_dupes.size)
        }
    }
    progress(true, "\n")
    output "Detecting duplicates based on full hash from #{full_dupes.size} files:\n"

    full_dupes.select{ |k,v| v.size > 1}.each do |full_hash, full_dupes|
        puts "Duplicates for long hash #{full_hash}"
        full_dupes.sort_by { |e| e[:mtime] }.reverse.each do |details|
            puts "\tFile: #{File.join(details[:path], details[:name])} , Modified: #{details[:mtime]}, Size: #{details[:size]}"
        end
    end
end

$options = {quiet: false, progress: true, directory: './', exclude_paths:[]}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: super_duper.rb [options]"
  opts.on_tail("-h", "--help", "Run verbosely") { puts opts; exit 0}
  opts.on("-d", "--directory DIRECTORY", "Proceed from directory DIRECTORY (default: ./)") { |dir|
    $options[:directory] = dir.to_s
  }
  opts.on("-x", "--exclude PATH", "Exclude PATH and it's children from traversal. Use -x aaa -x bbb to ignore both aaa and bbb") { |path|
    $options[:exclude_paths] << path.to_s
  } 
  opts.on("-p", "--[no-]progress", "Suppress progress indicators (default: false)") { |progress|
    $options[:progress] = progress
  } 
  opts.on("-q", "--quiet", "Only output duplicates, no messages (default: false)") { $options[:quiet] = true }
end

begin
    opt_parser.parse(ARGV)
rescue OptionParser::ParseError => e
  puts e
  puts opt_parser
  exit 1
end
print_dupes(get_files)
exit 0
