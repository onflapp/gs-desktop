all::
	-@$(foreach eddir,$(foreach ddir,$(DEPENDENCIES_DIRS),$(wildcard $(ddir))),echo "Making $@ in dependency directory '$(eddir)'..."; ( cd $(eddir) && make $@);)
