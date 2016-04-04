module Spree::Chimpy
  class Subscription
    delegate :configured?, :enqueue, to: Spree::Chimpy

    def initialize(model)
      @model      = model
    end

    def subscribe
      return unless configured?
      defer(:subscribe) if subscribing?
    end

    def unsubscribe
      return unless configured?
      defer(:unsubscribe) if unsubscribing?
    end

    def resubscribe(&block)
      block.call if block

      return unless configured?

      if unsubscribing?
        defer(:unsubscribe)
      elsif subscribing? || merge_vars_changed?
        defer(:subscribe)
      end
    end
    
    def update_member(&block)
      block.call if block

      return unless configured?

      if unsubscribing?
        defer(:leave_group)
      elsif subscribing? || merge_vars_changed?
        defer(:join_group)
      elsif @model.email_changed?
        defer(:update_email)
      end
    end

  private
    def defer(event)
      enqueue(event, @model)
    end

    def subscribing?
      @model.subscribed && (@model.subscribed_changed? || @model.id_changed? || @model.new_record?)
    end

    def unsubscribing?
      !@model.new_record? && !@model.subscribed && @model.subscribed_changed?
    end

    def merge_vars_changed?
      Config.merge_vars.values.any? do |attr|
        name = "#{attr}_changed?".to_sym
        !@model.methods.include?(name) || @model.send(name)
      end
    end
  end
end
