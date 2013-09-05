##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'


class Metasploit3 < Msf::Auxiliary

  include Msf::Exploit::Remote::Tcp
  include Msf::Auxiliary::Fuzzer

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'SSH Key Exchange Init Corruption',
      'Description'    => %q{
        This module sends a series of SSH requests with a corrupted initial key exchange payload.
      },
      'Author'         => [ 'hdm' ],
      'License'        => MSF_LICENSE
    ))
    register_options([
      Opt::RPORT(22),
      OptInt.new('MAXDEPTH', [false, 'Specify a maximum byte depth to test'])
    ], self.class)
  end

  def do_ssh_kexinit(pkt,opts={})
    @connected = false
    connect
    @connected = true

    @banner = sock.get_once(-1,opts[:banner_timeout])
    return if not @banner

    sock.put("SSH-2.0-OpenSSH_5.1p1 Debian-5ubuntu1\r\n")
    sock.put(pkt)
    sock.get_once(-1,opts[:kex_timeout])
  end

  def run
    last_str = nil
    last_inp = nil
    last_err = nil

    pkt = make_kex_init
    cnt = 0

    max = datastore['MAXDEPTH'].to_i
    max = nil if max == 0
    tot = ( max ? [max,pkt.length].min : pkt.length) * 256

    print_status("Fuzzing SSH initial key exchange with #{tot} requests")
    fuzz_string_corrupt_byte_reverse(pkt,max) do |str|
      cnt += 1

      if(cnt % 100 == 0)
        print_status("Fuzzing with iteration #{cnt}/#{tot} using #{@last_fuzzer_input}")
      end

      begin
        r = do_ssh_kexinit(str,:banner_timeout => 5, :kex_timeout => 0.5)
      rescue ::Interrupt
        print_status("Exiting on interrupt: iteration #{cnt} using #{@last_fuzzer_input}")
        raise $!
      rescue ::Exception => e
        last_err = e
      ensure
        disconnect
      end

      if(not @connected)
        if(last_str)
          print_status("The service may have crashed: iteration:#{cnt-1} method=#{last_inp} string=#{last_str.unpack("H*")[0]} error=#{last_err}")
        else
          print_status("Could not connect to the service: #{last_err}")
        end
        return
      end

      if(not @banner)
        print_status("The service may have crashed (no banner): iteration:#{cnt-1} method=#{last_inp} string=#{last_str.to_s.unpack("H*")[0]} ")
        return
      end

      last_str = str
      last_inp = @last_fuzzer_input
    end
  end

  def make_kex_init
    [0x00, 0x00, 0x03, 0x14, 0x08, 0x14, 0xff, 0x9f,
    0xde, 0x5d, 0x5f, 0xb3, 0x07, 0x8f, 0x49, 0xa7,
    0x79, 0x6a, 0x03, 0x3d, 0xaf, 0x55, 0x00, 0x00,
    0x00, 0x7e, 0x64, 0x69, 0x66, 0x66, 0x69, 0x65,
    0x2d, 0x68, 0x65, 0x6c, 0x6c, 0x6d, 0x61, 0x6e,
    0x2d, 0x67, 0x72, 0x6f, 0x75, 0x70, 0x2d, 0x65,
    0x78, 0x63, 0x68, 0x61, 0x6e, 0x67, 0x65, 0x2d,
    0x73, 0x68, 0x61, 0x32, 0x35, 0x36, 0x2c, 0x64,
    0x69, 0x66, 0x66, 0x69, 0x65, 0x2d, 0x68, 0x65,
    0x6c, 0x6c, 0x6d, 0x61, 0x6e, 0x2d, 0x67, 0x72,
    0x6f, 0x75, 0x70, 0x2d, 0x65, 0x78, 0x63, 0x68,
    0x61, 0x6e, 0x67, 0x65, 0x2d, 0x73, 0x68, 0x61,
    0x31, 0x2c, 0x64, 0x69, 0x66, 0x66, 0x69, 0x65,
    0x2d, 0x68, 0x65, 0x6c, 0x6c, 0x6d, 0x61, 0x6e,
    0x2d, 0x67, 0x72, 0x6f, 0x75, 0x70, 0x31, 0x34,
    0x2d, 0x73, 0x68, 0x61, 0x31, 0x2c, 0x64, 0x69,
    0x66, 0x66, 0x69, 0x65, 0x2d, 0x68, 0x65, 0x6c,
    0x6c, 0x6d, 0x61, 0x6e, 0x2d, 0x67, 0x72, 0x6f,
    0x75, 0x70, 0x31, 0x2d, 0x73, 0x68, 0x61, 0x31,
    0x00, 0x00, 0x00, 0x0f, 0x73, 0x73, 0x68, 0x2d,
    0x72, 0x73, 0x61, 0x2c, 0x73, 0x73, 0x68, 0x2d,
    0x64, 0x73, 0x73, 0x00, 0x00, 0x00, 0x9d, 0x61,
    0x65, 0x73, 0x31, 0x32, 0x38, 0x2d, 0x63, 0x62,
    0x63, 0x2c, 0x33, 0x64, 0x65, 0x73, 0x2d, 0x63,
    0x62, 0x63, 0x2c, 0x62, 0x6c, 0x6f, 0x77, 0x66,
    0x69, 0x73, 0x68, 0x2d, 0x63, 0x62, 0x63, 0x2c,
    0x63, 0x61, 0x73, 0x74, 0x31, 0x32, 0x38, 0x2d,
    0x63, 0x62, 0x63, 0x2c, 0x61, 0x72, 0x63, 0x66,
    0x6f, 0x75, 0x72, 0x31, 0x32, 0x38, 0x2c, 0x61,
    0x72, 0x63, 0x66, 0x6f, 0x75, 0x72, 0x32, 0x35,
    0x36, 0x2c, 0x61, 0x72, 0x63, 0x66, 0x6f, 0x75,
    0x72, 0x2c, 0x61, 0x65, 0x73, 0x31, 0x39, 0x32,
    0x2d, 0x63, 0x62, 0x63, 0x2c, 0x61, 0x65, 0x73,
    0x32, 0x35, 0x36, 0x2d, 0x63, 0x62, 0x63, 0x2c,
    0x72, 0x69, 0x6a, 0x6e, 0x64, 0x61, 0x65, 0x6c,
    0x2d, 0x63, 0x62, 0x63, 0x40, 0x6c, 0x79, 0x73,
    0x61, 0x74, 0x6f, 0x72, 0x2e, 0x6c, 0x69, 0x75,
    0x2e, 0x73, 0x65, 0x2c, 0x61, 0x65, 0x73, 0x31,
    0x32, 0x38, 0x2d, 0x63, 0x74, 0x72, 0x2c, 0x61,
    0x65, 0x73, 0x31, 0x39, 0x32, 0x2d, 0x63, 0x74,
    0x72, 0x2c, 0x61, 0x65, 0x73, 0x32, 0x35, 0x36,
    0x2d, 0x63, 0x74, 0x72, 0x00, 0x00, 0x00, 0x9d,
    0x61, 0x65, 0x73, 0x31, 0x32, 0x38, 0x2d, 0x63,
    0x62, 0x63, 0x2c, 0x33, 0x64, 0x65, 0x73, 0x2d,
    0x63, 0x62, 0x63, 0x2c, 0x62, 0x6c, 0x6f, 0x77,
    0x66, 0x69, 0x73, 0x68, 0x2d, 0x63, 0x62, 0x63,
    0x2c, 0x63, 0x61, 0x73, 0x74, 0x31, 0x32, 0x38,
    0x2d, 0x63, 0x62, 0x63, 0x2c, 0x61, 0x72, 0x63,
    0x66, 0x6f, 0x75, 0x72, 0x31, 0x32, 0x38, 0x2c,
    0x61, 0x72, 0x63, 0x66, 0x6f, 0x75, 0x72, 0x32,
    0x35, 0x36, 0x2c, 0x61, 0x72, 0x63, 0x66, 0x6f,
    0x75, 0x72, 0x2c, 0x61, 0x65, 0x73, 0x31, 0x39,
    0x32, 0x2d, 0x63, 0x62, 0x63, 0x2c, 0x61, 0x65,
    0x73, 0x32, 0x35, 0x36, 0x2d, 0x63, 0x62, 0x63,
    0x2c, 0x72, 0x69, 0x6a, 0x6e, 0x64, 0x61, 0x65,
    0x6c, 0x2d, 0x63, 0x62, 0x63, 0x40, 0x6c, 0x79,
    0x73, 0x61, 0x74, 0x6f, 0x72, 0x2e, 0x6c, 0x69,
    0x75, 0x2e, 0x73, 0x65, 0x2c, 0x61, 0x65, 0x73,
    0x31, 0x32, 0x38, 0x2d, 0x63, 0x74, 0x72, 0x2c,
    0x61, 0x65, 0x73, 0x31, 0x39, 0x32, 0x2d, 0x63,
    0x74, 0x72, 0x2c, 0x61, 0x65, 0x73, 0x32, 0x35,
    0x36, 0x2d, 0x63, 0x74, 0x72, 0x00, 0x00, 0x00,
    0x69, 0x68, 0x6d, 0x61, 0x63, 0x2d, 0x6d, 0x64,
    0x35, 0x2c, 0x68, 0x6d, 0x61, 0x63, 0x2d, 0x73,
    0x68, 0x61, 0x31, 0x2c, 0x75, 0x6d, 0x61, 0x63,
    0x2d, 0x36, 0x34, 0x40, 0x6f, 0x70, 0x65, 0x6e,
    0x73, 0x73, 0x68, 0x2e, 0x63, 0x6f, 0x6d, 0x2c,
    0x68, 0x6d, 0x61, 0x63, 0x2d, 0x72, 0x69, 0x70,
    0x65, 0x6d, 0x64, 0x31, 0x36, 0x30, 0x2c, 0x68,
    0x6d, 0x61, 0x63, 0x2d, 0x72, 0x69, 0x70, 0x65,
    0x6d, 0x64, 0x31, 0x36, 0x30, 0x40, 0x6f, 0x70,
    0x65, 0x6e, 0x73, 0x73, 0x68, 0x2e, 0x63, 0x6f,
    0x6d, 0x2c, 0x68, 0x6d, 0x61, 0x63, 0x2d, 0x73,
    0x68, 0x61, 0x31, 0x2d, 0x39, 0x36, 0x2c, 0x68,
    0x6d, 0x61, 0x63, 0x2d, 0x6d, 0x64, 0x35, 0x2d,
    0x39, 0x36, 0x00, 0x00, 0x00, 0x69, 0x68, 0x6d,
    0x61, 0x63, 0x2d, 0x6d, 0x64, 0x35, 0x2c, 0x68,
    0x6d, 0x61, 0x63, 0x2d, 0x73, 0x68, 0x61, 0x31,
    0x2c, 0x75, 0x6d, 0x61, 0x63, 0x2d, 0x36, 0x34,
    0x40, 0x6f, 0x70, 0x65, 0x6e, 0x73, 0x73, 0x68,
    0x2e, 0x63, 0x6f, 0x6d, 0x2c, 0x68, 0x6d, 0x61,
    0x63, 0x2d, 0x72, 0x69, 0x70, 0x65, 0x6d, 0x64,
    0x31, 0x36, 0x30, 0x2c, 0x68, 0x6d, 0x61, 0x63,
    0x2d, 0x72, 0x69, 0x70, 0x65, 0x6d, 0x64, 0x31,
    0x36, 0x30, 0x40, 0x6f, 0x70, 0x65, 0x6e, 0x73,
    0x73, 0x68, 0x2e, 0x63, 0x6f, 0x6d, 0x2c, 0x68,
    0x6d, 0x61, 0x63, 0x2d, 0x73, 0x68, 0x61, 0x31,
    0x2d, 0x39, 0x36, 0x2c, 0x68, 0x6d, 0x61, 0x63,
    0x2d, 0x6d, 0x64, 0x35, 0x2d, 0x39, 0x36, 0x00,
    0x00, 0x00, 0x1a, 0x7a, 0x6c, 0x69, 0x62, 0x40,
    0x6f, 0x70, 0x65, 0x6e, 0x73, 0x73, 0x68, 0x2e,
    0x63, 0x6f, 0x6d, 0x2c, 0x7a, 0x6c, 0x69, 0x62,
    0x2c, 0x6e, 0x6f, 0x6e, 0x65, 0x00, 0x00, 0x00,
    0x1a, 0x7a, 0x6c, 0x69, 0x62, 0x40, 0x6f, 0x70,
    0x65, 0x6e, 0x73, 0x73, 0x68, 0x2e, 0x63, 0x6f,
    0x6d, 0x2c, 0x7a, 0x6c, 0x69, 0x62, 0x2c, 0x6e,
    0x6f, 0x6e, 0x65, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack("C*")
  end
end
