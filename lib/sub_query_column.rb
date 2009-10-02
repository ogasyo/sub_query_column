# SubQueryColumn
module SubQueryColumn
    
    def self.enable
        ActiveRecord::Base.send :include, ArExtension
    end
    
    
    module ArExtension # :nodoc:
        def self.included(base)
            base.class_eval do
                named_scope :with_sub_query_column, lambda {|*args| {:select => sub_query_column_get_select(args)} }
            end
            base.extend ClassMethods
        end

        module ClassMethods
            @@sub_query_columns = {}
            
            def sub_query_column(name, options={})
                return false if name.blank?
                
                options[:name] = name
                options[:alias_name] ||= name
                options[:type] ||= :string
                
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
                
                @@sub_query_columns[name] = options
            end
            
            def sub_query_column_get_select(*args)
                args = @@sub_query_columns.keys if args.first.empty?
                select = ["*"]
                args.each do |arg|
                    key = Symbol === arg ? arg : arg.pop
                    if options = @@sub_query_columns[key]
                        select << "(#{options[:query]}) AS #{options[:alias_name]}"
                    end
                end
                return select.join(', ')
            end
        end
        
    end
    
    
    module VERSION # :nodoc:
        MAJOR = 0
        MINOR = 0
        TINY  = 1
        STRING = [MAJOR, MINOR, TINY].join('.')
    end
    
end