
require 'rails_helper'
class ShowComponentCertificatesForm
  include Capybara::DSL

  def has_disabled_signing_certificate?(certificate)
    within_table('Signing Certificates (Disabled)') do
      has_selector?("tr#certificate_table_#{certificate.id}", text: 'false')
    end
  end

  def has_enabled_signing_certificate?(certificate)
    within_table('Signing Certificates (Enabled)') do
      has_selector?("tr#certificate_table_#{certificate.id}", text: 'true')
    end
  end

  def has_encryption_signing_certificate?(certificate)
    within_table('Encryption Certificate assigned to component') do
      has_selector?("tr#certificate_table_#{certificate.id}")
    end
  end

  def disable_signing_certificate(certificate)
    within_table('Signing Certificates (Enabled)') do
      within("form#edit_certificate_#{certificate.id}") do
        click_on 'Disable'
      end
    end
  end

  def enable_signing_certificate(certificate)
    within_table('Signing Certificates (Disabled)') do
      within("form#edit_certificate_#{certificate.id}") do
        click_on 'Enable'
      end
    end
  end

  def replace_encryption_certificate(certificate)
    within_table('Previous Encryption Certificates for this component') do
      within("form#edit_certificate_#{certificate.id}") do
        click_on 'Replace'
      end
    end
  end
end