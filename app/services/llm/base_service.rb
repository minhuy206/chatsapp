module Llm
  class BaseService
    include Concerns::ErrorHandler
    include Concerns::Retryable

    # Stream completion from LLM provider
    # @param messages [Array<Hash>] [{role: 'user', content: '...'}, ...]
    # @param model [String] Model name
    # @yield [String] token
    def stream_completion(messages:, model:, &block)
      raise NotImplementedError, "#{self.class} must implement #stream_completion"
    end

    protected

    def max_tokens
      ENV.fetch("MAX_TOKENS", "2000").to_i
    end

    def temperature
      ENV.fetch("TEMPERATURE", "0.7").to_f
    end

    def provider_name
      self.class.name.demodulize.gsub("Service", "").downcase
    end
  end
end
