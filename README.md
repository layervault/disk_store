# DiskStore

[![Travis CI](https://travis-ci.org/layervault/disk_store.png?branch=master)](https://travis-ci.org/layervault/disk_store)

DiskStore is a way of caching large files to disk in Ruby. Unlike ActiveSupport::Cache::Store,
which is designed primarily for storing values of strings, DiskStore is meant for
caching files to disk.

DiskStore stores the files on disk in a very similar way to Rails' [ActiveSupport::Cache::FileStore](http://api.rubyonrails.org/classes/ActiveSupport/Cache/FileStore.html).

## Installation

```ruby
gem 'disk_store'
```

## Usage

You should use this in a similar way that you would use most Ruby caching libraries. Instead
of passing around string values to cache, you should pass around IO objects. Here are a few
examples.

### Setup

DiskStore requires a directory to to store the files.

It has two parameters:

* The first is the path to the cache directory. If no directory is given, then the current directory is used.
* The second is an options hash that controls the Reaper. More info below.

```ruby
cache = DiskStore.new("path/to/my/cache/directory")
```

#### Reaper

By default, DiskStore does not perform any evictions on files in the cache. Be careful with this, because
it can cause your disk to fill up if left to its own means.

The reaper configuration includes:

* `cache_size`: The maximum size of the cache before the reaper begins to evict files.
* `reaper_interval`: How often the reaper will check for files to evict (in seconds).
* `eviction_strategy`: Sets how the reaper will determine which files to evict.

Current available eviction strategies are:

* LRU (least recently used) - deletes the files with the oldest last access time

To configure DiskStore with an LRU eviction strategy:

``` ruby
cache = DiskStore.new('cache/dir', eviction_strategy: :LRU)
```

### Reading

```ruby
cache = DiskStore.new
cached_file = cache.read("my_cache_key") #=> File.open('somewhere_on_disk')
```

### Writing

```ruby
cache = DiskStore.new
cache.write("my_cache_key", File.open('file.psd', 'rb'))
```

### Fetching

```ruby
cache = DiskStore.new
cache.fetch("my_cache_key") do
  File.open('file.psd', 'rb')
end
```

This is where it gets cool. You can also feed it other IO classes.
Here we cache the result of a file download onto disk.

```ruby
cache = DiskStore.new
cache.fetch("my_other_cache_key") do
  open("https://layervault.com/cats.gif")
end
```

### Deleting

```ruby
cache = DiskStore.new
cache.delete("my_cache_key") #=> true
```
