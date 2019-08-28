module ErrorHelper
  def error_messages_for(model, name = nil)
    return unless model.errors.present?

    content_tag :div, error_div_govuk_summary_styles do
      (error_heading(model) + error_body(model, name)).html_safe
    end
  end

  def error_message_on(errors, field)
    return unless errors.present?

    message = errors.full_messages_for(field).first
    content_tag :span, id: 'value-error', class: 'govuk-error-message' do
      content_tag(:span, t('shared.errors.error'),
                  class: 'govuk-visually-hidden')
      t('shared.errors.message', message: message)
    end
  end

private

  def error_heading(model)
    content_tag :h2, t('shared.errors.problem',
                       count: model.errors.count,
                       model: model.class.model_name.human.downcase),
                class: 'govuk-error-summary__title', id: 'error-summary-title'
  end

  def error_body(model, name)
    content_tag :div, class: 'govuk-error-summary__body' do
      content_tag :ul, class: 'govuk-list govuk-error-summary__list' do
        model.errors.each do |key|
          error_content_listitem(key, model, name)
        end
      end
    end
  end

  def error_content_listitem(key, model, name)
    concat(
      content_tag(
        :li,
        link_to(
          model.errors.full_messages_for(key).first,
          use_lazy_evaluation_or_computed_name(key, name)
        ),
        'data-turbolinks': 'false'
      )
    )
  end

  def use_lazy_evaluation_or_computed_name(key, name)
    name.present? ? "##{name}_#{key}" : "##{t(".#{key}")}"
  end

  def error_div_govuk_summary_styles
    {
      class: 'govuk-error-summary', 'aria-labelledby': 'error-summary-title',
      role: 'alert', 'tab-index': '-1', 'data-module': 'error-summary'
    }
  end
end
