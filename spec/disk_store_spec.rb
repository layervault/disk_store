require 'spec_helper'

describe DiskStore do
  let(:cache) { DiskStore.new @tmpdir }
  let(:file_contents) { "Hello, Doge" }
  let(:file) { Tempfile.new("My Temp File.psd") }
  let(:key) { "doge" }

  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  before(:each) do
    file.write file_contents
    file.flush
  end

  context "initializing" do
    subject { DiskStore.new }
    it { should respond_to(:read) }
    it { should respond_to(:write) }
    it { should respond_to(:fetch) }
    it { should respond_to(:delete) }
    it { should respond_to(:exist?) }
  end

  context "#read" do
    it "reads from disk" do
      cache.write(key, file)
      file.close
      file.unlink # ensure the tempfile is deleted
      expect(cache.read(key)).to be_an_instance_of(File)
      expect(cache.read(key).read).to eq file_contents
    end
  end

  context "#write" do
    it "writes a file to disk" do
      expect{
        cache.write(key, file)
      }.to change{ Dir[File.join(@tmpdir, "**/*")].size }.by(3)

      file_path = Dir[File.join(@tmpdir, "**/*")].last
      expect(File.read(file_path)).to eq file_contents
    end
  end

  context "#delete" do
    it "deletes the file from disk" do
      cache.write(key, file)
      expect{
        cache.delete(key)
      }.to change{ Dir[File.join(@tmpdir, "**/*")].size }.by(-3)
    end
  end

  context "#exist?" do
    it "returns correct value" do
      expect(cache.exist?(key)).to be_false
      cache.write(key, file)
      expect(cache.exist?(key)).to be_true
      cache.delete(key)
      expect(cache.exist?(key)).to be_false
    end
  end

  context "web resources", :vcr do
    let(:url) { "http://media.giphy.com/media/KXD1pSzGb3Khi/giphy.gif" }
    let(:key) { "lolololol" }

    it "should cache the result of a web resource in a file" do
      expect(cache.exist?(key)).to be_false

      cache.fetch(key) do
        open(url)
      end

      expect(cache.read(key).read).to eq open(url).read
    end
  end
end