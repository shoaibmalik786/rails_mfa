# frozen_string_literal: true

require 'rails/generators/base'

module RailsMfa
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a RailsMFA initializer in your application."

      def copy_initializer
        template "rails_mfa.rb", "config/initializers/rails_mfa.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
