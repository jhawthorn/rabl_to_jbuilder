require 'rabl_to_jbuilder'

module RablToJbuilder
  class Cli
    def initialize(argv)
      @files = []
      argv.each do |filename|
        if File.file?(filename)
          @files << filename
        elsif File.directory?(filename)
          @files.concat Dir[File.join(filename, "**/*.rabl")]
        else
          puts "Invalid filename #{filename}"
        end
      end
    end

    def run
      @files.each do |filename|
        begin
          convert_file(filename)
        rescue StandardError => e
          puts e
          puts e.backtrace
        end
      end
    end

    def convert_file(filename)
      raise "Filenames must end in .rabl" unless filename.end_with?(".rabl")

      # Guess at an object name
      action_name = File.basename(filename)[/\A([^.]+)/, 1]
      object_name_plural = File.basename(File.dirname(filename))
      object_name_singular = object_name_plural.singularize

      target = filename.gsub(/\.rabl$/, '.jbuilder')
      puts "#{filename} => #{target}"

      rabl = File.read(filename)
      jbuilder = RablToJbuilder.convert(rabl, object: Sexp.s(:lvar, object_name_singular.to_sym))
      #jbuilder = RablToJbuilder.convert(rabl)

      File.write(target, jbuilder)
    end
  end
end
