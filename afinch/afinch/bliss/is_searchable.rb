# The purpose of this library is to enhance DataMapper's Model.all functionality to include custom finder attributes/queries
# as well as the simply attributes. For example, a search could include a custom finder for 'middle-age' people,
# really meaning :conditions => ['age >= 21 AND age <= 40']
module IsSearchable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    DEFAULT_FINDER_ALIASES = {
      :now => lambda {Time.now}
    }
    
    # Specify custom_finders for a model.
    #   custom_finders :extended => 'extended_after < :now', # :now is a default finder alias for Time.now, to be executed at query runtime.
    #     :has_email => 'id IN (SELECT person_id FROM emails)', # Just checks for any email belonging to person.
    #     :email => 'id IN (SELECT person_id FROM emails WHERE verified = 1 AND address IN ?)', # Checks for any of the emails in the list.
    #     :phone => 'id IN (SELECT person_id FROM phone_numbers WHERE verified = ? AND number IN ?', # Checks for any of the phone numbers in the list.
    #     :openid_url => 'id IN (SELECT person_id FROM logins WHERE openid_url = ?)', # Just checks for any login belonging to person.
    #     :login => 'guid IN (SELECT person_guid FROM logins WHERE nickname = ?)' # Checks for a specific login.
    # When casting these to sql, the value given the key in the finder options hash is appended to the array of values to quote, IF there is a ? in the sql given here.
    def custom_finders(options=nil)
      extend SearchableClassMethods
      return(@custom_finders ||= {}) if options.nil?
      custom_finders.merge!(options)
      # I really should complain here about bad values. Otherwise an error may be raised when a find is attempted, or even simply unexpected results.
    end

    # Can be used to create an alias for values in searches. These will be simply interpolated.
    def finder_alias(key,value=nil)
      key, value = key.to_a[0] if key.is_a?(Hash)
      @finder_aliases ||= DEFAULT_FINDER_ALIASES
      @finder_aliases[key] = value
    end

    module SearchableClassMethods
      # Model.first will work as normal, but any filters added will be translated.
      # 1) Translate any custom_finder options
      # 2) Remove any invalid finder options
      def first(options={})
        super(only_valid_find_options(translate_find_options({}.merge(options).symbolize_keys))) # {}.merge to overcome the HashWithIndifferentAccess problem
      end

      # Model.all will work as normal, but any filters added will be translated.
      # 1) Translate any custom_finder options
      # 2) Remove any invalid finder options
      def all(options={})
        super(only_valid_find_options(translate_find_options({}.merge(options).symbolize_keys))) # {}.merge to overcome the HashWithIndifferentAccess problem
      end

      private
        # Simply translates known translatable options.
        def translate_find_options(options)
          conditions, *sql_args = options.delete(:conditions) || []
          conditions = [conditions].compact
          options.each_key do |k|
            if @custom_finders.has_key?(k)
              search_value = options.delete(k)
              unless search_value.is_a?(Array) && search_value.empty?
                condition = (@custom_finders[k].is_a?(Hash) ? @custom_finders[k][search_value.class.name.to_sym] : @custom_finders[k])
                # strip out the proc if one was supplied, and modify the search_value.
                if condition.is_a?(Array)
                  search_value = condition[1].call(search_value) if condition[1].is_a?(Proc)
                  condition = condition[0]
                end
                conditions << condition
                if (needs = (' '+conditions.last+' ').split('?').length - 2) > -1
                  sql_args << (search_value.is_a?(Array) ? search_value[0..needs] : (0..needs).inject([]) {|a,v| a << search_value; a})
                end
              end
            end
          end
          options[:conditions] = [conditions.map {|e| '(' + e + ')'}.join(' AND '), sql_args].flatten if !conditions.blank?
          # Merb.logger.info "*** Find options: #{options.inspect}"
          options
        end

        def only_valid_find_options(options)
          ret = {}.merge(options).symbolize_keys.only(*(table.columns.collect(&:name) << :conditions))
          # Merb.logger.info "Valids: #{ret.keys.inspect} (from #{{}.merge(options).symbolize_keys.keys.inspect})"
          # ret
        end
    end
  end
end

DataMapper::Base.send(:include, IsSearchable)



# def search_count(query, options={})
#   filters = options[:filters] || {}
#   self.count_by_sql("SELECT COUNT(*) FROM (SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id) as tmpA")
# end
# def search(query, options={})
#   limit = options[:limit] || 10
#   offset = options[:offset] || 0
#   filters = options[:filters] || {}
#   puts "SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id LIMIT #{limit} OFFSET #{offset}"
#   self.find_by_sql("SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id LIMIT #{limit} OFFSET #{offset}")
# end
# def render_condition_for_query_and_filters(query, filters) #search in: first_name, last_name, identifier
#   "WHERE (#{self.render_query_condition(query)}) AND (#{self.render_filter_condition(filters)})"
# end
# def render_query_condition(query)
#   self.replace_named_bind_variables(@query_condition, {:query => query, :like_query => '%' + query.to_s + '%'})
# end
# def render_filter_condition(filters)
#   [1, filters.collect do |key,val|
#     val = "%#{val}%" if @filter_comparisons[key.to_s] =~ /LIKE/
#     self.replace_bind_variables(@filter_comparisons[key.to_s], [val])
#   end].flatten.join(' AND ')
# end
