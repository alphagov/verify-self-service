class DisableSigningCertificateEvent < SigningCertificateEvent

  def enabled
    false
  end
end