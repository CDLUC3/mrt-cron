# frozen_string_literal: true

class ObjectHealthStats
  def initialize(loop_sleep)
    @loops = []
    @loop_sleep = loop_sleep
  end

  def loop_num
    @loops.length
  end

  def loop_start
    @loops.append({
                    start: Time.now,
                    count: 0
                  })
  end

  def increment
    @loops[-1][:count] = @loops[-1][:count] + 1 unless @loops.empty?
  end

  def log_loop(last: false)
    return if @loops.empty?

    puts format('%10s: %s objects; time %ss',
                "Loop #{loop_num}",
                ObjectHealthUtil.num_format(@loops[-1][:count]),
                ObjectHealthUtil.num_format((Time.now - @loops[-1][:start]).to_i))
    return if last

    puts "\tSleep before next loop: #{@loop_sleep}s"
    sleep(@loop_sleep)
  end

  def log_loops
    return if @loops.empty?

    sum = 0
    @loops.each do |s|
      sum += s[:count]
    end
    puts format("\n\n%-10s: %s objects; time %ss",
                "#{loop_num} Loops",
                ObjectHealthUtil.num_format(sum),
                ObjectHealthUtil.num_format((Time.now - @loops[0][:start]).to_i))
  end
end
