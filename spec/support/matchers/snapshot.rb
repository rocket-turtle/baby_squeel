require "yaml"

module Matchers
  class Snapshot
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
