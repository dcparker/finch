# Pathway. Basically a wrapper for a managed piece of the session.
class Pathway
  attr_accessor :path_name, :session

  # Send it a session and a name to operate as within the session.
  # If there is already an array stored at this key, a Pathway will be built around it.
  def initialize(session, path_name)
    self.session = session
    self.path_name = path_name
  end

  # Use this for accessing things in the session -- it returns a fake array if session is non-existent.
  def session
    (@session[:pathways].is_a?(Hash) && @session[:pathways][path_name].is_a?(Array) ? @session[:pathways][path_name] : []).keep_uniq!
  end
  # Use this for putting things in the session -- it makes sure the session is created.
  def session!
    @session[:pathways] ||= {}
    (@session[:pathways][path_name] ||= []).keep_uniq!
  end

  delegate_instance_methods [:<<, :push] => :session!
  delegate_instance_methods [:>>, :last] => :session

  # Clears the current pathway, and deletes the pathway key entirely if there are no pathways left.
  def clear
    pth = @session[:pathways] ? @session[:pathways].delete(path_name) : nil
    @session.delete(:pathways) if @session[:pathways] && @session[:pathways].empty?
    pth
  end
  # Pops from the end of the session, and removes the session if empty.
  def next
    nxt = session.pop
    clear if session.empty?
    return *nxt
  end
  def next?; session && !session.blank? end
end

module Bliss
  class Sequence
    class << self
      def sequences
        @sequences ||= {}.order!
      end
    end
    # Default priority is 5
    def initialize(priority=5)
      @priority = priority
    end
    def priority(amount=nil)
      amount.nil? ? @priority : (@priority = amount)
    end

    def force(name=nil)
      return @force if name.nil?
      @force = name
      if !self.class.sequences[name].nil?
        (@only ||= {}).merge!(self.class.sequences[name].only) if self.class.sequences[name].only.is_a?(Hash)
        (@except ||= {}).merge!(self.class.sequences[name].except) if self.class.sequences[name].except.is_a?(Hash)
        @condition = self.class.sequences[name].condition if @condition.nil?
      end
      self.class.sequences[name] = self
      self
    end
    def only(ca_hash=nil)
      return @only if ca_hash.nil?
      (@only ||= {}).merge!(ca_hash)
      self
    end
    def except(ca_hash=nil)
      return @except if ca_hash.nil?
      (@except ||= {}).merge!(ca_hash)
      self
    end
    def when(lamb)
      @condition = lamb
      self
    end
    def condition
      @condition
    end

    def valid?(controller)
      return false if condition.blank?
      only = @only ? (@only.has_key?(controller.class.name) ? @only[controller.class.name] : (@only.has_key?('All') ? @only['All'] : nil)) : nil
      except = @except ? (@except.has_key?(controller.class.name) ? @except[controller.class.name] : (@except.has_key?('All') ? @except['All'] : nil)) : nil
      (only.nil? || controller.params[:action].to_sym.is_one_of?(only)) && (except.nil? || controller.params[:action].to_sym.is_not_one_of?(except))
    end
  end

  module Sequencer
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def sequencer
        return lambda { |controller|
          # This is where we'll run the process of sending the user along to where he should be, if there is any necessary actions on the list.
          # Sorts by priority: Higher priority numbers are run first.
          Bliss::Sequence.sequences.sort {|a,b| b[1].priority <=> a[1].priority}.each do |name,sequence|
            controller.activate_sequence!(sequence)
          end
        }
      end

      def pathway(name)
        Pathway.new(session, name)
      end

      # Create sequences with a default priority of 5. Higher numbers are higher priority.
      def force(name,priority=5)
        ((@@sequences ||= []) << Bliss::Sequence.new(priority).force(name))[-1]
      end
      def only(ca_hash)
        ((@@sequences ||= []) << Bliss::Sequence.new.only(ca_hash))[-1]
      end
      def except(ca_hash)
        ((@@sequences ||= []) << Bliss::Sequence.new.except(ca_hash))[-1]
      end
      def when(lamb)
        ((@@sequences ||= []) << Bliss::Sequence.new.when(lamb))[-1]
      end
    end

    def activate_sequence!(sequence)
      raise ArgumentError unless sequence.is_a?(Bliss::Sequence)
      throw(:halt, begin_pathway(sequence.force)) if sequence.valid?(self) && eval(sequence.condition)
    end

    def pathway(name)
      Pathway.new(session, name)
    end

    def begin_pathway(name,next_url_args={},complete_url_args={})
      pathway("redirect_after_#{name.to_s}") << [request.path, complete_url_args]
      redirect(url(name,next_url_args))
    end
    def next_in_pathway(name)
      redirect(url(*(pathway("redirect_after_#{name.to_s}").next)))
    end
    alias :complete_pathway :next_in_pathway
  end
end

Application.send :include, Bliss::Sequencer
