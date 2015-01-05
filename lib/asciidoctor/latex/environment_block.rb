# Test doc: samples/env.adoc


# EnvironmentBlock is a first draft for a better
# way of handing a construct in Asciidoc that
# will map to LaTeX environments.  See
# issue #1 in asciidoctor/asciidoctor-latex.
#
# The code below is based on @mojavelinux's
# outline. The EnvironmentBlock is called
# into action (please ... give me a more
# precise phrase here!) when text
# of the form [env.foo] is encountered.
# This is the signal to create a block
# of type environment. (Is this correct?)
# and environment-type "foo"
#
# In the act of creating an environment
# block, information extracted from
# [env.foo] is used to title the block
# as "Foo n", where n is a counter for
# environments of type "foo".  The
# counter is created in a hash the first
# time an environment of that kind
# is encountered.  We set
#
#    counter["foo"] = 1
#
# Subsequent encounters cause the
# counter to be incremented.
#
# Later, when the backend process the AST,
# the information bundled by the
# EnvironmentBlock is used as is
# appropriate. In the case of conversion
# to LaTeX, the content of the block
# simply enclosed in delimiters as
# follows:
#
# \begin{foo} CONTENT \end{foo}
#
# Additionally, label information
# for cross-referencing is added at
# this stage.
#
# If, on the other hand, the backend
# is HTML, then the title (with numbering)
# that is extracted from [env.foo] is used
# to title the block.  Additional styling
# is added so as to conform to LaTeX
# conventions: the body of the block is
# italicized.

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'


module Asciidoctor::LaTeX
  class EnvironmentBlock < Asciidoctor::Extensions::BlockProcessor

    use_dsl

    named :env
    on_context :open
    # parse_context_as :complex
    # ^^^ The above line gave me an error.  I'm not sure what do to with it.

    # Hash to count the number of times each environment is encountered
    # Global variables again.  Is there a better way?
    $counter = {}
    $ref2counter = {}

    def process parent, reader, attrs

      # Ensure that role is defined
      if attrs['role'] == nil
        role = 'item'
      else
        role = attrs['role']
      end

      # Determine whether this is a numbered block
      # FIXME: what if there are several options?
      if attrs['options'].nil?
        attrs['options'] = 'numbered'
      elsif !(attrs['options'].include? 'no-number')
        # attrs['options'] = 'numbered'
      end

      warn "env_name: #{env_name}".cyan if $VERBOSE
      warn "end EnvironmentBlock\n".blue if $VERBOSE

      env_name = role # roles.first # FIXME: roles.first is probably best
      env_title = env_name.capitalize
      if role == 'equation'
        attrs['title'] = nil
      else
        attrs['title'] = env_name.capitalize
      end

      if attrs['role'] == 'code'
        block = create_block parent, :listing, reader.lines, attrs
      else
        block = create_block parent, :environment, reader.lines, attrs
      end

      warn "document.references".blue + " #{parent.document.references}".cyan
      warn "id".red + " = #{attrs['id']}".yellow

      if attrs['options']['numbered']
        caption_num = parent.document.counter_increment("#{env_name}-number", block)
        caption = "#{caption_num}"
        attrs['title'] = "#{env_title} #{caption_num}."
        warn "eb: ".blue + "caption: #{caption}, title = #{attrs['title']}".magenta
      else
        attrs['title'] = "#{env_title} #{caption_num}."
        warn "eb: ".blue + "caption: #{caption}, title = #{attrs['title']}".magenta
      end

      if attrs['id'] and caption
        warn "registering #{caption} for #{attrs['id']}".magenta
        parent.document.register :ids, [attrs['id'], caption]
        warn "document.references".red + " #{parent.document.references}".yellow
      end


      block.assign_caption caption
      if role != 'equation'
        block.title = attrs['title']
      end
      block

    end

  end
end