# frozen_string_literal: true

class UserSettingsDecorator
  attr_reader :user, :settings

  def initialize(user)
    @user = user
  end

  def update(settings)
    @settings = settings
    process_update
  end

  private

  def process_update
    user.settings['notification_emails'] = merged_notification_emails if change?('notification_emails')
    user.settings['interactions']        = merged_interactions if change?('interactions')
    user.settings['default_privacy']     = default_privacy_preference if change?('setting_default_privacy')
    user.settings['default_sensitive']   = default_sensitive_preference if change?('setting_default_sensitive')
    user.settings['default_language']    = default_language_preference if change?('setting_default_language')
    user.settings['unfollow_modal']      = unfollow_modal_preference if change?('setting_unfollow_modal')
    user.settings['boost_modal']         = boost_modal_preference if change?('setting_boost_modal')
    user.settings['delete_modal']        = delete_modal_preference if change?('setting_delete_modal')
    user.settings['auto_play_gif']       = auto_play_gif_preference if change?('setting_auto_play_gif')
    user.settings['display_media']       = display_media_preference if change?('setting_display_media')
    user.settings['expand_spoilers']     = expand_spoilers_preference if change?('setting_expand_spoilers')
    user.settings['reduce_motion']       = reduce_motion_preference if change?('setting_reduce_motion')
    user.settings['system_font_ui']      = system_font_ui_preference if change?('setting_system_font_ui')
    user.settings['noindex']             = noindex_preference if change?('setting_noindex')
    user.settings['theme']               = theme_preference if change?('setting_theme')
    user.settings['hide_network']        = hide_network_preference if change?('setting_hide_network')
    user.settings['aggregate_reblogs']   = aggregate_reblogs_preference if change?('setting_aggregate_reblogs')
    user.settings['show_application']    = show_application_preference if change?('setting_show_application')
    user.settings['advanced_layout']     = advanced_layout_preference if change?('setting_advanced_layout')
    user.settings['use_blurhash']        = use_blurhash_preference if change?('setting_use_blurhash')
    user.settings['use_pending_items']   = use_pending_items_preference if change?('setting_use_pending_items')
    user.settings['trends']              = trends_preference if change?('setting_trends')
    user.settings['crop_images']         = crop_images_preference if change?('setting_crop_images')
    user.settings['emoji_size_simple']   = emoji_size_simple_preference if change?('setting_emoji_size_simple')
    user.settings['emoji_size_detailed'] = emoji_size_detailed_preference if change?('setting_emoji_size_detailed')
    user.settings['emoji_size_name']     = emoji_size_name_preference if change?('setting_emoji_size_name')
    user.settings['column_size']         = column_size_preference if change?('setting_column_size')
    user.settings['bbcode_spin']         = bbcode_spin_preference if change?('setting_bbcode_spin')
    user.settings['bbcode_pulse']        = bbcode_pulse_preference if change?('setting_bbcode_pulse')
    user.settings['bbcode_flip']         = bbcode_flip_preference if change?('setting_bbcode_flip')
    user.settings['bbcode_large']        = bbcode_large_preference if change?('setting_bbcode_large')
    user.settings['bbcode_size']         = bbcode_size_preference if change?('setting_bbcode_size')
    user.settings['bbcode_color']        = bbcode_color_preference if change?('setting_bbcode_color')
    user.settings['bbcode_b']            = bbcode_b_preference if change?('setting_bbcode_b')
    user.settings['bbcode_i']            = bbcode_i_preference if change?('setting_bbcode_i')
    user.settings['bbcode_u']            = bbcode_u_preference if change?('setting_bbcode_u')
    user.settings['bbcode_strike']       = bbcode_strike_preference if change?('setting_bbcode_strike')
    user.settings['bbcode_colorhex']     = bbcode_colorhex_preference if change?('setting_bbcode_colorhex')
    user.settings['bbcode_quote']        = bbcode_quote_preference if change?('setting_bbcode_quote')
    user.settings['bbcode_code']         = bbcode_code_preference if change?('setting_bbcode_code')
    user.settings['bbcode_center']       = bbcode_center_preference if change?('setting_bbcode_center')
    user.settings['bbcode_right']        = bbcode_right_preference if change?('setting_bbcode_right')
    user.settings['bbcode_url']          = bbcode_url_preference if change?('setting_bbcode_url')
    user.settings['bbcode_caps']         = bbcode_caps_preference if change?('setting_bbcode_caps')
    user.settings['bbcode_lower']        = bbcode_lower_preference if change?('setting_bbcode_lower')
    user.settings['bbcode_kan']          = bbcode_kan_preference if change?('setting_bbcode_kan')
    user.settings['bbcode_comic']        = bbcode_comic_preference if change?('setting_bbcode_comic')
    user.settings['bbcode_doc']          = bbcode_doc_preference if change?('setting_bbcode_doc')
    user.settings['bbcode_hs']           = bbcode_hs_preference if change?('setting_bbcode_hs')
    user.settings['bbcode_cute2']        = bbcode_cute2_preference if change?('setting_bbcode_cute2')
    user.settings['bbcode_oa']           = bbcode_oa_preference if change?('setting_bbcode_oa')
    user.settings['bbcode_sc']           = bbcode_sc_preference if change?('setting_bbcode_sc')
    user.settings['bbcode_impact']       = bbcode_impact_preference if change?('setting_bbcode_impact')
    user.settings['bbcode_luci']         = bbcode_luci_preference if change?('setting_bbcode_luci')
    user.settings['bbcode_pap']          = bbcode_pap_preference if change?('setting_bbcode_pap')
    user.settings['bbcode_copap']        = bbcode_copap_preference if change?('setting_bbcode_copap')
    user.settings['bbcode_na']           = bbcode_na_preference if change?('setting_bbcode_na')
    user.settings['bbcode_cute']         = bbcode_cute_preference if change?('setting_bbcode_cute')
    user.settings['show_cw_box']         = show_cw_box_preference if change?('setting_show_cw_box')
  end

  def merged_notification_emails
    user.settings['notification_emails'].merge coerced_settings('notification_emails').to_h
  end

  def merged_interactions
    user.settings['interactions'].merge coerced_settings('interactions').to_h
  end

  def default_privacy_preference
    settings['setting_default_privacy']
  end

  def default_sensitive_preference
    boolean_cast_setting 'setting_default_sensitive'
  end

  def unfollow_modal_preference
    boolean_cast_setting 'setting_unfollow_modal'
  end

  def boost_modal_preference
    boolean_cast_setting 'setting_boost_modal'
  end

  def delete_modal_preference
    boolean_cast_setting 'setting_delete_modal'
  end

  def system_font_ui_preference
    boolean_cast_setting 'setting_system_font_ui'
  end

  def auto_play_gif_preference
    boolean_cast_setting 'setting_auto_play_gif'
  end

  def display_media_preference
    settings['setting_display_media']
  end

  def expand_spoilers_preference
    boolean_cast_setting 'setting_expand_spoilers'
  end

  def reduce_motion_preference
    boolean_cast_setting 'setting_reduce_motion'
  end

  def noindex_preference
    boolean_cast_setting 'setting_noindex'
  end

  def hide_network_preference
    boolean_cast_setting 'setting_hide_network'
  end

  def show_application_preference
    boolean_cast_setting 'setting_show_application'
  end

  def theme_preference
    settings['setting_theme']
  end
  
  def emoji_size_simple_preference
    coerce_emoji_size 'setting_emoji_size_simple'
  end
  
  def emoji_size_detailed_preference
    coerce_emoji_size 'setting_emoji_size_detailed'
  end
  
  def emoji_size_name_preference
    coerce_emoji_size 'setting_emoji_size_name'
  end
  
  def coerce_emoji_size(key)
    value = settings[key].to_i
    
    if value < 1
      return nil
    end
    
    if value > 50
      return 50
    end
    
    ActiveModel::Type::Integer.new.cast(value)
  end
  
  def column_size_preference
    coerce_column_size 'setting_column_size'
  end

  def coerce_column_size(key)
    value = settings[key].to_i

    if value < 350
      return nil
    end

    if value > 1500
      return 1500
    end

    ActiveModel::Type::Integer.new.cast(value)
  end

  def bbcode_spin_preference
    boolean_cast_setting 'setting_bbcode_spin'
  end
  
  def bbcode_pulse_preference
    boolean_cast_setting 'setting_bbcode_pulse'
  end
  
  def bbcode_flip_preference
    boolean_cast_setting 'setting_bbcode_flip'
  end
  
  def bbcode_large_preference
    boolean_cast_setting 'setting_bbcode_large'
  end
  
  def bbcode_size_preference
    boolean_cast_setting 'setting_bbcode_size'
  end
  
  def bbcode_color_preference
    boolean_cast_setting 'setting_bbcode_color'
  end
  
  def bbcode_b_preference
    boolean_cast_setting 'setting_bbcode_b'
  end
  
  def bbcode_i_preference
    boolean_cast_setting 'setting_bbcode_i'
  end
  
  def bbcode_u_preference
    boolean_cast_setting 'setting_bbcode_u'
  end
  
  def bbcode_strike_preference
    boolean_cast_setting 'setting_bbcode_strike'
  end

  def bbcode_colorhex_preference
    boolean_cast_setting 'setting_bbcode_colorhex'
  end

  def bbcode_quote_preference
    boolean_cast_setting 'setting_bbcode_quote'
  end

  def bbcode_code_preference
    boolean_cast_setting 'setting_bbcode_code'
  end

  def bbcode_center_preference
    boolean_cast_setting 'setting_bbcode_center'
  end

  def bbcode_right_preference
    boolean_cast_setting 'setting_bbcode_right'
  end

  def bbcode_url_preference
    boolean_cast_setting 'setting_bbcode_url'
  end

  def bbcode_caps_preference
    boolean_cast_setting 'setting_bbcode_caps'
  end

  def bbcode_lower_preference
    boolean_cast_setting 'setting_bbcode_lower'
  end

  def bbcode_kan_preference
    boolean_cast_setting 'setting_bbcode_kan'
  end

  def bbcode_comic_preference
    boolean_cast_setting 'setting_bbcode_comic'
  end

  def bbcode_doc_preference
    boolean_cast_setting 'setting_bbcode_doc'
  end

  def bbcode_hs_preference
    boolean_cast_setting 'setting_bbcode_hs'
  end

  def bbcode_cute2_preference
    boolean_cast_setting 'setting_bbcode_cute2'
  end

  def bbcode_oa_preference
    boolean_cast_setting 'setting_bbcode_oa'
  end

  def bbcode_sc_preference
    boolean_cast_setting 'setting_bbcode_sc'
  end

  def bbcode_impact_preference
    boolean_cast_setting 'setting_bbcode_impact'
  end

  def bbcode_luci_preference
    boolean_cast_setting 'setting_bbcode_luci'
  end

  def bbcode_pap_preference
    boolean_cast_setting 'setting_bbcode_pap'
  end

  def bbcode_copap_preference
    boolean_cast_setting 'setting_bbcode_copap'
  end

  def bbcode_na_preference
    boolean_cast_setting 'setting_bbcode_na'
  end

  def bbcode_cute_preference
    boolean_cast_setting 'setting_bbcode_cute'
  end

  def show_cw_box_preference
    boolean_cast_setting 'setting_show_cw_box'
  end

  def default_language_preference
    settings['setting_default_language']
  end

  def aggregate_reblogs_preference
    boolean_cast_setting 'setting_aggregate_reblogs'
  end

  def advanced_layout_preference
    boolean_cast_setting 'setting_advanced_layout'
  end

  def use_blurhash_preference
    boolean_cast_setting 'setting_use_blurhash'
  end

  def use_pending_items_preference
    boolean_cast_setting 'setting_use_pending_items'
  end

  def trends_preference
    boolean_cast_setting 'setting_trends'
  end

  def crop_images_preference
    boolean_cast_setting 'setting_crop_images'
  end

  def boolean_cast_setting(key)
    ActiveModel::Type::Boolean.new.cast(settings[key])
  end

  def coerced_settings(key)
    coerce_values settings.fetch(key, {})
  end

  def coerce_values(params_hash)
    params_hash.transform_values { |x| ActiveModel::Type::Boolean.new.cast(x) }
  end

  def change?(key)
    !settings[key].nil?
  end
end
