module Sorge
  class Engine
    TaskStatus = Struct.new(
      :state,
      :trigger_state,
      :pending,
      :running,
      :finished,
      :position
    ) do
      def initialize(*args)
        super
        self.state ||= {}
        self.trigger_state ||= {}
        self.pending ||= PaneSet.new
        self.running ||= nil
        self.finished ||= [] # Array<Time>
        self.position ||= Time.at(0)
      end

      def freeze!
        values.each(&:freeze)
        freeze
      end

      def active?
        !(running.nil? && finished.empty?)
      end

      def complete?
        pending.empty? && running.nil? && finished.empty?
      end

      def pending?
        !active? && !complete?
      end

      def dump
        ret = {}
        ret[:st]  = state               unless state.empty?
        ret[:tst] = trigger_state       unless trigger_state.empty?
        ret[:pnd] = pending.dump        unless pending.empty?
        ret[:run] = running.dump        unless running.nil?
        ret[:fin] = finished            unless finished.empty?
        ret[:pos] = position            unless position.to_i.zero?
        ret
      end

      def self.restore(hash)
        o = new
        o.state         = hash[:st]                   if hash.include?(:st)
        o.trigger_state = hash[:tst]                  if hash.include?(:tst)
        o.pending       = PaneSet.restore(hash[:pnd]) if hash.include?(:pnd)
        o.running       = Pane.restore(hash[:run])    if hash.include?(:run)
        o.finished      = hash[:fin]                  if hash.include?(:fin)
        o.position      = hash[:pos]                  if hash.include?(:pos)

        o.freeze!
      end
    end
  end
end
