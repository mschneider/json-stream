# encoding: UTF-8

module JSON
  module Stream
    class ParserError < RuntimeError; end

    class Parser
      BUF_SIZE = 4096

      def self.parse json
        stream = if json.is_a? String then StringIO.new json else json end
        parser = Parser.new
        builder = Builder.new parser
        while (buf = stream.read BUF_SIZE) != nil
          parser << buf
        end
        parser.finalize
        raise ParserError, "unexpected eof" unless builder.result
        builder.result
      ensure
        stream.close
      end

      CALLBACKS = %w[start_document end_document start_object end_object
                      start_array end_array key value]

      def initialize &block
        @opened_scopes = @closed_scopes = 0
        @listeners = Hash.new {|h, k| h[k] = [] }
        @closures = [] # prevent GC
        @callbacks = Bindings::Callbacks.new
        METHODS.each do |name|
          @closures << @callbacks[name.to_sym] = method(name)
        end
        @handle = Bindings::yajl_alloc(@callbacks, nil, nil)
        instance_eval(&block) if block_given?
      end

      def << data
        begin
          status = Bindings::yajl_parse(@handle, data, data.size)
        ensure
          puts "#{object_id} [#{status.inspect}] #{data}"
          raise ParserError unless status == :yajl_status_ok
        end
        self
      end

      def finalize
        status = Bindings::yajl_complete_parse(@handle)
        Bindings::yajl_free(@handle)
        @callbacks.to_ptr.free
        puts "#{object_id} [#{status.inspect}] finalized!"
        raise ParserError unless status == :yajl_status_ok
      end

      CALLBACKS.each do |name|
        define_method name do |&block|
          @listeners[name] << block
        end

        define_method "notify_#{name}" do |*args|
          @listeners[name].each do |block|
            block.call(*args)
          end
        end

        private "notify_#{name}"
      end

      private

      def open_scope
        notify_start_document if @opened_scopes == 0
        @opened_scopes += 1
      end

      def close_scope
        @closed_scopes += 1
        notify_end_document if @closed_scopes == @opened_scopes
      end

      METHODS = %w[yajl_null yajl_boolean yajl_number yajl_string
                    yajl_start_map yajl_map_key yajl_end_map
                    yajl_start_array yajl_end_array]

      def yajl_null id
        notify_value nil
        return 1
      end

      def yajl_boolean id, bool
        notify_value bool
        return 1
      end

      def yajl_number id, data, size
        string = data.read_string(size)
        begin
          value = Integer(string)
        rescue ArgumentError
          value = Float(string)
        end
        notify_value value
        return 1
      end

      def yajl_string id, data, size
        notify_value data.read_string(size)
        return 1
      end

      def yajl_start_map id
        open_scope
        notify_start_object
        return 1
      end

      def yajl_map_key id, data, size
        notify_key data.read_string(size)
        return 1
      end

      def yajl_end_map id
        notify_end_object
        close_scope
        return 1
      end

      def yajl_start_array id
        open_scope
        notify_start_array
        return 1
      end

      def yajl_end_array id
        notify_end_array
        close_scope
        return 1
      end
    end
  end
end
