
module Utilities

  module Configuration

    module Settings
      def configuration(yaml_file_name)
        storage_yml = Pathname.new(Rails.root.join('config', yaml_file_name))
        erb = ERB.new(storage_yml.read)
        configuration = YAML.safe_load(erb.result) || {}
        configuration.deep_symbolize_keys
      rescue Errno::ENOENT
        puts 'Missing service configuration file in config/storage.yml'
        {}
      end

    end
  end
end