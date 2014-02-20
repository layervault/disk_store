# DiskStore

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

It takes a single parameter, which is the directory at which to store the cached files.
If no parameter is specified, it uses the current directory.

```ruby
cache = DiskStore.new("path/to/my/cache/directory")
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
