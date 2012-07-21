require 'psych'
require "yaml"
require 'thread'

class ExtQueue

  #
  # Create new Queue with on-demand external memory storage.
  # Requires read-write access to working directory.
  #
  # The class is not preserving the order of elements
  # as would be expected for a Queue.
  #
  # TODO: Modify this class to check for actual memory consumption rather than element count
  #

  def initialize(max_elem_in_memory, prefix)
    @data = []
    @waiting=[]

    @q_max = 0
    @q_min = 0

    @lock = Mutex.new

    @max_elem = max_elem_in_memory
    @swap_fraction = 0.5;  # fraction of data to write to disk when exceeding the queue limit
    @num = (@max_elem * @swap_fraction).ceil

    # filename prefix for the storage
    @prefix = prefix

    @data.taint
    @waiting.taint
    self.taint
  end


  ## Enqueue
  def push(obj)
    @lock.synchronize{
      writeToDisk if @data.length>=@max_elem
      @data.push obj
      begin
        t = @waiting.shift
        t.wakeup if t
      rescue ThreadError
        retry
      end
    }
    self
  end

  #
  # Alias of push
  #
  alias << push

  #
  # Alias of push
  #
  alias enq push



  #
  # Retrieves data from the queue.  If the queue is empty, the calling thread is
  # suspended until data is pushed onto the queue.  If +non_block+ is true, the
  # thread isn't suspended, and an exception is raised.
  #
  def pop(non_block=false)
    @lock.synchronize{
      while true
        if self.empty?
          raise ThreadError, "queue empty" if non_block
          @waiting.push Thread.current
          @lock.sleep
        else
          readFromDisk if @data.empty? and (@q_min < @q_max)
          return @data.shift
        end
      end
    }
  end

  #
  # Alias of pop
  #
  alias shift pop

  #
  # Alias of pop
  #
  alias deq pop



  def clear
    @lock.synchronize {
      @data.clear
      (@q_min..@q_max).each { |i| File.unlink("#{@prefix}#{i}.anemone") }
      @q_min = 0
      @q_max = 0
    }
  end

  def length
    @data.length
  end

  alias size length

  def empty?
    @data.empty? and @q_min==@q_max
  end

  #
  # Returns the number of threads waiting on the queue.
  #
  def num_waiting
    @waiting.size
  end

  private

  def writeToDisk
    File.open("#{@prefix}#{@q_max}.anemone","w+") do |file|
      popped = @data.pop(@num)
      popped.each { |elem| file.puts YAML::dump(elem) }
      @q_max += 1
    end
  end

  def readFromDisk
    $/="\n\n"
    f = File.open("#{@prefix}#{@q_min}.anemone","r")
    f.each do |obj|
      @data.unshift( YAML::load(obj) )
    end
    f.close
    @q_min += 1
    $/="\n"
    File.unlink("#{@prefix}#{@q_min-1}.anemone");
  end

end