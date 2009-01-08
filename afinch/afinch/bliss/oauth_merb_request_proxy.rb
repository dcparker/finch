require 'rubygems'
require 'oauth/request_proxy/base'
require 'uri'

module OAuth
  module Signature
    class Base
      def initialize(request, options = {}, &block)
        raise TypeError unless request.kind_of?(OAuth::RequestProxy::Base)
        @request = request
        if block_given?
          @token_secret, @consumer_secret = yield block.arity == 1 ? token : [token, consumer_key,nonce,request.timestamp]
        else
          @consumer_secret = options[:consumer].respond_to?(:secret) ? options[:consumer].secret : options[:consumer]
          @token_secret = options[:token].respond_to?(:secret) ? options[:token].secret : (options[:token] || '')
        end
      end
    end
  end
  module RequestProxy
    class Base
      def inspect
        "#<OAuth::RequestProxy::MerbRequest:#{object_id}\n\tconsumer_key: #{consumer_key}\n\ttoken: #{token}\n\tparameters: #{parameters.inspect}\n>"
      end
    end
    class MerbRequest < OAuth::RequestProxy::Base
      proxies Merb::Request

      def method
        request.method.to_s.upcase
      end

      def uri
        uri = URI.parse(request.protocol + request.host + request.path)
        uri.query = nil
        uri.to_s
      end

      def parameters
        if options[:clobber_request]
          options[:parameters]
        else
          all_parameters
        end
      end

      def auth_header_params
        header = nil
        %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each do |header|
          next unless request.env.include?(header)

          header = request.env[header]
          next unless header[0,6] == 'OAuth '
        end
        header
      end

      def header_params
        %w( X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION ).each do |header|
          next unless request.env.include?(header)

          header = request.env[header]
          next unless header[0,6] == 'OAuth '

          oauth_param_string = header[6,header.length].split(/[,=]/)
          oauth_param_string.map! { |v| v.strip }
          oauth_param_string.map! { |v| v =~ /^\".*\"$/ ? v[1..-2] : v }
          oauth_params = Hash[*oauth_param_string.flatten]
          oauth_params.reject! { |k,v| k !~ /^oauth_/ }

          return oauth_params.map { |k,v| "#{k}=#{v}" }.join('&')
        end

        return ''
      end

      def query_params
        request.query_string
      end

      def post_params
        p = request.send(:raw_post)
        p.blank? ? nil : p
      end

      def query_string
        [ query_params, post_params, header_params ].compact.join('&')
      end

      def all_parameters
        request_params = CGI.parse(query_string)
        if options[:parameters]
          options[:parameters].each do |k,v|
            if request_params.has_key?(k)
              request_params[k] << v
            else
              request_params[k] = [v].flatten
            end
          end
        end
        request_params
      end

      def unescape(value)
        URI.unescape(value.gsub('+', '%2B'))
      end
    end
  end
end
