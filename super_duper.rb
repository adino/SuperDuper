require 'pp'
require 'digest/sha1'

# run through directory hierarchy and identify duplicate files
def get_files_from_dir(dir)
    STDOUT.printf "Walking directory tree:"
    STDOUT.flush
    files = Hash.new { |h,k| h[k] = [] }
    inner_get_files_from_dir(dir, files)
    STDOUT.printf "\n"
    return files
end

def inner_get_files_from_dir(dir, files)
    Dir.foreach(dir) do |entry|
        next if entry == '.' || entry == '..'
        entry_path = File.join(dir, entry)
        if File.directory? entry_path then
            inner_get_files_from_dir entry_path, files
        else
            details = get_file_details(entry_path)
            files[details[:short_digest]] << details
            STDOUT.printf "\rWalking directory tree: %d", files.size
            STDOUT.flush if files.size % 100 == 1
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
    details.merge!({:atime => stats.atime, :mtime => stats.mtime, :ctime => stats.ctime, :size => stats.size, 
                    :short_digest => short_digest.hexdigest, :full_digest => nil})
end

def print_dupes(hash)
    STDOUT.printf "Detecting duplicates based on short hash from #{hash.size} files.\n"
    full_dupes = Hash.new { |h,k| h[k] = [] }
    hash.select { |k,v| v.size > 1 }.each { |short_hash, short_dupes|
        short_dupes.each { |details|
            full_digest = Digest::SHA1.file(details[:path]).hexdigest
            full_dupes[full_digest] << details.merge!({:full_digest=>full_digest})
            STDOUT.printf "\rCalculating full digest: %d", full_dupes.size
            STDOUT.flush if full_dupes.size % 100 == 1
        }
    }
    STDOUT.printf "\n"
    STDOUT.printf "Detecting duplicates based on full hash from #{full_dupes.size} files:\n"
    STDOUT.flush

    full_dupes.select{ |k,v| v.size > 1}.each do |full_hash, full_dupes|
        puts "Duplicates for long hash #{full_hash}"
        full_dupes.sort_by { |e| e[:mtime] }.reverse.each do |details|
            puts "\tFile: #{File.join(details[:path], details[:name])} , Modified: #{details[:mtime]}, Size: #{details[:size]}"
        end
    end
end

def usage
    puts "\nruby super_duper.rb [-h|--help] [<directory>]"
    puts "  <directory> where to look for duplicates (default: .)"
end
 
if ARGV[0]=='--help' || ARGV[0]=='-h' then
    usage
    exit 0
end

dir = ARGV[0] || '.'

print_dupes(get_files_from_dir(dir))
