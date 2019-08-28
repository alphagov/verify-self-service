environment = Rails.configuration.hub_environments.keys.first
I18n.backend = I18n::Backend::KeyValue.new({})
I18n.backend.store_translations(
  :en,
  {
    msa_components: {
      new: {
        environment: "component_environment_#{environment}"
      }
    },
    sp_components: {
      new: {
        environment: "component_environment_#{environment}"
      }
    }
  },
  escape: false
)
I18n::Backend::KeyValue.send(:include, I18n::Backend::Memoize)
I18n::Backend::Simple.send(:include, I18n::Backend::Memoize)
I18n::Backend::Simple.send(:include, I18n::Backend::Pluralization)

I18n.backend = I18n::Backend::Chain.new(
  I18n::Backend::Simple.new,
  I18n.backend
)
