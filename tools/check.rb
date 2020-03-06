#!/usr/bin/env ruby

require 'yaml'
require 'json'

ENVIRONMENTS = ["prod", "integration"]
ENVIRONMENT = ARGV[0]
ENTITY_ID = ARGV[1]
MSA = ARGV[2] == '--msa'

if ENVIRONMENT.nil?
  puts "USAGE: ./check.rb <environment> <entity_id> [--msa optional]"
end

unless ENVIRONMENTS.include?(ENVIRONMENT)
  puts "Invalid environment, accepted values are: #{ENVIRONMENTS}"
  exit 1
end

if ENTITY_ID.nil?
  puts "EntityID is missing"
  exit 1
end

def compare(config)
  entity_id = config['entityId']
  certs = get_fed_config_certs(config)
  published_certs = get_published_certs(entity_id)
  puts "MISMATCH! Encryption certificates are not matching" unless certs[:encryption] == published_certs[:encryption]
  puts "MISMATCH! Singing certificates are not matching" unless certs[:signing].sort == published_certs[:signing].sort
  return true if certs[:encryption] == published_certs[:encryption] && certs[:signing].sort == published_certs[:signing].sort
  false
end

def get_published_certs(entity_id)
  json = `aws s3 cp s3://govukverify-self-service-#{ENVIRONMENT}-config-metadata/verify_services_metadata.json temp_remote_metadata.json`
  published_metadata = JSON.parse(File.read('temp_remote_metadata.json'))
  if MSA
    certs = published_metadata["matching_service_adapters"].find{ |msa| msa['entity_id'] == entity_id}
  else
    type = 'service_providers'
    sp_id = published_metadata["connected_services"].find{ |component| component['entity_id'] == entity_id}&.fetch('service_provider_id', nil)
    if sp_id.nil?
      puts "ERROR! Component with the entityid is not being published by self-service"
    end
    certs = published_metadata["service_providers"].find{ |sp| sp['id'] == sp_id}
  end  

  {
    signing: certs.fetch('signing_certificates', [])&.map{|c| c['value']},
    encryption: certs.dig('encryption_certificate', 'value')
  }
end

def get_fed_config_certs(config)
  {
    signing: config.fetch('signatureVerificationCertificates', [])&.map{|c| c['x509']},
    encryption: config.dig('encryptionCertificate', 'x509')
  }
end

hub_fed_config_directory = "../../verify-hub-federation-config/configuration/config-service-data/#{ENVIRONMENT}/#{MSA ? 'matching-services' : 'transactions'}/"
config_files = Dir.children(hub_fed_config_directory)
all_good = false

config_files.each do |file|
  config = YAML.load_file(File.join(hub_fed_config_directory, file))
  if config['entityId'] == ENTITY_ID
    all_good = compare(config)
    break
  end
end

if all_good
  puts "WELL DONE! ALL LOOKS OK!"
else
  puts "Oh no, something is not correct"
end
