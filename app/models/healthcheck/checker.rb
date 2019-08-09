module Healthcheck
  STATUSES = [
    OK = :ok,
    CRITICAL = :critical,
  ].freeze

  class Checker
    def initialize(checks)
      @checks = checks
    end

    def run
      {
        status: worst_status,
        checks: check_statuses,
      }
    end

  private

    attr_reader :checks

    def check_statuses
      @check_statuses ||= checks.map(&:new).each_with_object({}) do |check, hash|
        hash[check.name] = build_check_status(check)
      end
    end

    def build_check_status(check)
      { status: check.status }
    rescue StandardError => e
      Rails.logger.error(e.to_s)
      { status: CRITICAL }
    end

    def worst_status
      critical? ? CRITICAL : OK
    end

    def critical?
      check_statuses.values.any? do |s|
        s[:status] == CRITICAL || s[:status].blank?
      end
    end
  end
end
