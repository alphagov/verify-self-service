require 'auth/cognito_chooser'
require 'auth/cognito_stub_client'
require 'storage/storage_registrar'

module SelfService
  def self.register_service(name:, client:)
    @services ||= {}

    @services[name] = client
  end

  def self.service(name)
    raise(ServiceNotRegisteredException.new(name)) unless self.service_present?(name)

    @services[name]
  end

  def self.service_present?(name)
    @services.key?(name)
  end

  class ServiceNotRegisteredException < RuntimeError; end
end

CognitoChooser.new
StorageRegistrar.new
