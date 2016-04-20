class Annealer
  def initialize(opts = {})
    max_iter = (opts[:max_iter] || 1000)
    
    @cooling_func = opts[:cooling_func] || lambda do |iter_count|
      Math.exp(-iter_count / (opts[:cooling_time] || max_iter * 1000))
    end
  
    @transition_probability = opts[:transition_probability] || lambda do |e0, e1, temp|
      Math.exp((e0 - e1) / temp)
    end
  
    @stop_condition = opts[:stop_condition] || lambda do |iter_count, best_energy|
      iter_count > max_iter
    end
    
    @repetition_count = opts[:repetition_count] || 1
    
    @logger = opts[:logger] || Class.new do
      def initialize(log_to)
        @log_to = log_to
      end
      
      def info(msg)
        @log_to.puts(msg) if @log_to
      end
    end.new(opts[:log_to])
    
    @log_progress_frequency = opts[:log_progress_frequency] || 5000
  end
  
  attr_accessor :logger
  
  # Given a (probably random) starting state, returns a state that approximately minimizes
  # an arbitrary "energy" metric.
  #
  # The given start_state must implement two methods:
  #
  #  - *energy*: Returns the metric you want to optimize.
  #  - *random_neighbor*:
  #      Returns a randomly selected new state which differs slightly from this one.
  #      This method _must not modify_ the original state, but instead return a clean copy.
  #      You must ensure that the entire state space you want to search is reachable by hopping
  #      from neighbor to neighbor. Ideally, the new state should be likely to have similar energy
  #      (i.e. "neighbors" should be small changes); at the same time, you don't want it to require
  #      too many hops between any two states.
  #
  def anneal(start_state)
    energy = start_state.energy
    best_state = start_state
    best_energy = energy

    logger.info "Starting state:"
    logger.info best_state.inspect
    
    @repetition_count.times do |rep|
      logger.info "Repetition #{rep}..." if @repetition_count > 1
      state = best_state
      
      iter_count = 0
      while !@stop_condition.call(iter_count, best_energy)
        temperature = @cooling_func.call(iter_count)
        new_state = state.random_neighbor
        new_energy = new_state.energy
        logger.info "Iteration #{iter_count} (energy = #{new_energy})..." if iter_count % @log_progress_frequency == 0
    
        if best_state.nil? || @transition_probability.call(energy, new_energy, temperature) > rand
          state, energy = new_state, new_energy
          if new_energy < best_energy
            best_state, best_energy = state, energy
            logger.info "New best solution on rep #{rep}, iter #{iter_count} with energy #{energy}:"
            logger.info state.inspect
          end
        end
    
        iter_count += 1
      end
    end
    
    best_state
  end
  
end
