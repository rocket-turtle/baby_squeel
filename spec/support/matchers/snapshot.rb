require "yaml"

module Matchers
  class Snapshot
    # Snapshot names read during this run, per file and without the version
    # suffix. With PRUNE_SNAPSHOTS every other key of a touched file is
    # removed when the run ends; keys of other Active Record versions share
    # the suffix-less name and survive.
    def self.read_names
      @read_names ||= Hash.new { |hash, path| hash[path] = Set.new }
    end

    def self.prune!
      read_names.each do |path, names|
        snapshots = YAML.load_file(path) || {}
        orphans = snapshots.keys.reject { |key| names.include?(key.sub(/ \(Active Record: v[\d.]+\)\z/, "")) }
        next if orphans.empty?

        orphans.each { |key| snapshots.delete(key) }
        File.write(path, snapshots.to_yaml)
        puts "#{path}: removed #{orphans.size} snapshot(s)"
      end
    end

    attr_reader :meta, :index

    def initialize(meta, index, suffix: nil)
      @meta = meta
      @index = index
      @suffix = suffix
    end

    def name
      value = "#{meta[:full_description]} #{index}"
      value = "#{value} #{@suffix}" if @suffix
      value
    end

    def path
      spec = meta[:absolute_file_path]
      file = "#{File.basename(spec, '.*')}.yaml"
      relative = File.join("..", "__snapshots__", file)
      File.expand_path(relative, spec)
    end

    def read
      self.class.read_names[path] << "#{meta[:full_description]} #{index}"
      data[name]
    end

    def write(value)
      puts "Writing #{name}"

      data[name] = value

      File.write(path, data.to_yaml)

      value
    end

    private

    def data
      @data ||=
        begin
          YAML.load_file(path) || {}
        rescue Errno::ENOENT
          {}
        end
    end
  end
end
