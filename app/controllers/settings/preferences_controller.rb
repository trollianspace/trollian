# frozen_string_literal: true

class Settings::PreferencesController < Settings::BaseController
  layout 'admin'

  before_action :authenticate_user!

  def show; end

  def update
    user_settings.update(user_settings_params.to_h)

    if current_user.update(user_params)
      I18n.locale = current_user.locale
      redirect_to after_update_redirect_path, notice: I18n.t('generic.changes_saved_msg')
    else
      render :show
    end
  end

  private

  def after_update_redirect_path
    settings_preferences_path
  end

  def user_settings
    UserSettingsDecorator.new(current_user)
  end

  def user_params
    params.require(:user).permit(
      :locale,
      chosen_languages: []
    )
  end

  def user_settings_params
    params.require(:user).permit(
      :setting_default_privacy,
      :setting_default_sensitive,
      :setting_default_language,
      :setting_unfollow_modal,
      :setting_boost_modal,
      :setting_delete_modal,
      :setting_auto_play_gif,
      :setting_display_media,
      :setting_expand_spoilers,
      :setting_reduce_motion,
      :setting_system_font_ui,
      :setting_noindex,
      :setting_theme,
      :setting_hide_network,
      :setting_aggregate_reblogs,
      :setting_show_application,
      :setting_advanced_layout,
      :setting_use_blurhash,
      :setting_use_pending_items,
      :setting_trends,
      :setting_crop_images,
      :setting_emoji_size_simple,
      :setting_emoji_size_detailed,
      :setting_emoji_size_name,
      :setting_column_size,
      :setting_bbcode_spin,
      :setting_bbcode_pulse,
      :setting_bbcode_flip,
      :setting_bbcode_large,
      :setting_bbcode_size,
      :setting_bbcode_color,
      :setting_bbcode_b,
      :setting_bbcode_i,
      :setting_bbcode_u,
      :setting_bbcode_strike,
      :setting_bbcode_colorhex,
      :setting_bbcode_quote,
      :setting_bbcode_code,
      :setting_bbcode_center,
      :setting_bbcode_right,
      :setting_bbcode_url,
      :setting_bbcode_caps,
      :setting_bbcode_lower,
      :setting_bbcode_kan,
      :setting_bbcode_comic,
      :setting_bbcode_doc,
      :setting_bbcode_hs,
      :setting_bbcode_cute2,
      :setting_bbcode_oa,
      :setting_bbcode_sc,
      :setting_bbcode_impact,
      :setting_bbcode_luci,
      :setting_bbcode_pap,
      :setting_bbcode_copap,
      :setting_bbcode_na,
      :setting_bbcode_cute,
      :setting_show_cw_box,
      notification_emails: %i(follow follow_request reblog favourite mention digest report pending_account trending_tag),
      interactions: %i(must_be_follower must_be_following must_be_following_dm)
    )
  end
end
