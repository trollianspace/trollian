 # frozen_string_literal: true

require 'singleton'
require_relative './sanitize_config'

class Formatter
  include Singleton
  include RoutingHelper

  include ActionView::Helpers::TextHelper

  def format(status, **options)
    if status.reblog?
      prepend_reblog = status.reblog.account.acct
      status         = status.proper
    else
      prepend_reblog = false
    end

    raw_content = status.text

    if options[:inline_poll_options] && status.preloadable_poll
      raw_content = raw_content + "\n\n" + status.preloadable_poll.options.map { |title| "[ ] #{title}" }.join("\n")
    end

    return '' if raw_content.blank?

    unless status.local?
      html = reformat(raw_content)
      html = encode_custom_emojis(html, status.emojis, options[:autoplay]) if options[:custom_emojify]
      html = format_bbcode(html)
      return html.html_safe # rubocop:disable Rails/OutputSafety
    end

    linkable_accounts = status.active_mentions.map(&:account)
    linkable_accounts << status.account

    html = raw_content
    html = "RT @#{prepend_reblog} #{html}" if prepend_reblog
    useless = raw_content.match(/\[img.*\]/)
    if useless == nil
      html = encode_and_link_urls(html, linkable_accounts)
    end
    html = encode_custom_emojis(html, status.emojis, options[:autoplay]) if options[:custom_emojify]
    html = simple_format(html, {}, sanitize: false)
    html = html.delete("\n")
    html = format_bbcode(html)

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def fix_newlines(html)
    fix = html.gsub(/<\/p>\s*<p>/, "<br><br>\n")
    fix.gsub(/<br \/>/, "<br>\n")
  end

  def reformat(html)
    html = sanitize(html, Sanitize::Config::MASTODON_STRICT)
    format_bbcode(html)
  end

  def plaintext(status)
    return status.text if status.local?

    text = status.text.gsub(/(<br \/>|<br>|<\/p>)+/) { |match| "#{match}\n" }
    strip_tags(text)
  end

  def simplified_format(account, **options)
    html = account.local? ? linkify(account.note) : reformat(account.note)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def sanitize(html, config)
    Sanitize.fragment(html, config)
  end

  def format_spoiler(status, **options)
    html = encode(status.spoiler_text)
    html = encode_custom_emojis(html, status.emojis, options[:autoplay])
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_poll_option(status, option, **options)
    html = encode(option.title)
    html = encode_custom_emojis(html, status.emojis, options[:autoplay])
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_display_name(account, **options)
    html = encode(account.display_name.presence || account.username)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def format_field(account, str, **options)
    return reformat(str).html_safe unless account.local? # rubocop:disable Rails/OutputSafety
    html = encode_and_link_urls(str, me: true)
    html = encode_custom_emojis(html, account.emojis, options[:autoplay]) if options[:custom_emojify]
    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def linkify(text)
    useless = text.match(/\[img.*\]/)
    if useless == nil
    html = encode_and_link_urls(text)
    else
    html = text
    end
    html = simple_format(html, {}, sanitize: false)
    html = html.delete("\n")
    html = format_bbcode(html)

    html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def html_entities
    @html_entities ||= HTMLEntities.new
  end

  def encode(html)
    html_entities.encode(html)
  end

  def encode_and_link_urls(html, accounts = nil, options = {})
    entities = utf8_friendly_extractor(html, extract_url_without_protocol: false)

    if accounts.is_a?(Hash)
      options  = accounts
      accounts = nil
    end

    rewrite(html.dup, entities) do |entity|
      if entity[:url]
        if entity[:indices][0] > 4 && html[entity[:indices][0]-5..entity[:indices][0]-1] == "[url="
          entity[:url]
        else
          link_to_url(entity, options)
        end
      elsif entity[:hashtag]
        link_to_hashtag(entity)
      elsif entity[:screen_name]
        link_to_mention(entity, accounts)
      end
    end
  end

  def count_tag_nesting(tag)
    if tag[1] == '/' then -1
    elsif tag[-2] == '/' then 0
    else 1
    end
  end

  def encode_custom_emojis(html, emojis, animate = false)
    return html if emojis.empty?

    emoji_map = emojis.each_with_object({}) { |e, h| h[e.shortcode] = [full_asset_url(e.image.url), full_asset_url(e.image.url(:static))] }

    i                     = -1
    tag_open_index        = nil
    inside_shortname      = false
    shortname_start_index = -1
    invisible_depth       = 0

    while i + 1 < html.size
      i += 1

      if invisible_depth.zero? && inside_shortname && html[i] == ':'
        shortcode = html[shortname_start_index + 1..i - 1]
        emoji     = emoji_map[shortcode]

        if emoji
          original_url, static_url = emoji
          replacement = begin
            if animate
              "<img draggable=\"false\" class=\"emojione\" alt=\":#{encode(shortcode)}:\" title=\":#{encode(shortcode)}:\" src=\"#{encode(original_url)}\" />"
            else
              "<img draggable=\"false\" class=\"emojione custom-emoji\" alt=\":#{encode(shortcode)}:\" title=\":#{encode(shortcode)}:\" src=\"#{encode(static_url)}\" data-original=\"#{original_url}\" data-static=\"#{static_url}\" />"
            end
          end
          before_html = shortname_start_index.positive? ? html[0..shortname_start_index - 1] : ''
          html        = before_html + replacement + html[i + 1..-1]
          i          += replacement.size - (shortcode.size + 2) - 1
        else
          i -= 1
        end

        inside_shortname = false
      elsif tag_open_index && html[i] == '>'
        tag = html[tag_open_index..i]
        tag_open_index = nil
        if invisible_depth.positive?
          invisible_depth += count_tag_nesting(tag)
        elsif tag == '<span class="invisible">'
          invisible_depth = 1
        end
      elsif html[i] == '<'
        tag_open_index   = i
        inside_shortname = false
      elsif !tag_open_index && html[i] == ':'
        inside_shortname      = true
        shortname_start_index = i
      end
    end

    html
  end

  def rewrite(text, entities)
    text = text.to_s

    # Sort by start index
    entities = entities.sort_by do |entity|
      indices = entity.respond_to?(:indices) ? entity.indices : entity[:indices]
      indices.first
    end

    result = []

    last_index = entities.reduce(0) do |index, entity|
      indices = entity.respond_to?(:indices) ? entity.indices : entity[:indices]
      result << encode(text[index...indices.first])
      result << yield(entity)
      indices.last
    end

    result << encode(text[last_index..-1])

    result.flatten.join
  end

  UNICODE_ESCAPE_BLACKLIST_RE = /\[img\]|\p{Z}|\p{P}|/

  def utf8_friendly_extractor(text, options = {})
    old_to_new_index = [0]

    escaped = text.chars.map do |c|
      output = begin
        if c.ord.to_s(16).length > 2 && UNICODE_ESCAPE_BLACKLIST_RE.match(c).nil?
          CGI.escape(c)
        else
          c
        end
      end

      old_to_new_index << old_to_new_index.last + output.length

      output
    end.join

    # Note: I couldn't obtain list_slug with @user/list-name format
    # for mention so this requires additional check
    special = Extractor.extract_urls_with_indices(escaped, options).map do |extract|
      new_indices = [
        old_to_new_index.find_index(extract[:indices].first),
        old_to_new_index.find_index(extract[:indices].last),
      ]

      next extract.merge(
        indices: new_indices,
        url: text[new_indices.first..new_indices.last - 1]
      )
    end

    standard = Extractor.extract_entities_with_indices(text, options)

    Extractor.remove_overlapping_entities(special + standard)
  end

  def link_to_url(entity, options = {})
    url        = Addressable::URI.parse(entity[:url])
    html_attrs = { target: '_blank', rel: 'nofollow noopener' }

    html_attrs[:rel] = "me #{html_attrs[:rel]}" if options[:me]

    Twitter::Autolink.send(:link_to_text, entity, link_html(entity[:url]), url, html_attrs)
  rescue Addressable::URI::InvalidURIError, IDN::Idna::IdnaError
    encode(entity[:url])
  end

  def link_to_mention(entity, linkable_accounts)
    acct = entity[:screen_name]

    return link_to_account(acct) unless linkable_accounts

    account = linkable_accounts.find { |item| TagManager.instance.same_acct?(item.acct, acct) }
    account ? mention_html(account) : "@#{encode(acct)}"
  end

  def link_to_account(acct)
    username, domain = acct.split('@')

    domain  = nil if TagManager.instance.local_domain?(domain)
    account = EntityCache.instance.mention(username, domain)

    account ? mention_html(account) : "@#{encode(acct)}"
  end

  def link_to_hashtag(entity)
    hashtag_html(entity[:hashtag])
  end

  def link_html(url)
    url    = Addressable::URI.parse(url).to_s
    prefix = url.match(/\Ahttps?:\/\/(www\.)?/).to_s
    text   = url[prefix.length, 30]
    suffix = url[prefix.length + 30..-1]
    cutoff = url[prefix.length..-1].length > 30

    "<span class=\"invisible\">#{encode(prefix)}</span><span class=\"#{cutoff ? 'ellipsis' : ''}\">#{encode(text)}</span><span class=\"invisible\">#{encode(suffix)}</span>"
  end

  def hashtag_html(tag)
    "<a href=\"#{encode(tag_url(tag))}\" class=\"mention hashtag\" rel=\"tag\">#<span>#{encode(tag)}</span></a>"
  end

  def mention_html(account)
    "<span class=\"h-card\"><a href=\"#{encode(ActivityPub::TagManager.instance.url_for(account))}\" class=\"u-url mention\">@<span>#{encode(account.username)}</span></a></span>"
  end
 
  def format_bbcode(html)
    colorhex = {
      :html_open => '<span class="bbcode__color" data-bbcodecolor="#%colorcode%">', :html_close => '</span>',
      :description => 'Use color code',
      :example => '[colorhex=ffffff]White text[/colorhex]',
      :allow_quick_param => true, :allow_between_as_param => false,
      :quick_param_format => /([0-9a-fA-F]{6})/,
      :quick_param_format_description => 'The size parameter \'%param%\' is incorrect',
      :param_tokens => [{:token => :colorcode}]}

   begin
      html = html.bbcode_to_html(false, {
      :img => {
        :html_open => '<img src="%between%" %width%%height%alt="" />', :html_close => '',
        :description => 'Image',
        :example => '[img]http://www.google.com/intl/en_ALL/images/logo.gif[/img].',
        :only_allow => [],
        :require_between => true,
        :allow_quick_param => true, 
        :allow_between_as_param => false,
        :quick_param_format => /^(\d+)x(\d+)$/,
        :param_tokens => [{ :token => :width, :prefix => 'width="', :postfix => '" ', :optional => true },
                              { :token => :height,  :prefix => 'height="', :postfix => '" ', :optional => true } ],
        :quick_param_format_description => 'The image parameters \'%param%\' are incorrect, \'<width>x<height>\' excepted'},
        :spin => {
          :html_open => '<span class="bbcode__spin">', :html_close => '</span>',
          :description => 'Make text spin',
          :example => 'This is [spin]spin[/spin].'},
        :pulse => {
          :html_open => '<span class="bbcode__pulse">', :html_close => '</span>',
          :description => 'Make text pulse',
          :example => 'This is [pulse]pulse[/pulse].'},
        :b => {
          :html_open => '<span class="bbcode__b">', :html_close => '</span>',
          :description => 'Make text bold',
          :example => 'This is [b]bold[/b].'},
        :i => {
          :html_open => '<span class="bbcode__i">', :html_close => '</span>',
          :description => 'Make text italic',
          :example => 'This is [i]italic[/i].'},
        :flip => {
          :html_open => '<span class="bbcode__flip-%direction%">', :html_close => '</span>',
          :description => 'Flip text',
          :example => '[flip=horizontal]This is flip[/flip]',
          :allow_quick_param => true, :allow_between_as_param => false,
          :quick_param_format => /(horizontal|vertical)/,
          :quick_param_format_description => 'The size parameter \'%param%\' is incorrect, a number is expected',
          :param_tokens => [{:token => :direction}]},
        :large => {
          :html_open => '<span class="bbcode__large-%size%">', :html_close => '</span>',
          :description => 'Large text',
          :example => '[large=2x]Large text[/large]',
          :allow_quick_param => true, :allow_between_as_param => false,
          :quick_param_format => /(2x|3x|4x|5x)/,
          :quick_param_format_description => 'The size parameter \'%param%\' is incorrect, a number is expected',
          :param_tokens => [{:token => :size}]},
        :size => {
          :html_open => '<span class="bbcode__size" data-bbcodesize="%size%px">', :html_close => '</span>',
          :description => 'Change the size of the text',
          :example => '[size=32]This is 32px[/size]',
          :allow_quick_param => true, :allow_between_as_param => false,
          :quick_param_format => /(\d+)/,
          :quick_param_format_description => 'The size parameter \'%param%\' is incorrect, a number is expected',
          :param_tokens => [{:token => :size}]},
        :color => {
          :html_open => '<span class="bbcode__color" data-bbcodecolor="%color%">', :html_close => '</span>',
          :description => 'Use color',
          :example => '[color=red]This is red[/color]',
          :allow_quick_param => true, :allow_between_as_param => false,
          :quick_param_format => /([a-z]+)/i,
          :param_tokens => [{:token => :color}]},
        :colorhex => colorhex,
        :hex => colorhex,
        :faicon => {
          :html_open => '<span class="fa fa-%between% bbcode__faicon" style="display: none"></span><span class="faicon_FTL">%between%</span>', :html_close => '',
          :description => 'Use Font Awesome Icons',
          :example => '[faicon]users[/faicon]',
          :only_allow => [],
          :require_between => true},
        :quote => {
          :html_open => '<div class="bbcode__quote">', :html_close => '</div>',
          :description => 'Quote',
          :example => 'This is [quote]quote[/quote].'},
        :code => {
          :html_open => '<div class="bbcode__code">', :html_close => '</div>',
          :description => 'Code',
          :example => 'This is [code]Code[/code].'},
        :u => {
          :html_open => '<span class="bbcode__u">', :html_close => '</span>',
          :description => 'Under line',
          :example => 'This is [u]Under line[/u].'},
        :s => {
          :html_open => '<span class="bbcode__s">', :html_close => '</span>',
          :description => 'line through',
          :example => 'This is [s]line through[/s].'},
        :center => {
          :html_open => '<div style="text-align:center;">', :html_close => '</div>',
          :description => 'Center a text',
          :example => '[center]This is centered[/center].'},
        :right => {
          :html_open => '<div style="text-align:right;">', :html_close => '</div>',
          :description => 'Right Align a text',
          :example => '[right]This is centered[/right].'},
        :caps => {
          :html_open => '<span class="bbcode__caps">', :html_close => '</span>',
          :description => 'Capitalize',
          :example => 'This is [caps]capitalize[/caps].'},
        :lower => {
          :html_open => '<span class="bbcode__lower">', :html_close => '</span>',
          :description => 'Lowercase',
          :example => 'This is [lower]lowercase[/lower].'},
        :break => {
          :html_open => '<br>', :html_close => '</br>',
          :description => 'Break',
          :example => 'This is [br][/br] a break.'},
        :kan => {
          :html_open => '<span class="bbcode__kan">', :html_close => '</span>',
          :description => 'uppercase',
          :example => 'This is [kan]uppercase[/kan].'},
        :comic => {
          :html_open => '<span class="bbcode__comic">', :html_close => '</span>',
          :description => 'comic sans',
          :example => 'This is [comic]comic sans[/comic].'},
        :doc => {
          :html_open => '<span class="bbcode__doc">', :html_close => '</span>',
          :description => 'transparent text',
          :example => 'This is [doc]transparent text[/doc].'},
        :hs => {
          :html_open => '<span class="bbcode__hs">', :html_close => '</span>',
          :description => 'Courier New',
          :example => 'This is [hs]Courier New[/hs].'},
        :cute2 => {
          :html_open => '<span class="bbcode__cute2">', :html_close => '</span>',
          :description => 'CUTE',
          :example => 'This is [cute2]CUTE[/cute2].'},
        :oa => {
          :html_open => '<span class="bbcode__oa">', :html_close => '</span>',
          :description => 'Old Alternian',
          :example => 'This is [oa]Old Alternian[/oa].'},
        :sc => {
          :html_open => '<span class="bbcode__sc">', :html_close => '</span>',
          :description => 'Small Caps',
          :example => 'This is [sc]Small Caps[/sc].'},
        :impact => {
          :html_open => '<span class="bbcode__impact">', :html_close => '</span>',
          :description => 'Impact',
          :example => 'This is [impact]Impact[/impact].'},
        :luci => {
          :html_open => '<span class="bbcode__luci">', :html_close => '</span>',
          :description => 'Lucida Sans',
          :example => 'This is [luci]Lucida Sans[/luci].'},
        :pap => {
          :html_open => '<span class="bbcode__pap">', :html_close => '</span>',
          :description => 'Papyrus',
          :example => 'This is [pap]Papyrus[/pap].'},
        :copap => {
          :html_open => '<span class="bbcode__copap">', :html_close => '</span>',
          :description => 'Comic Papyrus',
          :example => 'This is [copap]Comic Papyrus[/copap].'},
        :na => {
          :html_open => '<span class="bbcode__na">', :html_close => '</span>',
          :description => 'New Alternian',
          :example => 'This is [na]New Alternian[/na].'},
        :cute => {
          :html_open => '<span class="bbcode__cute">', :html_close => '</span>',
          :description => 'Cute',
          :example => 'This is [cute]Cute[/cute].'},
        :url => {
          :html_open => '<a href="%url%">%between%', :html_close => '</a>',
          :description => 'Link to another page',
          :example => '[url]http://www.google.com/[/url].',
          :only_allow => [],
          :require_between => true,
          :allow_quick_param => true, :allow_between_as_param => true,
          :quick_param_format => /^((((http|https|ftp):\/\/)|\/).+)$/,
          :quick_param_format_description => 'The URL should start with http:// https://, ftp:// or /, instead of \'%param%\'',
          :param_tokens => [{ :token => :url }]},
      }, :enable, :i, :b, :color, :quote, :code, :size, :u, :s, :spin, :pulse, :flip, :large, :colorhex, :hex, :faicon, :center, :right, :caps, :lower, :kan, :comic, :doc, :hs, :cute2, :oa, :sc, :impact, :luci, :pap, :copap, :na, :cute, :img, :url, :width, :height, :break)
    rescue Exception => e
    end
    html
  end
end
