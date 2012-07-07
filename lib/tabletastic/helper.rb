module Tabletastic
  module Helper
    # returns and outputs a table for the given active record collection
    def table_for(collection, *args, &block)
      block = Tabletastic.default_table_block unless block_given?
      klass = default_class_for(collection)
      options = args.extract_options!
      initialize_html_options(options, klass)
      builder = TableBuilder.new(collection, klass, self, params)
      inner_table = capture { block.call(builder) }
      outer_table = capture { content_tag(:table, inner_table, options[:html]) }
      action_prefix = builder.instance_variable_get(:@action_prefix)
      mass_actions = builder.instance_variable_get(:@mass_actions)
      if !mass_actions.blank?
        path = polymorphic_path([:mass_action, action_prefix,
                                 collection.klass.name.underscore.
                                  pluralize.to_sym])
        mass_actions_submit = content_tag(:div,
          select_tag(:mass_action, options_for_select([""] + mass_actions)) +
           submit_tag("Submit"),
          :class => "mass_actions_submit"
        )
        content_tag(:form, mass_actions_submit + outer_table,
                    :action => path, :method => :post)
      else
        outer_table
      end
    end

    private
    # Finds the class representing the objects within the collection
    def default_class_for(collection)
      if collection.respond_to?(:klass) # ActiveRecord::Relation
        collection.klass
      elsif !collection.empty?
        collection.first.class
      end
    end

    def initialize_html_options(options, klass)
      options[:html] ||= {}
      options[:html][:id] ||= get_id_for(klass)
      options[:html].reverse_merge!(Tabletastic.default_table_html)
    end

    def get_id_for(klass)
      klass ? klass.model_name.collection : ""
    end
  end
end

ActiveSupport.on_load(:action_view) do
  include Tabletastic::Helper
end
