require "tilt"

module Sprockets
  module Sass
    class SassTemplate < Tilt::SassTemplate
      self.default_mime_type = "text/css"
      
      # A reference to the current Sprockets context
      attr_reader :context
      
      # Templates are initialized once the 
      def self.engine_initialized?
        super && defined?(@@sass_functions_added)
      end
      
      # Add the Sass functions if they haven't already been added.
      def initialize_engine
        super
        
        if Sass.add_sass_functions
          begin
            require "sprockets/sass/functions"
          rescue LoadError
            # Safely ignore load issues, because
            # sprockets-helpers may not be available.
            @@sass_functions_added = false
          end
          @@sass_functions_added = true
        else
          @@sass_functions_added = false
        end
      end
      
      # Define the expected syntax for the template
      def syntax
        :sass
      end
      
      # See `Tilt::Template#prepare`.
      def prepare
        @context = nil
        @output  = nil
      end
      
      # See `Tilt::Template#evaluate`.
      def evaluate(context, locals, &block)
        @output ||= begin
          @context = context
          ::Sass::Engine.new(data, sass_options).render
        end
      end

      protected
      
      # A reference to the custom Sass importer, `Sprockets::Sass::Importer`.
      def importer
        Importer.new context
      end
      
      # Assemble the options for the `Sass::Engine`
      def sass_options
        merge_sass_options(default_sass_options, options).merge(
          :filename => eval_file,
          :line     => line,
          :syntax   => syntax,
          :importer => importer
        )
      end
      
      # Get the default, global Sass options. Start with Compass's
      # options, if it's available.
      def default_sass_options
        if defined?(Compass)
          merge_sass_options Compass.sass_engine_options.dup, Sprockets::Sass.options
        else
          Sprockets::Sass.options.dup
        end
      end
      
      # Merges two sets of `Sass::Engine` options, prepending
      # the `:load_paths` instead of clobbering them.
      def merge_sass_options(options, other_options)
        if (load_paths = options[:load_paths]) && (other_paths = other_options[:load_paths])
          other_options[:load_paths] = other_paths + load_paths
        end
        options.merge other_options
      end
    end
  end
end
