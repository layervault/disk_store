require 'spec_helper'
require 'open-uri'

describe DiskStore do
  let(:cache) { DiskStore.new @tmpdir }
  let(:file_contents) { SecureRandom.random_bytes(8192) }
  let(:file) { Tempfile.new("My Temp File.psd") }
  let(:key) { "doge" }

  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  before(:each) do
    file.binmode
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
    before(:each) do
      cache.write(key, file)
      file.close
      file.unlink # ensure the tempfile is deleted
    end

    it "reads from disk" do
      expect(cache.read(key)).to be_an_instance_of(File)
      expect(cache.read(key).read).to eq file_contents
    end

    describe "md5 validation" do
      let(:expected_md5) { Digest::MD5.hexdigest(file_contents) }

      it "validates the md5 when reading from disk" do
        expect(cache).to receive(:validate_file!)
        cache.read(key, expected_md5)
      end

      it "does not throw an exception when the md5 is correct" do
        expect {
          cache.read(key, expected_md5)
        }.to_not raise_error
      end

      it "raises an exception and deletes the file when the md5 is incorrect" do
        expect {
          cache.read(key, "naw")
        }.to raise_error(DiskStore::MD5DidNotMatch)

        expect(cache.exist?(key)).to be_false
      end
    end
  end

  context "#write" do
    it "writes a file to disk" do
      expect{
        cache.write(key, file)
      }.to change{ Dir[File.join(@tmpdir, "**/*")].size }.by(3)

      file_path = Dir[File.join(@tmpdir, "**/*")].last
      expect(File.binread(file_path)).to eq file_contents
    end

    describe "md5 validation" do
      let(:expected_md5) { Digest::MD5.hexdigest(file_contents) }

      it "validates md5 after writing to disk" do
        expect(cache).to receive(:validate_file!)
        cache.write(key, file, expected_md5)
      end

      it "does not throw an exception when the md5 is correct" do
        expect {
          cache.write(key, file, expected_md5)
        }.to_not raise_error
      end

      it "raises an exception and deletes the file when the md5 is incorrect" do
        expect {
          cache.write(key, file, "i am incorrect")
        }.to raise_error(DiskStore::MD5DidNotMatch)

        expect(cache.exist?(key)).to be_false
      end
    end
  end

  context "#delete" do
    it "deletes the file from disk" do
      cache.write(key, file)
      expect{
        expect(cache.delete(key)).to be_true
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
end