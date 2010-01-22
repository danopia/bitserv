require 'rubygems'
require 'eventmachine'

module BitServ
class LineConnection < EventMachine::Connection
  attr_accessor :port, :ip
	
  def initialize
    super

    @buffer = ''
  end

  def post_init
    sleep 0.1
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    puts "Connected to #{@ip}:#{@port}"
  end
		
  def send_line line
    send_data "#{line}\r\n"
  end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
      line = @buffer.slice!(0, @buffer.index("\n")+1)
      receive_line line.chomp
    end
  end
  
  def receive_line line
    puts "Recieved data: #{line}"
  end
  
  def unbind
    puts "Connection closed to #{@ip}:#{@port}"
  end
end # class
end # module
