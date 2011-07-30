module Moob
    VERSION = [0,3,0]

    class ResponseError < Exception
        def initialize response
            @response = response
        end
        def to_s
            "#{@response.url} failed (status #{@response.status})"
        end
    end

    autoload :BaseLom,    'moob/baselom.rb'
    autoload :Idrac6,     'moob/idrac6.rb'
    autoload :Megatrends, 'moob/megatrends.rb'
    autoload :SunILom,    'moob/sunilom.rb'

    TYPES = {
        :idrac6     => Idrac6,
        :megatrends => Megatrends,
        :sun        => SunILom
    }

    def self.lom type, hostname, options = {}
        case type
        when :auto
            TYPES.find do |sym, klass|
                Moob.inform "Trying type #{sym}..."
                lom = klass.new hostname, options
                if lom.detect
                    Moob.inform "Type #{sym} detected."
                    return lom
                end
                false
            end
            raise RuntimeError.new "Couldn't detect a known LOM type"
        else
            return TYPES[type].new hostname, options
        end
    end

    def self.start_jnlp lom
        jnlp = lom.jnlp

        unless jnlp[/<\/jnlp>/]
            raise RuntimeError.new "Invalid JNLP file (\"#{jnlp}\")"
        end

        filepath = "/tmp/#{lom.hostname}_#{Time.now.to_i}.jnlp"
        File.open filepath, 'w' do |f|
            f.write jnlp
        end

        raise Exception.new "javaws failed" unless system "javaws -wait #{filepath}"
    end

    def self.inform msg
        $stderr.puts "\036[31m#{msg}\033[0m" if $VERBOSE
    end
end
