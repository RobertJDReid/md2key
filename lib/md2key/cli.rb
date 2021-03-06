require 'md2key/config_builder'
require 'md2key/config_loader'
require 'md2key/parser'
require 'md2key/renderer'
require 'thor'
require 'yaml'

module Md2key
  class CLI < Thor
    desc 'convert MARKDOWN', 'Convert markdown to keynote'
    def convert(path)
      abort "md2key: `#{path}` does not exist" unless File.exist?(path)

      markdown = File.read(path)
      config = ConfigLoader.load('~/.md2key', './.md2key')
      ast = Parser.new.parse(markdown)
      Renderer.new(config).render!(ast)
    end

    desc 'init', 'Put .md2key template to current directory'
    option :skip_options, type: :boolean, default: false, aliases: %w[-n]
    def init
      yaml = ConfigBuilder.build(skip_options: options[:skip_options])
      File.write('.md2key', yaml)
      puts "# Successfully generated .md2key!\n#{yaml}"
    end

    desc 'listen', 'Update the *.key file when each saves'
    def listen(path)
      require 'listen'
      puts 'Watching the *.md file...'
      listener = Listen.to('./', only: /\.md$/) do |_|
        convert(path) && (puts "The *.key file has been updated. let's open *.key file!")
      end
      listener.start
      sleep
    rescue Interrupt
      puts 'Bye.'
    end

    private

    # Shorthand for `md2key convert *.md`
    def method_missing(*args)
      path = args.first.to_s
      if args.length == 1 && path.end_with?('.md')
        convert(path)
      else
        return super(*args)
      end
    end
  end
end
