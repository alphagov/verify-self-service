RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  def wait_until(timeout=1.5, frequency=0.1, &block)
    start = Time.now
    loop {
      sleep(frequency)
      #return if block.call == true
      r = block.call
      return r if r
      break if Time.now - start > timeout
    }
    fail "timeout after #{timeout}s"
  end
end