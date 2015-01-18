module SchemaMonkey
  module ModuleSupport

    def include_once(base, mod)
      base.send(:include, mod) unless base.include? mod
    end

    def include_if_defined(base, parent, subname)
      if submodule = get_const(parent, subname)
        include_once(base, submodule)
      end
    end

    def patch(base, parent = SchemaMonkey)
      patch = get_const(parent, base)
      raise "#{parent} does not contain a definition of #{base}" unless patch
      include_once(base, patch)
    end

    # ruby 2.* supports mod.const_get("Component::Path") but ruby 1.9.3
    # doesn't.  And neither has a version that can return nil rather than
    # raising a NameError
    def get_const(mod, name)
      name.to_s.split('::').map(&:to_sym).each do |component|
        begin
          mod = mod.const_get(component, false)
        rescue NameError
          return nil
        end
      end
      mod
    end

    def get_modules(parent, opts={})
      opts = opts.keyword_args(:prefix, :match, :reject, :recursive, :respond_to, :and_self)
      parent = get_const(parent, opts.prefix) if opts.prefix
      return [] unless parent && parent.is_a?(Module)
      modules = []
      modules << parent if opts.and_self
      modules += parent.constants.map{|c| parent.const_get(c)}.select(&it.is_a?(Module))
      modules.reject! &it.to_s =~ opts.reject if opts.reject
      modules.select! &it.to_s =~ opts.match if opts.match
      modules.select! &it.respond_to?(opts.respond_to) if opts.respond_to
      modules += modules.flat_map { |mod| get_modules(mod, opts.except(:prefix, :and_self)) } if opts.recursive
      modules
    end
  end
end
