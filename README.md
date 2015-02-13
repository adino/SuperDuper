# SuperDuper
Detects duplicate files on the filesystem by calculating SHA1 digest. All files matching same digest are printed out as result. Script first calculates short digest. Short digest is calculated on full file body if it's shorter than 8 kilobytes and or takes first 4 and last 4 kilobytes from longer files. Only when file is longer than 8kilobytes and short digest indicates collisions the full digest is calculated on the full file. 

## Usage
```
:!ruby ./super_duper.rb -h
Usage: super_duper.rb [options]
    -d, --directory DIRECTORY        Proceed from directory DIRECTORY (default: ./)
    -x, --exclude PATH               Exclude PATH and it's children from traversal. Use -x aaa -x bbb to ignore both aaa and bbb
    -p, --[no-]progress              Suppress progress indicators (default: false)
    -q, --quiet                      Only output duplicates, no messages (default: false)
    -h, --help                       Run verbosely
``` 
