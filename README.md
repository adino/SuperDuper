# SuperDuper
Detects duplicate files on the filesystem by calculating SHA1 digest. All files matching same digest are printed out as result. Script first calculates short digest. Short digest is calculated on full file body if it's shorter than 8 kilobytes and or takes first 4 and last 4 kilobytes from longer files. Only when file is longer than 8kilobytes and short digest indicates collisions the full digest is calculated on the full file. 

## Usage
```
ruby ./super_duper.rb -h
Usage: super_duper.rb [options]
    -d, --directory DIRECTORY        Proceed from directory DIRECTORY (default: ./)
    -x, --exclude PATH               Exclude PATH and it's children from traversal. Use -x aaa -x bbb to ignore both aaa and bbb
    -p, --[no-]progress              Suppress progress indicators (default: false)
    -q, --quiet                      Only output duplicates, no messages (default: false)
    -h, --help                       Run verbosely
``` 

## Example
```
ruby ./super_duper.rb 
Walking directory tree ./
- 50
Detecting duplicates based on short hash from 50 files.
Duplicates based on full digest: 2
Detecting duplicates based on full hash from 2 short digest collisions:
Duplicates for full_digest b79da879f6fc4581a0735565ef93b9a54c4b031b
        File: ./.git/refs/remotes/origin/master/master , Modified: 2015-02-13 10:39:14 +0000, Size: 41
        File: ./.git/refs/heads/master/master , Modified: 2015-02-13 10:38:51 +0000, Size: 41
Duplicates for full_digest dd3488b3b032e4ca3e740c0823fbaa33fac2f1e5
        File: ./.git/logs/HEAD/HEAD , Modified: 2015-02-13 10:38:51 +0000, Size: 706
        File: ./.git/logs/refs/heads/master/master , Modified: 2015-02-13 10:38:51 +0000, Size: 706
```
