require 'spec_helper'

describe DiskStore::Reaper do
  let(:file_contents) { "Hello, Doge" }
  let(:file) { Tempfile.new("My Temp File.psd") }
  let(:key) { "doge" }

  before(:each) do
    @reaper = nil
    DiskStore::Reaper.stub(:spawn_for) { |path, opts| @reaper ||= DiskStore::Reaper.new(path, opts) }

    file.write file_contents
    file.flush
    file.rewind
  end

  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  it 'is spawned with a new cache' do
    cache = DiskStore.new(@tmpdir)
    expect(cache.reaper).to_not be_nil
    expect(cache.reaper.path).to eq @tmpdir
    expect(cache.reaper).to be_alive
  end

  it 'only spawns one reaper per cache dir' do
    cache1 = DiskStore.new(@tmpdir)
    cache2 = DiskStore.new(@tmpdir)

    expect(cache1.reaper).to be cache2.reaper
  end

  it 'allows you to set the maximum cache size' do
    cache = DiskStore.new(@tmpdir, cache_size: 2000)
    expect(cache.reaper.send(:maximum_cache_size)).to eq 2000
  end

  describe 'cache files' do
    let (:cache) { DiskStore.new(@tmpdir) }
    let (:reaper) { cache.reaper }

    before(:each) do
      cache.write key, file
    end

    it "correctly calculates the cache size" do
      expect(reaper.send(:current_cache_size)).to eq file_contents.size
    end

    it "finds all files" do
      expect(reaper.send(:files).size).to eq 1
      expect(File.read(reaper.send(:files).first)).to eq file_contents
    end

    it "finds all directories" do
      expect(reaper.send(:directories).size).to eq 2
    end
  end

  describe 'LRU eviction' do
    context 'when below the cache size' do
      let (:cache) { DiskStore.new(@tmpdir, eviction_strategy: :LRU, cache_size: 1073741824) }

      before(:each) do
        cache.write key, file
      end

      it "does not require eviction" do
        expect(cache.reaper.send(:needs_eviction?)).to be_false
      end
    end

    context 'when over the cache size' do
      let(:file2_contents) { "Hi friend" }
      let(:file2) { Tempfile.new("Friends are magical.psd") }
      let(:key2) { "friend" }

      let (:cache) { DiskStore.new(@tmpdir, eviction_strategy: :LRU, cache_size: file_contents.size + 1) }
      let (:reaper) { cache.reaper }

      before(:each) do
        cache.write key, file

        file2.write file2_contents
        file2.flush
        file2.rewind

        cache.write key2, file2
      end

      it "requires eviction" do
        expect(reaper.send(:needs_eviction?)).to be_true
      end

      it "correctly determines the files to evict" do
        files = reaper.send(:files_to_evict).map { |f| f[:path] }
        
        expect(files.size).to eq 1
        expect(File.read(files.first)).to eq file_contents
      end

      it "removes the file during eviction" do
        reaper.send(:perform_sweep!)

        expect(reaper.send(:files).size).to eq 1
        expect(File.read(reaper.send(:files).first)).to eq file2_contents
      end

      it "correctly determines empty directories" do
        reaper.send(:files).each { |f| FileUtils.rm(f) }
        expect(reaper.send(:empty_directories).size).to eq 2
      end

      it "removes empty directories during eviction" do
        2.times { reaper.send(:perform_sweep!) }
        expect(reaper.send(:empty_directories).size).to eq 0
      end
    end
  end
end