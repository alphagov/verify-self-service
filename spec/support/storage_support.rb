module StorageSupport
  def stub_storage_client_service_error
    allow(
        SelfService.service(:storage_client)
      ).to receive(:put_object).with(hash_including(bucket: "staging-bucket")).and_raise(Aws::S3::Errors::ServiceError.new('', ''))
  end
end
