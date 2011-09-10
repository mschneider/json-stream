# encoding: UTF-8

module JSON
  module Stream
    module Bindings
      extend FFI::Library
      ffi_lib "yajl"

      callback :yajl_null, [:pointer], :int
      callback :yajl_boolean, [:pointer, :bool], :int
      callback :yajl_integer, [:pointer, :long_long], :int
      callback :yajl_double, [:pointer, :double], :int
      callback :yajl_number, [:pointer, :pointer, :size_t], :int
      callback :yajl_string, [:pointer, :pointer, :size_t], :int
      callback :yajl_start_map, [:pointer], :int
      callback :yajl_map_key, [:pointer, :pointer, :size_t], :int
      callback :yajl_end_map, [:pointer], :int
      callback :yajl_start_array, [:pointer], :int
      callback :yajl_end_array, [:pointer], :int

      class Callbacks < FFI::Struct
        layout :yajl_null,       :yajl_null,
               :yajl_boolean,    :yajl_boolean,
               :yajl_integer,    :yajl_integer,
               :yajl_double,     :yajl_double,
               :yajl_number,     :yajl_number,
               :yajl_string,     :yajl_string,
               :yajl_start_map,  :yajl_start_map,
               :yajl_map_key,    :yajl_map_key,
               :yajl_end_map,    :yajl_end_map,
               :yajl_start_array,:yajl_start_array,
               :yajl_end_array,  :yajl_end_array
      end

      enum :yajl_status, [ :yajl_status_ok,
                           :yajl_status_client_canceled,
                           :yajl_status_error ]

      attach_function :yajl_status_to_string, [:yajl_status], :string
      attach_function :yajl_alloc, [:pointer, :pointer, :pointer], :pointer
      attach_function :yajl_free, [:pointer], :void
      attach_function :yajl_parse, [:pointer, :string, :size_t], :yajl_status
      attach_function :yajl_complete_parse, [:pointer], :yajl_status
      # int  yajl_config (yajl_handle h, yajl_option opt,...)
      # unsigned char *  yajl_get_error (yajl_handle hand, int verbose, const unsigned char *jsonText, size_t jsonTextLength)
      # size_t   yajl_get_bytes_consumed (yajl_handle hand)
      # void   yajl_free_error (yajl_handle hand, unsigned char *str)
    end
  end
end