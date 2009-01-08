# Validations are currently NOT exempt from OrmAuthorization!

class Unauthorized < StandardError #:nodoc:
end
module OrmAuthorization
  def self.merge_finder_options(options, merger)
    # Extract the conditions from options.
    conditions, *sql_args = options.delete(:conditions) || []
    conditions = [conditions].compact

    # Extract the conditions from merger.
    mconditions, *msql_args = merger.delete(:conditions) || []
    mconditions = [mconditions].compact

    # Combine them.
    conditions = conditions + mconditions
    sql_args = sql_args + msql_args

    # Recompile them.
    options[:conditions] = [conditions.map {|e| '(' + e + ')'}.join(' AND '), sql_args].flatten if !conditions.blank?
    options.merge(merger)
  end
  
  def self.included(base)
    base.class_eval do
      def destroy
        self.class.check_auth('destroy', self) if OrmAuthorization.on?
        super
      end
      def update
        self.class.check_auth('update', self) if OrmAuthorization.on?
        super
      end

      def is_readable_by?(openid_url=nil)
        self.class.authorized?('read', self, openid_url || Person.current_guid)
      end
      def is_updatable_by?(openid_url=nil)
        self.class.authorized?('read', self, openid_url || Person.current_guid)
      end
      def is_destroyable_by?(openid_url=nil)
        self.class.authorized?('read', self, openid_url || Person.current_guid)
      end

      class << self
        def create(*a)
          OrmAuthorization.on? ? check_auth('create', super) : super
        end
        def [](*a)
          OrmAuthorization.on? ? check_auth('read', super) : super
        end
        def first(*args)
          if OrmAuthorization.on?
            args = [{}] if args.blank? || args.first.nil?
            args.each {|aa| aa.merge!(auth_conditions) if aa.is_a?(Hash) } if can_auth?
            check_auth('read', super(*args))
          else
            super
          end
        end
        def all(*args)
          if OrmAuthorization.on?
            args = [{}] if args.blank? || args.first.nil?
            args.each {|aa| aa.merge!(auth_conditions) if aa.is_a?(Hash) } if can_auth?
            super(*args).each {|r| check_auth('read', r) }
          else
            super
          end
        end

        def readable(&block)
          @authorize_readable = block
        end

        def authorize_create(unauthorized_message=nil,&block)
          (@authorize_create ||= []) << [unauthorized_message, block]
          true
        end
        def authorize_read(unauthorized_message=nil,&block)
          (@authorize_read ||= []) << [unauthorized_message, block]
          true
        end
        def authorize_update(unauthorized_message=nil,&block)
          (@authorize_update ||= []) << [unauthorized_message, block]
          true
        end
        def authorize_destroy(unauthorized_message=nil,&block)
          (@authorize_destroy ||= []) << [unauthorized_message, block]
          true
        end

        def belongs_to_with_authorization(association_name,options={},&block)
          belongs_to(association_name,OrmAuthorization.merge_finder_options(options, :lambda => lambda {can_auth?(block) ? block.call(Person.current_guid) : {}}))
        end
        def has_many_with_authorization(association_name,options={},&block)
          has_many(association_name,OrmAuthorization.merge_finder_options(options, :lambda => auth_lambda(block)))
        end
        def has_one_with_authorization(association_name,options={},&block)
          has_one(association_name,OrmAuthorization.merge_finder_options(options, :lambda => lambda {can_auth?(block) ? block.call(Person.current_guid) : {}}))
        end

        def can_auth?(auth_proc=nil)
          auth_proc ||= @authorize_readable
          OrmAuthorization.on? && Application.signed_in? && auth_proc.is_a?(Proc)
        end
        def auth_conditions
          @authorize_readable.call(Person.current_guid) if Application.signed_in? && @authorize_readable.is_a?(Proc)
        end
        def auth_lambda(proc=nil,&block)
          block = proc if proc
          lambda {can_auth?(block) ? block.call(Person.current_guid) : {}}
        end

        private
          def check_auth(action, record)
            unless OrmAuthorization.off? || record.nil?
              message = false.static(:message => 'Not logged in!')
              raise(Unauthorized, "Unauthorized to #{action.upcase} #{record.class.name} ##{record.id}: #{message.message}") unless Application.signed_in? && message = authorized?(action, record, Person.current_guid)
            end
            record
          end
          def authorized?(action, record, guid)
            raise ArgumentError unless action.is_one_of?('create', 'read', 'update', 'destroy')
            (instance_variable_get('@authorize_'+action) || []).each do |auth|
              return false.static(:message => auth[0]) unless auth[1].call(record, guid)
            end if !record.nil?
            return true
          end
      end
    end
  end

  def self.on?
    !Thread.current['orm_authorization'] # Using Thread.current, it's thread-safe for turning OrmAuthorization.off! or .on!
  end
  def self.off?
    !on?
  end
  def self.on!
    Thread.current['orm_authorization'] = false
  end
  def self.off!
    Thread.current['orm_authorization'] = true
  end
end

module Kernel
  def without_orm_authorization(&block)
    off = OrmAuthorization.off?
    OrmAuthorization.off!
    re = yield
    OrmAuthorization.on! unless off
    return re
  end
end
