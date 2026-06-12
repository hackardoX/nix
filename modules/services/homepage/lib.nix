{ lib }:
let
  # Convert structured Homepage configuration to Docker labels
  # Usage:
  #   labels = config.flake.lib.mkHomepageLabels {
  #     category = "Media";
  #     name = "Immich";
  #     description = "Photo & Video Management";
  #     icon = "immich.png";
  #     href = "http://localhost:9000";
  #     widget = {
  #       type = "immich";
  #       url = "http://localhost:9000";
  #     };
  #   };
  mkHomepageLabels =
    {
      # Required fields
      category,
      name,
      # Optional fields
      description ? null,
      icon ? null,
      href ? null,
      widget ? null,
      # Additional optional fields
      ping ? null,
      siteMonitor ? null,
      showStats ? null,
      statusStyle ? null,
    }:
    let
      # Base labels (always present)
      baseLabels = {
        "homepage.group" = category;
        "homepage.name" = name;
      };

      # Optional string labels
      optionalLabels =
        (lib.optionalAttrs (description != null) { "homepage.description" = description; })
        // (lib.optionalAttrs (icon != null) { "homepage.icon" = icon; })
        // (lib.optionalAttrs (href != null) { "homepage.href" = href; })
        // (lib.optionalAttrs (ping != null) { "homepage.ping" = ping; })
        // (lib.optionalAttrs (siteMonitor != null) { "homepage.siteMonitor" = siteMonitor; })
        // (lib.optionalAttrs (showStats != null) { "homepage.showStats" = lib.boolToString showStats; })
        // (lib.optionalAttrs (statusStyle != null) { "homepage.statusStyle" = statusStyle; });

      widgetLabels =
        if widget == null then
          { }
        else
          lib.concatMapAttrs (
            key: value:
            let
              labelValue = if builtins.isBool value then lib.boolToString value else toString value;
            in
            {
              "homepage.widget.${key}" = labelValue;
            }
          ) widget;
    in
    baseLabels // optionalLabels // widgetLabels;
in
{
  flake.lib.mkHomepageLabels = mkHomepageLabels;
}
