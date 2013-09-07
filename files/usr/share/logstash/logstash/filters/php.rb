require "logstash/filters/base"
require "logstash/namespace"

# php filter. Takes a field that contains JSON and expands it into
# an actual datastructure.
# Based on JSON Filter: https://github.com/logstash/logstash/blob/v1.1.4/lib/logstash/filters/json.rb
class LogStash::Filters::Php < LogStash::Filters::Base

  config_name "php"
  plugin_status "beta"

  # Config for php is:
  #   source: dest
  # PHP Serialized strings in the value of the source field will be expanded into a
  # datastructure in the "dest" field.  Note: if the "dest" field
  # already exists, it will be overridden.
  config /[A-Za-z0-9_-]+/, :validate => :string

  public
  def register
    @json = {}

    @config.each do |field, dest|
      next if RESERVED.member?(field)

      @json[field] = dest
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running php filter", :event => event)

    matches = 0
    @json.each do |key, dest|
      next unless event[key]
      if event[key].is_a?(String)
        event[key] = [event[key]]
      end

      if event[key].length > 1
        @logger.warn("php filter only works on single fields (not lists)",
                     :key => key, :value => event[key])
        next
      end

      raw = event[key].first
      begin
        event[dest] = unserialize(raw)
        filter_matched(event)
      rescue => e
        event.tags << "_phpparsefailure"
        @logger.warn("Trouble parsing serialized object", :key => key, :raw => raw,
                      :exception => e)
        next
      end
    end

    @logger.debug("Event after php filter", :event => event)
  end # def filter
  def unserialize(string, classmap = nil, assoc = false) # {{{
    if classmap == true or classmap == false
      assoc = classmap
      classmap = {}
    end
    classmap ||= {}

    require 'stringio'
    string = StringIO.new(string)
    def string.read_until(char)
      val = ''
      while (c = self.read(1)) != char
        val << c
      end
      val
    end

    if string.string =~ /^(\w+)\|/ # session_name|serialized_data
      ret = Hash.new
      loop do
        if string.string[string.pos, 32] =~ /^(\w+)\|/
          string.pos += $&.size
          ret[$1] = do_unserialize(string, classmap, assoc)
        else
          break
        end
      end
      ret
    else
      do_unserialize(string, classmap, assoc)
    end
  end

  private
  def do_unserialize(string, classmap, assoc)
    val = nil
    # determine a type
    type = string.read(2)[0,1]
    case type
      when 'a' # associative array, a:length:{[index][value]...}
        count = string.read_until('{').to_i
        val = vals = Array.new
        count.times do |i|
          vals << [do_unserialize(string, classmap, assoc), do_unserialize(string, classmap, assoc)]
        end
        string.read(1) # skip the ending }

        # now, we have an associative array, let's clean it up a bit...
        # arrays have all numeric indexes, in order; otherwise we assume a hash
        array = true
        i = 0
        vals.each do |key,value|
          if key != i # wrong index -> assume hash
            array = false
            break
          end
          i += 1
        end

        if array
          vals.collect! do |key,value|
            value
          end
        else
          if assoc
            val = vals.map {|v| v }
          else
            val = Hash.new
            vals.each do |key,value|
              val[key] = value
            end
          end
        end

      when 'O' # object, O:length:"class":length:{[attribute][value]...}
        # class name (lowercase in PHP, grr)
        len = string.read_until(':').to_i + 3 # quotes, seperator
        klass = string.read(len)[1...-2].capitalize.intern # read it, kill useless quotes

        # read the attributes
        attrs = []
        len = string.read_until('{').to_i

        len.times do
          attr = (do_unserialize(string, classmap, assoc))
          attrs << [attr.intern, (attr << '=').intern, do_unserialize(string, classmap, assoc)]
        end
        string.read(1)

        val = nil
        # See if we need to map to a particular object
        if classmap.has_key?(klass)
          val = classmap[klass].new
        elsif Struct.const_defined?(klass) # Nope; see if there's a Struct
          classmap[klass] = val = Struct.const_get(klass)
          val = val.new
        else # Nope; see if there's a Constant
          begin
            classmap[klass] = val = Module.const_get(klass)

            val = val.new
          rescue NameError # Nope; make a new Struct
            classmap[klass] = Struct.new(klass.to_s, *attrs.collect { |v| v[0].to_s })
            val = val.new
          end
        end

        attrs.each do |attr,attrassign,v|
          val.__send__(attrassign, v)
        end

      when 's' # string, s:length:"data";
        len = string.read_until(':').to_i + 3 # quotes, separator
        val = string.read(len)[1...-2] # read it, kill useless quotes

      when 'i' # integer, i:123
        val = string.read_until(';').to_i

      when 'd' # double (float), d:1.23
        val = string.read_until(';').to_f

      when 'N' # NULL, N;
        val = nil

      when 'b' # bool, b:0 or 1
        val = (string.read(2)[0] == ?1 ? true : false)

      else
        raise TypeError, "Unable to unserialize type '#{type}'"
    end

    val
  end # }}}
end # class LogStash::Filters::Php
