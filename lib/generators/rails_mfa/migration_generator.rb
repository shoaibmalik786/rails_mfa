# frozen_string_literal: true

require 'rails/generators/base'
require 'rails/generators/active_record'

module RailsMfa
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Generates a migration to add MFA columns to a model"

      argument :name, type: :string, default: "User",
               desc: "The name of the model to add MFA columns to (e.g., User, Account)"

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        migration_template(
          "migration.rb.erb",
          "db/migrate/add_mfa_to_#{table_name}.rb"
        )
      end

      def show_instructions
        return unless behavior == :invoke

        say ""
        say "Migration created!", :green
        say ""
        say "Next steps:", :yellow
        say "  1. Review the migration file"
        say "  2. Run: rails db:migrate"
        say "  3. Include RailsMFA::Model in your #{class_name} model"
        say ""
      end

      private

      def table_name
        name.tableize
      end

      def class_name
        name.classify
      end
    end
  end
end
