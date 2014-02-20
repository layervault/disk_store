# DiskStore

DiskStore is a way of caching large files to disk in a Ruby (and perhaps Rails) like manner.
Rather than passing around strings though, DiskStore passing around Ruby `IO` objects.

## Installation

```ruby
gem 'disk_store'
```

## Usage

You should use this in a similar way that you would use most Ruby caching libraries. Instead 
of passing around string values to cache, you should pass around IO objects. Here are a few
examples.

### Setup

DiskStore requires a directory to to store the files. It stores the files on disk in a very 
similar way to Rails' ActiveSupport::Cache::FileStore.

It takes a single parameter, which is the directory at which to store the cached files.
If no parameter is specified, it uses the current directory.

### Reading

```ruby
cache = DiskStore.new
cached_file = cache.read("my_cache_key") #=> File.open('somewhere_on_disk')
```

### Writing

```ruby
cache = DiskStore.new
cache.write("my_cache_key", File.open('file.psd', 'r'))
```

### Fetching

```ruby
cache = DiskStore.new
cache.fetch("my_cache_key") do 
  File.open('file.psd', 'r')
end
```

This is where it gets cool. You can also feed it other IO classes.

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
