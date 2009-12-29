# SubQueryColumn
module SubQueryColumn
    
    def self.enable
        ActiveRecord::Base.send :include, ArExtension
    end
    
    
    module ArExtension # :nodoc:
        def self.included(base)
            base.extend ClassMethods
        end

        module ClassMethods
            
            def sub_query_column(name, options={})
                return false if name.blank?
                
                class << self
                    attr_accessor :sub_query_columns, :sub_query_columns_keys
                end
                
                self.sub_query_columns ||= {}
                self.sub_query_columns_keys ||= []
                Rails.logger.debug "[sub_query_column] Register #{self.name}.#{name}"
                
                named_scope(:with_sub_query_column, lambda {|*args| sub_query_column_get_select(self, args) })
                named_scope(:"filter_#{name}", lambda {|params| sub_query_column_get_conditions(self, name, params) })
                
                case options[:type]
                when :integer
                    define_method("#{name}") do # 引数なし
                        value = self.attributes["#{name}"] || 0
                        value.to_i
                    end
                else
                    define_method("#{name}") do # 引数なし
                        value = self.attributes["#{name}"] || nil
                    end
                end
                
                options[:name] = name
                options[:alias_name] ||= name
                options[:type] ||= :string
                options[:filter] ||= nil
                
                self.sub_query_columns[name] = options
                self.sub_query_columns_keys << name unless self.sub_query_columns_keys.include?(name)
            end
            
            def sub_query_column_get_select(klass, *args)
                options = args.pop if args.last.is_a?(Hash)
                keys = args.flatten || []
                keys = self.sub_query_columns_keys if keys.empty?
                return {} unless keys && keys.length > 0
                
                Rails.logger.debug "[sub_query_column] get_select: #{klass.name} => #{keys.inspect}"
                selects = ["#{klass.table_name}.*"]
                keys.each do |key|
                    if options = self.sub_query_columns[key]
                        selects << "(#{options[:query]}) AS #{options[:alias_name]}"
                    end
                end
                return { :select => selects.join(', ') }
            end
            
            def sub_query_column_get_conditions(klass, name, params={})
                name = name.to_sym unless name.is_a?(Symbol)
                options = self.sub_query_columns[name] rescue nil
                sql = options[:query] rescue nil
                cond = options[:filter] rescue nil
                return {} if sql.blank? || cond.blank?
                
                Rails.logger.debug "[sub_query_column] get_conditions: #{klass.name} => #{options.inspect}, name => #{name}, cond => #{cond}"
                return { :conditions => ["(#{sql}) #{cond}", params] }
            end
        end
        
    end
    
    
    module VERSION # :nodoc:
        MAJOR = 0
        MINOR = 0
        TINY  = 2
        STRING = [MAJOR, MINOR, TINY].join('.')
    end
    
end