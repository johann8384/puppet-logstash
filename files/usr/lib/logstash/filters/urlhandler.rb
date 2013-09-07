require "logstash/filters/base"
require "logstash/namespace"
require "uri"

# The urldecode filter is for decoding fields that are urlencoded.
class LogStash::Filters::Urlhandler < LogStash::Filters::Base
  config_name "urlhandler"
  plugin_status "beta"

  # The field which value is urldecoded
  config :field, :validate => :string, :default => "@message"

  public
  def register
    # Nothing to do
  end #def register

  public
  def filter(event)
    return unless filter?(event)

    event[@field] = urldecode(event[@field])
    value = event[@field]
    pairs = value.split('&')
    pairs.each { |pair| event["@fields"] = urlsplit(event["@fields"], pair) }

    filter_matched(event)
  end # def filter

  private
  def urlsplit(fields, pair)
     newfield = pair.split('=')
     fields[newfield[0]]=newfield[1]
     return fields
  end

  # Attempt to handle string, array, and hash values for fields.
  # For all other datatypes, just return, URI.unescape doesn't support them.
  private
  def urldecode(value)
    case value
    when String
      return URI.unescape(value)
    when Array
      ret_values = []
      value.each { |v| ret_values << urldecode(v) }
      return ret_values
    when Hash
      ret_values = {}
      value.each { |k,v| ret_values[k] = urldecode(v) }
      return ret_values
    else
      return "could not urldecode:" + value
    end
  end
end # class LogStash::Filters::Urldecode
